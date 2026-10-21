-- Migration 0008: Annual Rollover and Student Academic Promotion Workflow
-- Allows reviewing academic decisions (promote, repeat, graduate, transfer_out),
-- previewing the new academic year distribution, and executing rollover safely.

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
CREATE OR REPLACE FUNCTION public.execute_year_rollover(
  _from_year uuid,
  _to_year uuid
)
RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  rec RECORD;
  promoted_count int := 0;
  repeated_count int := 0;
  graduated_count int := 0;
  transferred_count int := 0;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'لا تملك صلاحية اعتماد وتنفيذ الترحيل السنوي';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.student_promotions
    WHERE from_academic_year_id = _from_year
      AND to_academic_year_id = _to_year
      AND decision = 'pending'
      AND NOT is_executed
  ) THEN
    RAISE EXCEPTION 'توجد قرارات طلاب معلقة لم تُحسم بعد. يُرجى حسم كافة القرارات أولًا';
  END IF;

  FOR rec IN
    SELECT sp.*, e.id AS from_enrollment_id
    FROM public.student_promotions sp
    LEFT JOIN public.enrollments e ON e.student_id = sp.student_id AND e.academic_year_id = _from_year
    WHERE sp.from_academic_year_id = _from_year
      AND sp.to_academic_year_id = _to_year
      AND NOT sp.is_executed
  LOOP
    IF rec.decision = 'promote' THEN
      IF rec.target_section_id IS NULL THEN
        RAISE EXCEPTION 'يجب تحديد الشعبة المستهدفة لجميع الطلاب المترقين';
      END IF;

      INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
      VALUES (rec.student_id, _to_year, rec.target_section_id, 'continuing', 'active')
      ON CONFLICT (student_id, academic_year_id) DO NOTHING;

      IF rec.from_enrollment_id IS NOT NULL THEN
        UPDATE public.enrollments SET status = 'promoted' WHERE id = rec.from_enrollment_id;
      END IF;
      promoted_count := promoted_count + 1;

    ELSIF rec.decision = 'repeat' THEN
      IF rec.target_section_id IS NULL THEN
        RAISE EXCEPTION 'يجب تحديد شعبة الإعادة لجميع الطلاب المعيدين';
      END IF;

      INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
      VALUES (rec.student_id, _to_year, rec.target_section_id, 'continuing', 'active')
      ON CONFLICT (student_id, academic_year_id) DO NOTHING;

      IF rec.from_enrollment_id IS NOT NULL THEN
        UPDATE public.enrollments SET status = 'repeated' WHERE id = rec.from_enrollment_id;
      END IF;
      repeated_count := repeated_count + 1;

    ELSIF rec.decision = 'graduate' THEN
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
    'transferred', transferred_count
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.execute_year_rollover(uuid, uuid) TO authenticated;
