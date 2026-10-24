-- Migration 0006: Grades, Assessments, Exams, and Results Lifecycle
-- Workflow: draft -> review -> approved -> published
-- Updated per FIX-1 (F-012, F-016, F-022)

CREATE TABLE IF NOT EXISTS public.assessment_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  name text NOT NULL,
  default_max_score numeric(5, 2) NOT NULL DEFAULT 100,
  weight numeric(5, 2) NOT NULL DEFAULT 1.0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  section_id uuid NOT NULL REFERENCES public.sections(id) ON DELETE RESTRICT,
  subject_id uuid NOT NULL REFERENCES public.subjects(id) ON DELETE RESTRICT,
  title text NOT NULL,
  term text NOT NULL DEFAULT 'term_1' CHECK (term IN ('term_1', 'term_2', 'annual', 'midterm', 'final')),
  max_score numeric(5, 2) NOT NULL DEFAULT 100 CHECK (max_score > 0),
  pass_score numeric(5, 2) NOT NULL DEFAULT 50 CHECK (pass_score >= 0),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'approved', 'published')),
  created_by uuid REFERENCES public.profiles(id),
  approved_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (section_id, subject_id, term, title)
);

CREATE TABLE IF NOT EXISTS public.student_grades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id uuid NOT NULL REFERENCES public.assessments(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  score numeric(5, 2) CHECK (score >= 0),
  is_absent boolean NOT NULL DEFAULT false,
  absence_reason text,
  notes text,
  updated_by uuid REFERENCES public.profiles(id),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (assessment_id, student_id)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS assessments_section_idx ON public.assessments (section_id, academic_year_id);
CREATE INDEX IF NOT EXISTS student_grades_assessment_idx ON public.student_grades (assessment_id);
CREATE INDEX IF NOT EXISTS student_grades_student_idx ON public.student_grades (student_id);

-- F-016 & F-012: Grade Score Validation and Published Lock Triggers
CREATE OR REPLACE FUNCTION public.check_grade_score_and_status()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_max_score numeric(5, 2);
  v_status text;
BEGIN
  SELECT max_score, status INTO v_max_score, v_status
  FROM public.assessments
  WHERE id = NEW.assessment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الاختبار المحدد غير موجود';
  END IF;

  -- F-012: Prevent grade modification once published
  IF v_status = 'published' AND NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'لا يمكن تعديل أو رصد درجات لاختبار معتمد ومنشور رسمياً. فك النشر أولاً لإجراء أي تعديل.';
  END IF;

  -- F-016: Score bound check
  IF NEW.score IS NOT NULL AND NEW.score > v_max_score THEN
    RAISE EXCEPTION 'الدرجة المرصودة (%) تتجاوز النهاية العظمى المعتمدة للاختبار (%)', NEW.score, v_max_score;
  END IF;

  NEW.updated_at := now();
  IF auth.uid() IS NOT NULL THEN
    NEW.updated_by := auth.uid();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_grade_score_and_status ON public.student_grades;
CREATE TRIGGER trg_check_grade_score_and_status
  BEFORE INSERT OR UPDATE ON public.student_grades
  FOR EACH ROW EXECUTE FUNCTION public.check_grade_score_and_status();

-- RLS & Grants
GRANT SELECT, INSERT, UPDATE ON public.assessment_categories TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.assessments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.student_grades TO authenticated;

GRANT ALL ON public.assessment_categories TO service_role;
GRANT ALL ON public.assessments TO service_role;
GRANT ALL ON public.student_grades TO service_role;

ALTER TABLE public.assessment_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_grades ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "staff read assessment_categories" ON public.assessment_categories FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "managers manage assessment_categories" ON public.assessment_categories FOR ALL TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "staff read assessments" ON public.assessments FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff create assessments" ON public.assessments FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "staff update assessments" ON public.assessments FOR UPDATE TO authenticated USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));

CREATE POLICY "staff read student_grades" ON public.student_grades FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff insert student_grades" ON public.student_grades FOR INSERT TO authenticated WITH CHECK (public.is_staff(auth.uid()));
CREATE POLICY "staff update student_grades" ON public.student_grades FOR UPDATE TO authenticated USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));

-- F-022: Audit triggers on assessments and student_grades
CREATE OR REPLACE TRIGGER audit_assessments
  AFTER INSERT OR UPDATE OR DELETE ON public.assessments
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

CREATE OR REPLACE TRIGGER audit_student_grades
  AFTER INSERT OR UPDATE OR DELETE ON public.student_grades
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();
