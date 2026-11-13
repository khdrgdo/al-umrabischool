-- 0019: parent dashboard — per-child subjects with teacher names, and grade recording time.
-- Applied live 2026-11-12 after a rolled-back dry run (8 subjects with teachers, graded_at present).
DO $mig$
DECLARE v_def text;
BEGIN
  v_def := pg_get_functiondef('public.parent_get_dashboard_data()'::regprocedure);
  IF position('''created_at'', a.created_at, ''academic_year_id''' IN v_def) = 0 THEN RAISE EXCEPTION 'patch 1 not found'; END IF;
  v_def := replace(v_def, '''created_at'', a.created_at, ''academic_year_id''', '''created_at'', a.created_at, ''graded_at'', sg.updated_at, ''academic_year_id''');
  IF position('''section_name'', COALESCE(sec.name, ''غير محدد''),' IN v_def) = 0 THEN RAISE EXCEPTION 'patch 2 not found'; END IF;
  v_def := replace(v_def, '''section_name'', COALESCE(sec.name, ''غير محدد''),', '''section_name'', COALESCE(sec.name, ''غير محدد''), ''subjects'', (SELECT COALESCE(jsonb_agg(jsonb_build_object(''subject_name'', sb2.name, ''teacher_name'', t2.full_name, ''weekly_periods'', ta2.weekly_periods) ORDER BY sb2.name), ''[]''::jsonb) FROM public.teaching_assignments ta2 JOIN public.subjects sb2 ON sb2.id = ta2.subject_id LEFT JOIN public.teachers t2 ON t2.id = ta2.teacher_id WHERE ta2.section_id = sec.id AND ta2.academic_year_id = e.academic_year_id),');
  EXECUTE v_def;
END
$mig$;
