-- Migration 0005: Fees, Payments, Discounts, and Guardians Schema
-- Architecture matches Notion & ANTIGRAVITY specs for Al-Umrabi School
-- Updated per FIX-1 (F-014, F-015, F-022)

-- 1. Fee Types (دراسة، زي، كتب، نقل، إلخ)
CREATE TABLE IF NOT EXISTS public.fee_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Fee Structures (الرسوم المقررة لكل صف وسنة دراسية)
-- F-015: UNIQUE NULLS NOT DISTINCT to prevent duplicate fee structures when track_id is NULL
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
  CONSTRAINT fee_structures_unique_academic_grade_track_fee 
    UNIQUE NULLS NOT DISTINCT (academic_year_id, grade_id, track_id, fee_type_id)
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

-- 4. Server-Side Sequence for Unique Receipt Numbers (F-014)
CREATE SEQUENCE IF NOT EXISTS public.receipt_number_seq START 1;

-- 5. Student Payments (المدفوعات والإيصالات)
-- F-014: Idempotency key, server-generated receipt, no delete/update (reversals only)
CREATE TABLE IF NOT EXISTS public.student_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  fee_type_id uuid NOT NULL REFERENCES public.fee_types(id) ON DELETE RESTRICT,
  amount numeric(12, 2) NOT NULL CHECK (amount > 0),
  payment_method text NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'cheque', 'pos')),
  receipt_number text NOT NULL UNIQUE,
  idempotency_key text UNIQUE,
  is_reversed boolean NOT NULL DEFAULT false,
  reversal_payment_id uuid REFERENCES public.student_payments(id),
  reversal_reason text,
  notes text,
  recorded_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 6. Payment Allocations (تخصيص الدفعات على المستحقات)
CREATE TABLE IF NOT EXISTS public.student_payment_allocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id uuid NOT NULL REFERENCES public.student_payments(id) ON DELETE RESTRICT,
  fee_structure_id uuid NOT NULL REFERENCES public.fee_structures(id) ON DELETE RESTRICT,
  allocated_amount numeric(12, 2) NOT NULL CHECK (allocated_amount > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 7. Guardians & Family Relations (أولياء الأمور والربط مع الطلاب)
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
CREATE INDEX IF NOT EXISTS student_payments_idempotency_idx ON public.student_payments (idempotency_key);
CREATE INDEX IF NOT EXISTS student_discounts_student_idx ON public.student_fee_discounts (student_id, academic_year_id);
CREATE INDEX IF NOT EXISTS guardians_phone_idx ON public.guardians (phone);
CREATE INDEX IF NOT EXISTS guardian_students_guardian_idx ON public.guardian_students (guardian_id);

-- RLS & Grants
GRANT SELECT, INSERT, UPDATE ON public.fee_types TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.fee_structures TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.student_fee_discounts TO authenticated;
GRANT SELECT, INSERT ON public.student_payments TO authenticated;
GRANT SELECT, INSERT ON public.student_payment_allocations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.guardians TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.guardian_students TO authenticated;

GRANT ALL ON public.fee_types TO service_role;
GRANT ALL ON public.fee_structures TO service_role;
GRANT ALL ON public.student_fee_discounts TO service_role;
GRANT ALL ON public.student_payments TO service_role;
GRANT ALL ON public.student_payment_allocations TO service_role;
GRANT ALL ON public.guardians TO service_role;
GRANT ALL ON public.guardian_students TO service_role;

ALTER TABLE public.fee_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_fee_discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_payment_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guardian_students ENABLE ROW LEVEL SECURITY;

-- Staff Read Policies
CREATE POLICY "staff read fee_types" ON public.fee_types FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read fee_structures" ON public.fee_structures FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read student_discounts" ON public.student_fee_discounts FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read student_payments" ON public.student_payments FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read payment_allocations" ON public.student_payment_allocations FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read guardians" ON public.guardians FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));
CREATE POLICY "staff read guardian_students" ON public.guardian_students FOR SELECT TO authenticated USING (public.is_staff(auth.uid()));

-- Manager Write Policies
CREATE POLICY "managers insert fee_types" ON public.fee_types FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update fee_types" ON public.fee_types FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert fee_structures" ON public.fee_structures FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update fee_structures" ON public.fee_structures FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert student_discounts" ON public.student_fee_discounts FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update student_discounts" ON public.student_fee_discounts FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

-- F-014: Payments can only be inserted, never updated or deleted by clients (immutable audit trail)
CREATE POLICY "managers insert student_payments" ON public.student_payments FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers insert payment_allocations" ON public.student_payment_allocations FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert guardians" ON public.guardians FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update guardians" ON public.guardians FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

CREATE POLICY "managers insert guardian_students" ON public.guardian_students FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()));
CREATE POLICY "managers update guardian_students" ON public.guardian_students FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()));

-- F-022: Audit triggers on all financial tables
CREATE OR REPLACE TRIGGER audit_fee_structures
  AFTER INSERT OR UPDATE OR DELETE ON public.fee_structures
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

CREATE OR REPLACE TRIGGER audit_student_fee_discounts
  AFTER INSERT OR UPDATE OR DELETE ON public.student_fee_discounts
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

CREATE OR REPLACE TRIGGER audit_student_payments
  AFTER INSERT OR UPDATE OR DELETE ON public.student_payments
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

CREATE OR REPLACE TRIGGER audit_guardians
  AFTER INSERT OR UPDATE OR DELETE ON public.guardians
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

CREATE OR REPLACE TRIGGER audit_guardian_students
  AFTER INSERT OR UPDATE OR DELETE ON public.guardian_students
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

-- F-014: Server-side atomic payment recording with idempotency and sequential receipt generation
CREATE OR REPLACE FUNCTION public.record_student_payment(
  p_student_id uuid,
  p_academic_year_id uuid,
  p_fee_type_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_notes text DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_seq bigint;
  v_receipt text;
  v_existing RECORD;
  v_new_payment RECORD;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'لا تملك صلاحية تسجيل المدفوعات والرسوم';
  END IF;

  -- Idempotency check: if already recorded with this key, return existing receipt
  IF p_idempotency_key IS NOT NULL AND p_idempotency_key <> '' THEN
    SELECT * INTO v_existing FROM public.student_payments WHERE idempotency_key = p_idempotency_key;
    IF FOUND THEN
      RETURN jsonb_build_object(
        'success', true,
        'is_duplicate', true,
        'payment_id', v_existing.id,
        'receipt_number', v_existing.receipt_number
      );
    END IF;
  END IF;

  -- Generate sequential receipt number: REC-YYYY-000001
  SELECT nextval('public.receipt_number_seq') INTO v_seq;
  v_receipt := 'REC-' || to_char(CURRENT_DATE, 'YYYY') || '-' || lpad(v_seq::text, 6, '0');

  INSERT INTO public.student_payments (
    student_id,
    academic_year_id,
    fee_type_id,
    amount,
    payment_method,
    receipt_number,
    idempotency_key,
    notes,
    recorded_by
  ) VALUES (
    p_student_id,
    p_academic_year_id,
    p_fee_type_id,
    p_amount,
    p_payment_method,
    v_receipt,
    p_idempotency_key,
    p_notes,
    auth.uid()
  )
  RETURNING * INTO v_new_payment;

  RETURN jsonb_build_object(
    'success', true,
    'is_duplicate', false,
    'payment_id', v_new_payment.id,
    'receipt_number', v_receipt
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.record_student_payment(uuid, uuid, uuid, numeric, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_student_payment(uuid, uuid, uuid, numeric, text, text, text) TO authenticated;

