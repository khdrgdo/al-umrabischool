-- Daily attendance per section. Default is present; staff mark absentees only.
CREATE TABLE public.attendance_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  section_id uuid NOT NULL REFERENCES public.sections(id) ON DELETE RESTRICT,
  attendance_date date NOT NULL,
  created_by uuid DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (section_id, attendance_date)
);
CREATE TABLE public.attendance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.attendance_sessions(id) ON DELETE RESTRICT,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'present' CHECK (status IN ('present','absent')),
  reason text,
  updated_by uuid DEFAULT auth.uid(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (session_id, student_id)
);
CREATE INDEX attendance_sessions_date_idx ON public.attendance_sessions (attendance_date);

GRANT SELECT, INSERT, UPDATE ON public.attendance_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.attendance_records TO authenticated;
GRANT ALL ON public.attendance_sessions TO service_role;
GRANT ALL ON public.attendance_records TO service_role;
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "staff read" ON public.attendance_sessions FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "managers insert" ON public.attendance_sessions FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update" ON public.attendance_sessions FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "staff read" ON public.attendance_records FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "managers insert" ON public.attendance_records FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update" ON public.attendance_records FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

-- Integrity enforced in the database, whatever path writes the rows.
CREATE OR REPLACE FUNCTION public.attendance_session_guard()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.sections WHERE id = NEW.section_id AND academic_year_id = NEW.academic_year_id) THEN
    RAISE EXCEPTION 'الشعبة لا تتبع السنة الدراسية المحددة';
  END IF;
  IF TG_OP = 'UPDATE' THEN
    NEW.created_by := OLD.created_by; NEW.created_at := OLD.created_at;
    NEW.updated_by := auth.uid(); NEW.updated_at := now();
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER attendance_session_guard BEFORE INSERT OR UPDATE ON public.attendance_sessions
  FOR EACH ROW EXECUTE FUNCTION public.attendance_session_guard();

CREATE OR REPLACE FUNCTION public.attendance_record_guard()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (NEW.session_id <> OLD.session_id OR NEW.student_id <> OLD.student_id) THEN
    RAISE EXCEPTION 'لا يمكن نقل سجل الحضور إلى جلسة أو طالب آخر';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.attendance_sessions s
    JOIN public.enrollments e ON e.section_id = s.section_id AND e.academic_year_id = s.academic_year_id
    WHERE s.id = NEW.session_id AND e.student_id = NEW.student_id AND e.status = 'active'
  ) THEN
    RAISE EXCEPTION 'الطالب غير مسجل نشطًا في هذه الشعبة لهذا العام';
  END IF;
  IF NEW.status = 'present' THEN NEW.reason := NULL; END IF;
  NEW.updated_by := auth.uid(); NEW.updated_at := now();
  RETURN NEW;
END $$;
CREATE TRIGGER attendance_record_guard BEFORE INSERT OR UPDATE ON public.attendance_records
  FOR EACH ROW EXECUTE FUNCTION public.attendance_record_guard();

CREATE TRIGGER audit_attendance_sessions AFTER INSERT OR UPDATE OR DELETE ON public.attendance_sessions
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();
CREATE TRIGGER audit_attendance_records AFTER INSERT OR UPDATE OR DELETE ON public.attendance_records
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

-- Atomic save: creates or reopens the (section, date) session; roster comes from the database, not the client.
CREATE OR REPLACE FUNCTION public.save_daily_attendance(_section uuid, _date date, _absences jsonb)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE sid uuid; yid uuid; bad int;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN RAISE EXCEPTION 'row-level security: not allowed'; END IF;
  IF _date IS NULL THEN RAISE EXCEPTION 'حدد التاريخ'; END IF;
  SELECT academic_year_id INTO yid FROM public.sections WHERE id = _section;
  IF yid IS NULL THEN RAISE EXCEPTION 'الشعبة غير موجودة'; END IF;

  SELECT count(*) INTO bad FROM jsonb_array_elements(coalesce(_absences,'[]'::jsonb)) a
  WHERE NOT EXISTS (SELECT 1 FROM public.enrollments e
    WHERE e.student_id::text = a->>'student_id' AND e.section_id = _section AND e.academic_year_id = yid AND e.status = 'active');
  IF bad > 0 THEN RAISE EXCEPTION 'قائمة الغياب تحتوي طلابًا غير مسجلين نشطين في هذه الشعبة'; END IF;

  INSERT INTO public.attendance_sessions (academic_year_id, section_id, attendance_date)
  VALUES (yid, _section, _date)
  ON CONFLICT (section_id, attendance_date) DO UPDATE SET updated_at = now()
  RETURNING id INTO sid;

  INSERT INTO public.attendance_records (session_id, student_id, status, reason)
  SELECT sid, e.student_id,
    CASE WHEN a.v IS NULL THEN 'present' ELSE 'absent' END,
    NULLIF(trim(a.v->>'reason'),'')
  FROM public.enrollments e
  LEFT JOIN LATERAL (SELECT x AS v FROM jsonb_array_elements(coalesce(_absences,'[]'::jsonb)) x
                     WHERE x->>'student_id' = e.student_id::text LIMIT 1) a ON true
  WHERE e.section_id = _section AND e.academic_year_id = yid AND e.status = 'active'
  ON CONFLICT (session_id, student_id) DO UPDATE SET status = EXCLUDED.status, reason = EXCLUDED.reason
  WHERE attendance_records.status IS DISTINCT FROM EXCLUDED.status OR attendance_records.reason IS DISTINCT FROM EXCLUDED.reason;
  RETURN sid;
END $$;
REVOKE ALL ON FUNCTION public.save_daily_attendance(uuid, date, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_daily_attendance(uuid, date, jsonb) TO authenticated;