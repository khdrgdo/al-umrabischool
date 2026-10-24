-- Migration 0007: School Calendar, Academic Events, and School Announcements
-- Manages: Term start/end, Exams, Official Holidays, Meetings, Result Declarations, and Announcements

CREATE TABLE IF NOT EXISTS public.school_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  academic_year_id uuid REFERENCES public.academic_years(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  event_type text NOT NULL CHECK (event_type IN ('term_date', 'exam', 'holiday', 'meeting', 'event', 'result')),
  starts_on date NOT NULL,
  ends_on date,
  target_audience text NOT NULL DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'teachers', 'parents', 'staff_only')),
  is_published boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  title text NOT NULL,
  body text NOT NULL,
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal', 'important', 'urgent')),
  target_audience text NOT NULL DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'teachers', 'parents', 'staff_only')),
  is_published boolean NOT NULL DEFAULT true,
  published_at timestamptz NOT NULL DEFAULT now(),
  expires_at date,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS school_events_dates_idx ON public.school_events (school_id, starts_on, ends_on);
CREATE INDEX IF NOT EXISTS school_events_type_idx ON public.school_events (event_type, target_audience);
CREATE INDEX IF NOT EXISTS announcements_school_idx ON public.announcements (school_id, is_published, published_at DESC);

-- RLS & Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.school_events TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.announcements TO authenticated;

GRANT ALL ON public.school_events TO service_role;
GRANT ALL ON public.announcements TO service_role;

ALTER TABLE public.school_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Policies for School Events
CREATE POLICY "staff read school_events" ON public.school_events
  FOR SELECT TO authenticated
  USING (public.is_staff(auth.uid()));

CREATE POLICY "managers insert school_events" ON public.school_events
  FOR INSERT TO authenticated
  WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers update school_events" ON public.school_events
  FOR UPDATE TO authenticated
  USING (public.can_manage(auth.uid()))
  WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers delete school_events" ON public.school_events
  FOR DELETE TO authenticated
  USING (public.can_manage(auth.uid()));

-- Policies for Announcements
CREATE POLICY "staff read announcements" ON public.announcements
  FOR SELECT TO authenticated
  USING (public.is_staff(auth.uid()));

CREATE POLICY "managers insert announcements" ON public.announcements
  FOR INSERT TO authenticated
  WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers update announcements" ON public.announcements
  FOR UPDATE TO authenticated
  USING (public.can_manage(auth.uid()))
  WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers delete announcements" ON public.announcements
  FOR DELETE TO authenticated
  USING (public.can_manage(auth.uid()));
