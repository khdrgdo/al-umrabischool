-- 0018: parent app v2 — school WhatsApp, targeted announcements, optional fees,
-- announcement read receipts, parent problem reports, academic year on grades.
-- Applied live 2026-11-12 after a rolled-back dry run (targeting, optional fee, read flags, report all verified).

ALTER TABLE public.schools ADD COLUMN IF NOT EXISTS whatsapp_number text;

ALTER TABLE public.fee_structures ADD COLUMN IF NOT EXISTS is_optional boolean NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.fee_structure_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fee_structure_id uuid NOT NULL REFERENCES public.fee_structures(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  assigned_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (fee_structure_id, student_id)
);
CREATE INDEX IF NOT EXISTS fee_structure_assignments_student_idx ON public.fee_structure_assignments (student_id);

CREATE TABLE IF NOT EXISTS public.announcement_targets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id uuid NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  student_id uuid REFERENCES public.students(id) ON DELETE CASCADE,
  section_id uuid REFERENCES public.sections(id) ON DELETE CASCADE,
  grade_id uuid REFERENCES public.grades(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT announcement_targets_one_target CHECK (num_nonnulls(student_id, section_id, grade_id) = 1)
);
CREATE INDEX IF NOT EXISTS announcement_targets_ann_idx ON public.announcement_targets (announcement_id);

CREATE TABLE IF NOT EXISTS public.announcement_reads (
  announcement_id uuid NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  guardian_id uuid NOT NULL REFERENCES public.guardians(id) ON DELETE CASCADE,
  read_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (announcement_id, guardian_id)
);

CREATE TABLE IF NOT EXISTS public.parent_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES public.guardians(id) ON DELETE CASCADE,
  student_id uuid REFERENCES public.students(id) ON DELETE SET NULL,
  category text NOT NULL CHECK (category IN ('bug','question','suggestion','other')),
  body text NOT NULL CHECK (char_length(body) BETWEEN 5 AND 2000),
  app_version text,
  device text,
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new','seen','resolved')),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS parent_reports_status_idx ON public.parent_reports (status, created_at DESC);

GRANT SELECT, INSERT, DELETE ON public.fee_structure_assignments TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.announcement_targets TO authenticated;
GRANT SELECT ON public.announcement_reads TO authenticated;
GRANT SELECT, UPDATE ON public.parent_reports TO authenticated;
GRANT ALL ON public.fee_structure_assignments, public.announcement_targets, public.announcement_reads, public.parent_reports TO service_role;

ALTER TABLE public.fee_structure_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff read fee_structure_assignments" ON public.fee_structure_assignments;
CREATE POLICY "staff read fee_structure_assignments" ON public.fee_structure_assignments FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
DROP POLICY IF EXISTS "managers insert fee_structure_assignments" ON public.fee_structure_assignments;
CREATE POLICY "managers insert fee_structure_assignments" ON public.fee_structure_assignments FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
DROP POLICY IF EXISTS "managers delete fee_structure_assignments" ON public.fee_structure_assignments;
CREATE POLICY "managers delete fee_structure_assignments" ON public.fee_structure_assignments FOR DELETE TO authenticated USING (public.can_manage(auth.uid()));

DROP POLICY IF EXISTS "staff read announcement_targets" ON public.announcement_targets;
CREATE POLICY "staff read announcement_targets" ON public.announcement_targets FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
DROP POLICY IF EXISTS "managers insert announcement_targets" ON public.announcement_targets;
CREATE POLICY "managers insert announcement_targets" ON public.announcement_targets FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
DROP POLICY IF EXISTS "managers delete announcement_targets" ON public.announcement_targets;
CREATE POLICY "managers delete announcement_targets" ON public.announcement_targets FOR DELETE TO authenticated USING (public.can_manage(auth.uid()));

DROP POLICY IF EXISTS "staff read announcement_reads" ON public.announcement_reads;
CREATE POLICY "staff read announcement_reads" ON public.announcement_reads FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

DROP POLICY IF EXISTS "staff read parent_reports" ON public.parent_reports;
CREATE POLICY "staff read parent_reports" ON public.parent_reports FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
DROP POLICY IF EXISTS "managers update parent_reports" ON public.parent_reports;
CREATE POLICY "managers update parent_reports" ON public.parent_reports FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE OR REPLACE FUNCTION public.parent_mark_announcements_read(p_ids uuid[])
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $fn$
DECLARE v_g uuid; v_n integer;
BEGIN
  SELECT id INTO v_g FROM public.guardians WHERE user_id = auth.uid() AND status = 'active' LIMIT 1;
  IF v_g IS NULL THEN RETURN 0; END IF;
  INSERT INTO public.announcement_reads (announcement_id, guardian_id)
  SELECT a.id, v_g FROM public.announcements a WHERE a.id = ANY (p_ids) AND a.is_published
  ON CONFLICT DO NOTHING;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.parent_submit_report(p_category text, p_body text, p_student_id uuid, p_app_version text, p_device text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $fn$
DECLARE v_g uuid; v_recent integer; v_id uuid;
BEGIN
  SELECT id INTO v_g FROM public.guardians WHERE user_id = auth.uid() AND status = 'active' LIMIT 1;
  IF v_g IS NULL THEN RETURN jsonb_build_object('error', 'NOT_ALLOWED'); END IF;
  IF p_category NOT IN ('bug','question','suggestion','other') OR p_body IS NULL OR char_length(btrim(p_body)) < 5 OR char_length(p_body) > 2000 THEN
    RETURN jsonb_build_object('error', 'INVALID');
  END IF;
  IF p_student_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.guardian_students WHERE guardian_id = v_g AND student_id = p_student_id) THEN
    p_student_id := NULL;
  END IF;
  SELECT count(*) INTO v_recent FROM public.parent_reports WHERE guardian_id = v_g AND created_at > now() - interval '24 hours';
  IF v_recent >= 5 THEN RETURN jsonb_build_object('error', 'RATE_LIMITED'); END IF;
  INSERT INTO public.parent_reports (guardian_id, student_id, category, body, app_version, device)
  VALUES (v_g, p_student_id, p_category, btrim(p_body), left(p_app_version, 40), left(p_device, 120))
  RETURNING id INTO v_id;
  RETURN jsonb_build_object('ok', true, 'id', v_id);
END;
$fn$;

REVOKE ALL ON FUNCTION public.parent_mark_announcements_read(uuid[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.parent_submit_report(text, text, uuid, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.parent_mark_announcements_read(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.parent_submit_report(text, text, uuid, text, text) TO authenticated;

DO $mig$
DECLARE
  v_def text;
  v_old text;
  v_new text;
  v_pairs text[][] := ARRAY[
    ARRAY['''created_at'', a.created_at', '''created_at'', a.created_at, ''academic_year_id'', a.academic_year_id, ''academic_year'', ay.name'],
    ARRAY['JOIN public.subjects sub ON sub.id = a.subject_id', 'JOIN public.subjects sub ON sub.id = a.subject_id LEFT JOIN public.academic_years ay ON ay.id = a.academic_year_id'],
    ARRAY['SELECT ft.name, fs.description, fs.amount, fs.due_date,', 'SELECT ft.name, fs.description, fs.amount, fs.due_date, fs.is_optional,'],
    ARRAY['''due_date'', x.due_date', '''due_date'', x.due_date, ''is_optional'', x.is_optional'],
    ARRAY['AND fs.track_id IS NULL', 'AND fs.track_id IS NULL AND (NOT fs.is_optional OR EXISTS (SELECT 1 FROM public.fee_structure_assignments fa WHERE fa.fee_structure_id = fs.id AND fa.student_id = s.id))'],
    ARRAY['jsonb_build_object(''id'', id, ''title'', title, ''body'', body, ''priority'', priority, ''published_at'', published_at)',
          'jsonb_build_object(''id'', an.id, ''title'', an.title, ''body'', an.body, ''priority'', an.priority, ''published_at'', an.published_at, ''targeted'', EXISTS (SELECT 1 FROM public.announcement_targets t0 WHERE t0.announcement_id = an.id), ''read_at'', (SELECT r.read_at FROM public.announcement_reads r WHERE r.announcement_id = an.id AND r.guardian_id = v_guardian.id))'],
    ARRAY['ORDER BY published_at DESC', 'ORDER BY an.published_at DESC'],
    ARRAY['FROM public.announcements', 'FROM public.announcements an'],
    ARRAY['AND (expires_at IS NULL OR expires_at >= CURRENT_DATE);',
          'AND (an.expires_at IS NULL OR an.expires_at >= CURRENT_DATE) AND (NOT EXISTS (SELECT 1 FROM public.announcement_targets t WHERE t.announcement_id = an.id) OR EXISTS (SELECT 1 FROM public.announcement_targets t JOIN public.guardian_students gs2 ON gs2.guardian_id = v_guardian.id LEFT JOIN public.enrollments e2 ON e2.student_id = gs2.student_id AND e2.status = ''active'' LEFT JOIN public.sections sc2 ON sc2.id = e2.section_id WHERE t.announcement_id = an.id AND (t.student_id = gs2.student_id OR t.section_id = sc2.id OR t.grade_id = sc2.grade_id)));'],
    ARRAY['''events'', COALESCE(v_events, ''[]''::jsonb)', '''events'', COALESCE(v_events, ''[]''::jsonb), ''school'', (SELECT jsonb_build_object(''name'', sch.name, ''whatsapp_number'', sch.whatsapp_number) FROM public.schools sch WHERE sch.id = v_guardian.school_id)']
  ];
  i int;
BEGIN
  v_def := pg_get_functiondef('public.parent_get_dashboard_data()'::regprocedure);
  FOR i IN 1 .. array_length(v_pairs, 1) LOOP
    v_old := v_pairs[i][1]; v_new := v_pairs[i][2];
    IF position(v_old IN v_def) = 0 THEN
      RAISE EXCEPTION 'patch % not found: %', i, v_old;
    END IF;
    v_def := replace(v_def, v_old, v_new);
  END LOOP;
  EXECUTE v_def;
END
$mig$;
