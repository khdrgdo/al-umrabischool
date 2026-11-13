-- 0017: parent_get_dashboard_data() now also returns 'created_at' (assessment creation time) per published grade,
-- so the app can draw a grade-progress trend in chronological order. Additive, read-only; derived from the live definition.
DO $mig$
DECLARE d text;
BEGIN
  d := pg_get_functiondef('public.parent_get_dashboard_data()'::regprocedure);
  IF position('''created_at'', a.created_at' in d) > 0 THEN RETURN; END IF;
  d := replace(d, '''is_absent'', sg.is_absent', '''is_absent'', sg.is_absent, ''created_at'', a.created_at');
  IF position('''created_at'', a.created_at' in d) = 0 THEN RAISE EXCEPTION 'pattern not found'; END IF;
  EXECUTE d;
END $mig$;
