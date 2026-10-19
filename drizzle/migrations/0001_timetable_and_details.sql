ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS national_id text,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS guardian_relation text,
  ADD COLUMN IF NOT EXISTS previous_school text,
  ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE public.teachers
  ADD COLUMN IF NOT EXISTS qualification text,
  ADD COLUMN IF NOT EXISTS hired_on date,
  ADD COLUMN IF NOT EXISTS notes text;

-- Status history for students (never lose why a status changed)
CREATE TABLE public.student_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  old_status public.student_status,
  new_status public.student_status NOT NULL,
  reason text,
  changed_by uuid,
  changed_at timestamptz NOT NULL DEFAULT now()
);
CREATE OR REPLACE FUNCTION public.track_student_status()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  NEW.updated_at := now();
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO public.student_status_history (student_id, old_status, new_status, reason, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, current_setting('app.status_reason', true), auth.uid());
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER student_status_track BEFORE UPDATE ON public.students
  FOR EACH ROW EXECUTE FUNCTION public.track_student_status();

-- Periods (configurable, not hard-coded)
CREATE TABLE public.periods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  period_order int NOT NULL,
  label text NOT NULL,
  starts_at time NOT NULL,
  ends_at time NOT NULL,
  is_break boolean NOT NULL DEFAULT false,
  UNIQUE (school_id, period_order),
  CHECK (ends_at > starts_at)
);
-- School week days (0=Sunday .. 6=Saturday)
CREATE TABLE public.school_days (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  weekday int NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  UNIQUE (school_id, weekday)
);
-- Teacher ↔ subject ↔ section per year
CREATE TABLE public.teaching_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  section_id uuid NOT NULL REFERENCES public.sections(id) ON DELETE RESTRICT,
  subject_id uuid NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
  teacher_id uuid NOT NULL REFERENCES public.teachers(id) ON DELETE RESTRICT,
  weekly_periods int CHECK (weekly_periods IS NULL OR weekly_periods > 0),
  UNIQUE (section_id, subject_id)
);
CREATE TYPE public.timetable_status AS ENUM ('draft', 'approved');
CREATE TABLE public.section_timetables (
  section_id uuid PRIMARY KEY REFERENCES public.sections(id) ON DELETE RESTRICT,
  status public.timetable_status NOT NULL DEFAULT 'draft',
  approved_by uuid,
  approved_at timestamptz
);
CREATE TABLE public.timetable_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  section_id uuid NOT NULL REFERENCES public.sections(id) ON DELETE RESTRICT,
  weekday int NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  period_id uuid NOT NULL REFERENCES public.periods(id) ON DELETE RESTRICT,
  subject_id uuid NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
  teacher_id uuid NOT NULL REFERENCES public.teachers(id) ON DELETE RESTRICT,
  room text,
  UNIQUE (section_id, weekday, period_id),
  UNIQUE (academic_year_id, teacher_id, weekday, period_id)
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['periods','school_days','teaching_assignments','section_timetables','timetable_entries'] LOOP
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    EXECUTE format('GRANT ALL ON public.%I TO service_role', t);
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY "staff read" ON public.%I FOR SELECT TO authenticated USING (public.is_staff(auth.uid()))', t);
    EXECUTE format('CREATE POLICY "managers insert" ON public.%I FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()))', t);
    EXECUTE format('CREATE POLICY "managers update" ON public.%I FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()))', t);
    EXECUTE format('CREATE POLICY "managers delete" ON public.%I FOR DELETE TO authenticated USING (public.can_manage(auth.uid()))', t);
    EXECUTE format('CREATE TRIGGER audit_%I AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.audit_trigger()', t, t);
  END LOOP;
END $$;

GRANT SELECT ON public.student_status_history TO authenticated;
GRANT ALL ON public.student_status_history TO service_role;
ALTER TABLE public.student_status_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "staff read" ON public.student_status_history FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

-- Status change with reason (server-side, validated)
CREATE OR REPLACE FUNCTION public.change_student_status(_student uuid, _status public.student_status, _reason text)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN RAISE EXCEPTION 'row-level security: not allowed'; END IF;
  IF coalesce(trim(_reason),'') = '' THEN RAISE EXCEPTION 'يجب ذكر سبب تغيير الحالة'; END IF;
  PERFORM set_config('app.status_reason', _reason, true);
  UPDATE public.students SET status = _status WHERE id = _student;
END $$;
GRANT EXECUTE ON FUNCTION public.change_student_status(uuid, public.student_status, text) TO authenticated;

-- Editing an approved timetable reverts it to draft
CREATE OR REPLACE FUNCTION public.timetable_back_to_draft()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.section_timetables SET status = 'draft', approved_by = NULL, approved_at = NULL
  WHERE section_id = COALESCE(NEW.section_id, OLD.section_id) AND status = 'approved';
  RETURN COALESCE(NEW, OLD);
END $$;
CREATE TRIGGER timetable_entries_draft AFTER INSERT OR UPDATE OR DELETE ON public.timetable_entries
  FOR EACH ROW EXECUTE FUNCTION public.timetable_back_to_draft();