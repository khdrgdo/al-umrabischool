-- Migration 0008: Annual Rollover and Student Academic Promotion Workflow
-- Allows reviewing academic decisions (promote, repeat, graduate, transfer_out),
-- previewing the new academic year distribution, and executing rollover safely.
-- Updated per FIX-1 (F-004, F-005, F-006, F-007)

CREATE TABLE IF NOT EXISTS public.student_promotions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  from_academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  to_academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  decision text NOT NULL DEFAULT 'pending' CHECK (decision IN ('promote', 'repeat', 'graduate', 'transfer_out', 'pending')),
  target_section_id uuid REFERENCES public.sections(id) ON DELETE RESTRICT,
  notes text,
  is_executed boolean NOT NULL DEFAULT false,
  executed_at timestamptz,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (student_id, from_academic_year_id)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS student_promotions_years_idx ON public.student_promotions (from_academic_year_id, to_academic_year_id, is_executed);
CREATE INDEX IF NOT EXISTS student_promotions_student_idx ON public.student_promotions (student_id);

-- RLS & Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.student_promotions TO authenticated;
GRANT ALL ON public.student_promotions TO service_role;

ALTER TABLE public.student_promotions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "staff read student_promotions" ON public.student_promotions
  FOR SELECT TO authenticated
  USING (public.is_staff(auth.uid()));

CREATE POLICY "managers manage student_promotions" ON public.student_promotions
  FOR ALL TO authenticated
  USING (public.can_manage(auth.uid()))
  WITH CHECK (public.can_manage(auth.uid()));

-- Stored Procedure to execute annual promotion atomically
-- F-004, F-005, F-006, F-007: Strict validation, no silent DO NOTHING, explicit decisions
CREATE OR REPLACE FUNCTION public.execute_year_rollover(
  _from_year uuid,
  _to_year uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  rec RECORD;
  v_student_rec RECORD;
  v_from_grade_order int;
  v_from_grade_name text;
  v_target_grade_order int;
  v_target_grade_name text;
  v_max_grade_order int;
  promoted_count int := 0;
  repeated_count int := 0;
  graduated_count int := 0;
  transferred_count int := 0;
  already_enrolled_count int := 0;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'لا تملك صلاحية اعتماد وتنفيذ الترحيل السنوي';
  END IF;

  -- Determine highest grade level in system (e.g. Grade 3 for secondary)
  SELECT COALESCE(MAX(level_order), 3) INTO v_max_grade_order FROM public.grades;

  -- F-004: Validate that years exist and are distinct
  IF _from_year = _to_year THEN
    RAISE EXCEPTION 'لا يمكن إجراء الترحيل السنوي بين نفس السنة الدراسية.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.academic_years WHERE id = _from_year) THEN
    RAISE EXCEPTION 'السنة الدراسية المنقول منها غير موجودة في النظام.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.academic_years WHERE id = _to_year) THEN
    RAISE EXCEPTION 'السنة الدراسية المنقول إليها غير موجودة في النظام.';
  END IF;

  -- F-006: Ensure no pending unfinalized decisions
  IF EXISTS (
    SELECT 1 FROM public.student_promotions
    WHERE from_academic_year_id = _from_year
      AND to_academic_year_id = _to_year
      AND decision = 'pending'
      AND NOT is_executed
  ) THEN
    RAISE EXCEPTION 'توجد قرارات طلاب معلقة (pending) لم تُحسم بعد. يُرجى حسم كافة القرارات أولًا.';
  END IF;

  FOR rec IN
    SELECT sp.*, e.id AS from_enrollment_id
    FROM public.student_promotions sp
    LEFT JOIN public.enrollments e ON e.student_id = sp.student_id AND e.academic_year_id = _from_year
    WHERE sp.from_academic_year_id = _from_year
      AND sp.to_academic_year_id = _to_year
      AND NOT sp.is_executed
  LOOP
    -- Fetch student current status
    SELECT * INTO v_student_rec FROM public.students WHERE id = rec.student_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'سجل الطالب غير موجود (معرف: %)', rec.student_id;
    END IF;

    -- Fetch from_grade level_order if student was enrolled
    v_from_grade_order := NULL;
    v_from_grade_name := NULL;
    IF rec.from_enrollment_id IS NOT NULL THEN
      SELECT g.level_order, g.name INTO v_from_grade_order, v_from_grade_name
      FROM public.enrollments e
      JOIN public.sections s ON s.id = e.section_id
      JOIN public.grades g ON g.id = s.grade_id
      WHERE e.id = rec.from_enrollment_id;
    END IF;

    -- Fetch target_grade level_order if target_section is specified
    v_target_grade_order := NULL;
    v_target_grade_name := NULL;
    IF rec.target_section_id IS NOT NULL THEN
      SELECT g.level_order, g.name INTO v_target_grade_order, v_target_grade_name
      FROM public.sections s
      JOIN public.grades g ON g.id = s.grade_id
      WHERE s.id = rec.target_section_id;
    END IF;

    -- F-007: Block active enrollment for graduated or transferred-out students
    IF v_student_rec.status IN ('graduated', 'transferred_out') AND rec.decision IN ('promote', 'repeat') THEN
      RAISE EXCEPTION 'لا يمكن قيد طالب متخرج أو منقول خارجياً في السنة الجديدة (الطالب: %)', v_student_rec.full_name;
    END IF;

    IF rec.decision = 'promote' THEN
      IF rec.target_section_id IS NULL THEN
        RAISE EXCEPTION 'يجب تحديد الشعبة المستهدفة لجميع الطلاب المترقين (الطالب: %)', v_student_rec.full_name;
      END IF;

      -- Enforce strictly promote to next level (level_order + 1)
      IF v_from_grade_order IS NOT NULL AND v_target_grade_order IS NOT NULL THEN
        IF v_target_grade_order <> v_from_grade_order + 1 THEN
          RAISE EXCEPTION 'ترقية غير صالحة للطالب (%): لا يمكن الترقية من الصف (%) إلى الصف (%). الترقية يجب أن تكون للصف التالي مباشرة.',
            v_student_rec.full_name, COALESCE(v_from_grade_name, 'الحالي'), COALESCE(v_target_grade_name, 'المستهدف');
        END IF;
      END IF;

      -- F-004: Verify target section belongs to target academic year
      IF NOT EXISTS (
        SELECT 1 FROM public.sections
        WHERE id = rec.target_section_id AND academic_year_id = _to_year
      ) THEN
        RAISE EXCEPTION 'الشعبة المستهدفة للطالب (%) غير مرتبطة بالسنة الدراسية الجديدة', v_student_rec.full_name;
      END IF;

      -- F-005: Check existing enrollment before insert rather than silent DO NOTHING
      IF EXISTS (
        SELECT 1 FROM public.enrollments 
        WHERE student_id = rec.student_id AND academic_year_id = _to_year
      ) THEN
        already_enrolled_count := already_enrolled_count + 1;
      ELSE
        INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
        VALUES (rec.student_id, _to_year, rec.target_section_id, 'continuing', 'active');
        promoted_count := promoted_count + 1;
      END IF;

      IF rec.from_enrollment_id IS NOT NULL THEN
        UPDATE public.enrollments SET status = 'promoted' WHERE id = rec.from_enrollment_id;
      END IF;

    ELSIF rec.decision = 'repeat' THEN
      IF rec.target_section_id IS NULL THEN
        RAISE EXCEPTION 'يجب تحديد شعبة الإعادة لجميع الطلاب المعيدين (الطالب: %)', v_student_rec.full_name;
      END IF;

      -- Enforce repeating in the same grade level (level_order == from_level_order)
      IF v_from_grade_order IS NOT NULL AND v_target_grade_order IS NOT NULL THEN
        IF v_target_grade_order <> v_from_grade_order THEN
          RAISE EXCEPTION 'إعادة قيد غير صالحة للطالب (%): يجب أن تكون الإعادة في نفس الصف الدراسي (%).',
            v_student_rec.full_name, COALESCE(v_from_grade_name, 'الحالي');
        END IF;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM public.sections
        WHERE id = rec.target_section_id AND academic_year_id = _to_year
      ) THEN
        RAISE EXCEPTION 'شعبة الإعادة للطالب (%) غير مرتبطة بالسنة الدراسية الجديدة', v_student_rec.full_name;
      END IF;

      -- F-005: Explicit enrollment check
      IF EXISTS (
        SELECT 1 FROM public.enrollments 
        WHERE student_id = rec.student_id AND academic_year_id = _to_year
      ) THEN
        already_enrolled_count := already_enrolled_count + 1;
      ELSE
        INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
        VALUES (rec.student_id, _to_year, rec.target_section_id, 'continuing', 'active');
        repeated_count := repeated_count + 1;
      END IF;

      IF rec.from_enrollment_id IS NOT NULL THEN
        UPDATE public.enrollments SET status = 'repeated' WHERE id = rec.from_enrollment_id;
      END IF;

    ELSIF rec.decision = 'graduate' THEN
      -- Enforce graduation only from terminal grade (highest grade level, e.g. Grade 3)
      IF v_from_grade_order IS NOT NULL AND v_from_grade_order < v_max_grade_order THEN
        RAISE EXCEPTION 'لا يمكن تخريج الطالب (%) لأنه مقيد بالصف (%) وليس بالصف النهائي المؤهل للتخرج (الصف %).',
          v_student_rec.full_name, COALESCE(v_from_grade_name, 'الحالي'), v_max_grade_order;
      END IF;

      IF rec.from_enrollment_id IS NOT NULL THEN
        UPDATE public.enrollments SET status = 'graduated' WHERE id = rec.from_enrollment_id;
      END IF;
      UPDATE public.students SET status = 'graduated' WHERE id = rec.student_id;
      graduated_count := graduated_count + 1;

    ELSIF rec.decision = 'transfer_out' THEN
      IF rec.from_enrollment_id IS NOT NULL THEN
        UPDATE public.enrollments SET status = 'transferred_out' WHERE id = rec.from_enrollment_id;
      END IF;
      UPDATE public.students SET status = 'transferred_out' WHERE id = rec.student_id;
      transferred_count := transferred_count + 1;
    END IF;

    UPDATE public.student_promotions
    SET is_executed = true, executed_at = now()
    WHERE id = rec.id;
  END LOOP;

  RETURN jsonb_build_object(
    'promoted', promoted_count,
    'repeated', repeated_count,
    'graduated', graduated_count,
    'transferred', transferred_count,
    'already_enrolled_skipped', already_enrolled_count
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.execute_year_rollover(uuid, uuid) TO authenticated;
