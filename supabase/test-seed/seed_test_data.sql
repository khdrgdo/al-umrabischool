-- DISABLED: legacy test fixture no longer matches the parent-auth schema.
-- It contains obsolete temp_password_code values and fixed account codes.
-- Use the maintained, guarded seed procedure only after reviewing the live schema.
DO $$
BEGIN
  RAISE EXCEPTION 'LEGACY_SEED_DISABLED: this fixture is obsolete and must not be executed.';
END
$$;
