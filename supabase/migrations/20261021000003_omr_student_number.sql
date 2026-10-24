-- New students get OMR-000001, OMR-000002, ... Existing numbers stay exactly as they are.
CREATE SEQUENCE IF NOT EXISTS public.omr_student_number_seq AS bigint MINVALUE 1 START 1;
REVOKE ALL ON SEQUENCE public.omr_student_number_seq FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SEQUENCE public.omr_student_number_seq TO service_role;
COMMENT ON SEQUENCE public.student_number_seq IS 'DEPRECATED: replaced by omr_student_number_seq';

CREATE OR REPLACE FUNCTION public.student_number_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Client value is always ignored. nextval is concurrency-safe; skip any value already taken.
    LOOP
      NEW.student_number := 'OMR-' || lpad(nextval('public.omr_student_number_seq')::text, 6, '0');
      EXIT WHEN NOT EXISTS (SELECT 1 FROM public.students WHERE student_number = NEW.student_number);
    END LOOP;
  ELSIF NEW.student_number IS DISTINCT FROM OLD.student_number THEN
    RAISE EXCEPTION 'الرقم المدرسي يولده النظام ولا يمكن تعديله';
  END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.student_number_guard() FROM PUBLIC, anon, authenticated;