-- Migration 0012: Admissions, Required Documents Checklist, and Document Template Studio
-- Architecture matches Plan1 & Notion specifications for Al-Umrabi Secondary School

-- 1. Extend app_role enum with accountant role (Plan1 Sec 4 & 10)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'accountant' AND enumtypid = 'public.app_role'::regtype) THEN
    ALTER TYPE public.app_role ADD VALUE 'accountant';
  END IF;
END $$;

-- 2. Finance Authorization Helper (least-privilege role for finance and accountant)
CREATE OR REPLACE FUNCTION public.can_finance(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = _user_id AND role IN ('owner', 'principal', 'accountant')
  );
$$;

-- 3. Document Verification Status Type
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_verification_status') THEN
    CREATE TYPE public.document_verification_status AS ENUM (
      'missing',
      'received',
      'under_review',
      'accepted',
      'rejected',
      'waived'
    );
  END IF;
END $$;

-- 4. Student Documents Table (Plan1 Sec 3 - Intermediate Certificate & Transfer Reports)
CREATE TABLE IF NOT EXISTS public.student_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  academic_year_id uuid REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  document_type text NOT NULL CHECK (document_type IN (
    'intermediate_certificate',  -- شهادة المرحلة المتوسطة (إلزامية للمرحلة الثانوية)
    'previous_term_report',     -- شهادة/تقرير الفصل السابق للمنقولين
    'transfer_release_cert',    -- شهادة النقل وإخلاء الطرف
    'birth_certificate',        -- شهادة الميلاد / الرقم الوطني
    'guardian_id_card',         -- إثبات هوية ولي الأمر
    'medical_record',           -- التقرير الطبي
    'other'                     -- مستندات أخرى
  )),
  title text NOT NULL,
  status public.document_verification_status NOT NULL DEFAULT 'missing',
  file_url text,
  file_name text,
  file_size integer,
  is_waived boolean NOT NULL DEFAULT false,
  waiver_reason text,
  waived_by uuid REFERENCES public.profiles(id),
  waived_at timestamptz,
  reviewed_by uuid REFERENCES public.profiles(id),
  reviewed_at timestamptz,
  reviewer_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS student_docs_student_idx ON public.student_documents (student_id);
CREATE INDEX IF NOT EXISTS student_docs_status_idx ON public.student_documents (status);

-- 5. Student Transfers-In Tracking Table (Plan1 Sec 3.B)
CREATE TABLE IF NOT EXISTS public.student_transfers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  previous_school text NOT NULL,
  previous_stage text NOT NULL DEFAULT 'المرحلة المتوسطة',
  previous_grade text,
  completed_term text,
  last_attendance_date date,
  incoming_gpa numeric(5, 2),
  has_intermediate_cert boolean NOT NULL DEFAULT false,
  has_prior_term_report boolean NOT NULL DEFAULT false,
  approval_status text NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected', 'conditional')),
  approved_by uuid REFERENCES public.profiles(id),
  approved_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS student_transfers_student_idx ON public.student_transfers (student_id);

-- 6. Document Templates Table (Plan1 Sec 7 - Editable Studio)
CREATE TABLE IF NOT EXISTS public.document_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  title text NOT NULL,
  template_type text NOT NULL CHECK (template_type IN (
    'enrollment_certificate',   -- إفادة قيد وتسجيل طالب
    'conduct_certificate',      -- شهادة حسن سير وسلوك
    'transfer_certificate',     -- شهادة انتقال وإخلاء طرف
    'parent_notice',            -- إشعار / استدعاء ولي أمر
    'fee_clearance',            -- إفادة براءة ذمة مالية
    'grade_transcript',         -- كشف درجات أكاديمي
    'custom'                    -- نموذج مخصص
  )),
  content text NOT NULL,
  version integer NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'archived')),
  page_orientation text NOT NULL DEFAULT 'portrait' CHECK (page_orientation IN ('portrait', 'landscape')),
  show_header boolean NOT NULL DEFAULT true,
  show_signature boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS doc_templates_school_idx ON public.document_templates (school_id);
CREATE INDEX IF NOT EXISTS doc_templates_status_idx ON public.document_templates (status);

-- 7. Issued Documents Registry (Plan1 Sec 7 - Exact Versioned Immutability)
CREATE TABLE IF NOT EXISTS public.issued_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  document_number text NOT NULL UNIQUE,
  template_id uuid NOT NULL REFERENCES public.document_templates(id) ON DELETE RESTRICT,
  template_version integer NOT NULL,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  rendered_content text NOT NULL,
  issued_by uuid NOT NULL REFERENCES public.profiles(id),
  issued_at timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled')),
  cancel_reason text,
  cancelled_by uuid REFERENCES public.profiles(id),
  cancelled_at timestamptz
);

CREATE INDEX IF NOT EXISTS issued_docs_number_idx ON public.issued_documents (document_number);
CREATE INDEX IF NOT EXISTS issued_docs_student_idx ON public.issued_documents (student_id);

-- Sequence for Document Reference Numbers
CREATE SEQUENCE IF NOT EXISTS public.document_number_seq START 1001;

-- 8. Enhanced RPC: Create Student with Admission Document Checklist
CREATE OR REPLACE FUNCTION public.create_student_with_admission(
  _student jsonb,
  _academic_year uuid,
  _section uuid,
  _enrollment_type public.enrollment_type,
  _admission_details jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_student_id uuid;
  v_grade_level integer;
  v_has_intermediate boolean;
  v_has_prior_report boolean;
  v_waiver_reason text;
  v_school_id uuid;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية قبول وقيد الطلاب إلا مدير المدرسة أو المشرف المعتمد.';
  END IF;

  v_school_id := (_student->>'school_id')::uuid;
  IF v_school_id IS NULL THEN
    SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  END IF;

  -- 1. Identify Grade Level
  SELECT g.level_order INTO v_grade_level
  FROM public.sections sec
  JOIN public.grades g ON g.id = sec.grade_id
  WHERE sec.id = _section;

  v_has_intermediate := COALESCE((_admission_details->>'has_intermediate_cert')::boolean, false);
  v_has_prior_report := COALESCE((_admission_details->>'has_prior_term_report')::boolean, false);
  v_waiver_reason := trim(COALESCE(_admission_details->>'waiver_reason', ''));

  -- Secondary Entry Requirement: Intermediate School Certificate (شهادة المرحلة المتوسطة)
  -- Mandatory unless an authorized waiver with documented reason exists
  IF NOT v_has_intermediate AND v_waiver_reason = '' THEN
    RAISE EXCEPTION 'شهادة المرحلة المتوسطة مطلوبة للتسجيل في المرحلة الثانوية. إذا كان هناك استثناء رسمي معتمد، يرجى تدوين سبب الاستثناء.';
  END IF;

  -- Transfer-in to Grade 2 or 3 requires previous school report
  IF _enrollment_type = 'transfer_in' AND v_grade_level > 1 AND NOT v_has_prior_report AND v_waiver_reason = '' THEN
    RAISE EXCEPTION 'تقرير درجات/شهادة الفصل السابق مطلوبة للطلاب المنقولين لصفوف متقدمة، أو تدوين سبب الاستثناء المعتمد.';
  END IF;

  -- 2. Insert Student Core Profile
  INSERT INTO public.students (
    school_id, full_name, gender, birth_date, national_id, address,
    guardian_name, guardian_relation, guardian_phone, previous_school, notes
  ) VALUES (
    v_school_id,
    _student->>'full_name',
    NULLIF(_student->>'gender', ''),
    NULLIF(_student->>'birth_date', '')::date,
    NULLIF(_student->>'national_id', ''),
    NULLIF(_student->>'address', ''),
    NULLIF(_student->>'guardian_name', ''),
    NULLIF(_student->>'guardian_relation', ''),
    NULLIF(_student->>'guardian_phone', ''),
    NULLIF(_student->>'previous_school', ''),
    NULLIF(_student->>'notes', '')
  ) RETURNING id INTO v_student_id;

  -- 3. Insert Enrollment
  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_student_id, _academic_year, _section, _enrollment_type, 'active');

  -- 4. Record Intermediate Certificate Status
  INSERT INTO public.student_documents (
    student_id, school_id, academic_year_id, document_type, title, status, is_waived, waiver_reason, waived_by, waived_at
  ) VALUES (
    v_student_id, v_school_id, _academic_year, 'intermediate_certificate', 'شهادة إتمام المرحلة المتوسطة',
    CASE WHEN v_has_intermediate THEN 'accepted'::public.document_verification_status
         WHEN v_waiver_reason <> '' THEN 'waived'::public.document_verification_status
         ELSE 'missing'::public.document_verification_status END,
    (v_waiver_reason <> ''),
    NULLIF(v_waiver_reason, ''),
    CASE WHEN v_waiver_reason <> '' THEN auth.uid() ELSE NULL END,
    CASE WHEN v_waiver_reason <> '' THEN now() ELSE NULL END
  );

  -- 5. Record Prior Term Report if Transfer
  IF _enrollment_type = 'transfer_in' THEN
    INSERT INTO public.student_documents (
      student_id, school_id, academic_year_id, document_type, title, status, is_waived, waiver_reason, waived_by, waived_at
    ) VALUES (
      v_student_id, v_school_id, _academic_year, 'previous_term_report', 'تقرير نتائج الفصل السابق من المدرسة السابقة',
      CASE WHEN v_has_prior_report THEN 'accepted'::public.document_verification_status
           WHEN v_waiver_reason <> '' THEN 'waived'::public.document_verification_status
           ELSE 'missing'::public.document_verification_status END,
      (v_waiver_reason <> ''),
      NULLIF(v_waiver_reason, ''),
      CASE WHEN v_waiver_reason <> '' THEN auth.uid() ELSE NULL END,
      CASE WHEN v_waiver_reason <> '' THEN now() ELSE NULL END
    );

    INSERT INTO public.student_transfers (
      student_id, academic_year_id, previous_school, previous_stage, previous_grade,
      has_intermediate_cert, has_prior_term_report, approval_status, approved_by, approved_at
    ) VALUES (
      v_student_id, _academic_year, COALESCE(_student->>'previous_school', 'غير محدد'),
      'المرحلة الثانوية', 'الصف ' || (v_grade_level - 1)::text,
      v_has_intermediate, v_has_prior_report, 'approved', auth.uid(), now()
    );
  END IF;

  -- 6. Audit Log
  INSERT INTO public.audit_log (table_name, record_id, action, new_data, actor_id)
  VALUES ('students', v_student_id::text, 'ADMIT_STUDENT', jsonb_build_object(
    'full_name', _student->>'full_name',
    'enrollment_type', _enrollment_type,
    'has_intermediate_cert', v_has_intermediate,
    'waived', (v_waiver_reason <> '')
  ), auth.uid());

  RETURN jsonb_build_object(
    'success', true,
    'student_id', v_student_id
  );
END;
$$;

-- RLS & Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.student_documents TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.student_transfers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.document_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.issued_documents TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.document_number_seq TO authenticated;

GRANT ALL ON public.student_documents TO service_role;
GRANT ALL ON public.student_transfers TO service_role;
GRANT ALL ON public.document_templates TO service_role;
GRANT ALL ON public.issued_documents TO service_role;
GRANT ALL ON SEQUENCE public.document_number_seq TO service_role;

ALTER TABLE public.student_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issued_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view all student documents" ON public.student_documents
  FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

CREATE POLICY "Staff can insert/update student documents" ON public.student_documents
  FOR ALL TO authenticated USING (public.can_manage(auth.uid()));

CREATE POLICY "Staff can view student transfers" ON public.student_transfers
  FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

CREATE POLICY "Staff can manage student transfers" ON public.student_transfers
  FOR ALL TO authenticated USING (public.can_manage(auth.uid()));

CREATE POLICY "Staff can view document templates" ON public.document_templates
  FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

CREATE POLICY "Staff can manage document templates" ON public.document_templates
  FOR ALL TO authenticated USING (public.can_manage(auth.uid()));

CREATE POLICY "Staff can view issued documents" ON public.issued_documents
  FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

CREATE POLICY "Staff can issue documents" ON public.issued_documents
  FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
