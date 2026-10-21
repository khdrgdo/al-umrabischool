-- Migration 0005: Fees, Payments, Discounts, and Guardians Schema
-- Architecture matches Notion & ANTIGRAVITY specs for Al-Umrabi School

-- 1. Fee Types (دراسة، زي، كتب، نقل، إلخ)
CREATE TABLE IF NOT EXISTS public.fee_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Fee Structures (الرسوم المقررة لكل صف وسنة دراسية)
CREATE TABLE IF NOT EXISTS public.fee_structures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  grade_id uuid NOT NULL REFERENCES public.grades(id) ON DELETE RESTRICT,
  track_id uuid REFERENCES public.tracks(id) ON DELETE RESTRICT,
  fee_type_id uuid NOT NULL REFERENCES public.fee_types(id) ON DELETE RESTRICT,
  amount numeric(12, 2) NOT NULL CHECK (amount >= 0),
  due_date date,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (academic_year_id, grade_id, track_id, fee_type_id)
);

-- 3. Student Discounts & Scholarships (المنح والخصومات والإعفاءات)
CREATE TABLE IF NOT EXISTS public.student_fee_discounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  fee_type_id uuid NOT NULL REFERENCES public.fee_types(id) ON DELETE RESTRICT,
  discount_type text NOT NULL CHECK (discount_type IN ('scholarship', 'sibling', 'financial_aid', 'special_discount')),
  amount numeric(12, 2) NOT NULL CHECK (amount >= 0),
  reason text NOT NULL,
  approved_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 4. Student Payments (المدفوعات والإيصالات)
CREATE TABLE IF NOT EXISTS public.student_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  fee_type_id uuid NOT NULL REFERENCES public.fee_types(id) ON DELETE RESTRICT,
  amount numeric(12, 2) NOT NULL CHECK (amount > 0),
  payment_method text NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'cheque', 'pos')),
  receipt_number text NOT NULL,
  notes text,
  recorded_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (receipt_number)
);

-- 5. Guardians & Family Relations (أولياء الأمور والربط مع الطلاب)
CREATE TABLE IF NOT EXISTS public.guardians (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  full_name text NOT NULL,
  phone text NOT NULL,
  national_id text,
  email text,
  address text,
  user_id uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.guardian_students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES public.guardians(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  relation text NOT NULL DEFAULT 'father' CHECK (relation IN ('father', 'mother', 'brother', 'uncle', 'legal_guardian', 'other')),
  is_primary boolean NOT NULL DEFAULT true,
  can_view_fees boolean NOT NULL DEFAULT true,
  receives_notifications boolean NOT NULL DEFAULT true,
  verified_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (guardian_id, student_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS fee_structures_year_idx ON public.fee_structures (academic_year_id);
CREATE INDEX IF NOT EXISTS student_payments_student_idx ON public.student_payments (student_id, academic_year_id);
CREATE INDEX IF NOT EXISTS student_discounts_student_idx ON public.student_fee_discounts (student_id, academic_year_id);
CREATE INDEX IF NOT EXISTS guardians_phone_idx ON public.guardians (phone);
CREATE INDEX IF NOT EXISTS guardian_students_guardian_idx ON public.guardian_students (guardian_id);

-- RLS & Grants
GRANT SELECT, INSERT, UPDATE ON public.fee_types TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.fee_structures TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.student_fee_discounts TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.student_payments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.guardians TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.guardian_students TO authenticated;

GRANT ALL ON public.fee_types TO service_role;
GRANT ALL ON public.fee_structures TO service_role;
GRANT ALL ON public.student_fee_discounts TO service_role;
GRANT ALL ON public.student_payments TO service_role;
GRANT ALL ON public.guardians TO service_role;
GRANT ALL ON public.guardian_students TO service_role;

ALTER TABLE public.fee_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_fee_discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardian_students ENABLE ROW LEVEL SECURITY;

-- Staff Read Policies
CREATE POLICY "staff read fee_types" ON public.fee_types FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read fee_structures" ON public.fee_structures FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read student_discounts" ON public.student_fee_discounts FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read student_payments" ON public.student_payments FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read guardians" ON public.guardians FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read guardian_students" ON public.guardian_students FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

-- Manager Write Policies
CREATE POLICY "managers insert fee_types" ON public.fee_types FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update fee_types" ON public.fee_types FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert fee_structures" ON public.fee_structures FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update fee_structures" ON public.fee_structures FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert student_discounts" ON public.student_fee_discounts FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update student_discounts" ON public.student_fee_discounts FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert student_payments" ON public.student_payments FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert guardians" ON public.guardians FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update guardians" ON public.guardians FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert guardian_students" ON public.guardian_students FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update guardian_students" ON public.guardian_students FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));
