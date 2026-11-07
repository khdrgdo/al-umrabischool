DO $$
BEGIN
  IF to_regprocedure('public.parent_app_login(text,text)') IS NOT NULL
     OR to_regprocedure('public.parent_get_portal_data(uuid,text,text)') IS NOT NULL THEN
    RAISE EXCEPTION 'legacy parent PIN RPC still present';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
             WHERE n.nspname = 'public' AND p.proname LIKE 'parent%'
               AND has_function_privilege('anon', p.oid, 'EXECUTE')) THEN
    RAISE EXCEPTION 'anon can execute a parent function';
  END IF;
  IF to_regclass('public.guardian_activation_codes') IS NULL THEN
    RAISE EXCEPTION 'migration 0013 not applied';
  END IF;
END $$;