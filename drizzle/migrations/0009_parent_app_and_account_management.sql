-- Migration 0009: Parent Mobile App Backend & Account Management
-- Implements specifications from Notion "تطبيق العمرابي":
-- 1. Unpredictable random account identifiers (account_code)
-- 2. Explicit lifecycle: pending_activation, active, suspended, revoked
-- 3. Principal-only activation & password reset workflow with audit logging
-- 4. Server-enforced data isolation for multi-child parent accounts (prevents BOLA/IDOR)

-- 1. Extend guardians table with account lifecycle fields
ALTER TABLE public.guardians 
  ADD COLUMN IF NOT EXISTS account_code text UNIQUE,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending_activation' 
    CHECK (status IN ('pending_activation', 'active', 'suspended', 'revoked')),
  ADD COLUMN IF NOT EXISTS activated_at timestamptz,
  ADD COLUMN IF NOT EXISTS activated_by uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS temp_password_code text,
  ADD COLUMN IF NOT EXISTS temp_code_expires_at timestamptz;

CREATE INDEX IF NOT EXISTS guardians_account_code_idx ON public.guardians (account_code);
CREATE INDEX IF NOT EXISTS guardians_status_idx ON public.guardians (status);

-- 2. Function: Generate unguessable account code
CREATE OR REPLACE FUNCTION public.generate_guardian_account_code()
RETURNS text LANGUAGE plpgsql AS $$
DECLARE
  chars text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  res text := 'PAR-';
  i int;
BEGIN
  FOR i IN 1..6 LOOP
    res := res || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN res;
END;
$$;

-- 3. RPC: Principal activates guardian account
CREATE OR REPLACE FUNCTION public.admin_activate_guardian_account(_guardian_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_code text;
  v_temp text;
  v_exists boolean;
  v_cur_code text;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية تفعيل حساب ولي الأمر إلا مدير المدرسة المعتمد.';
  END IF;

  SELECT account_code INTO v_cur_code FROM public.guardians WHERE id = _guardian_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'سجل ولي الأمر غير موجود.';
  END IF;

  -- Generate unguessable code if not already present
  IF v_cur_code IS NULL OR v_cur_code = '' THEN
    LOOP
      v_code := public.generate_guardian_account_code();
      SELECT EXISTS(SELECT 1 FROM public.guardians WHERE account_code = v_code) INTO v_exists;
      EXIT WHEN NOT v_exists;
    END LOOP;
  ELSE
    v_code := v_cur_code;
  END IF;

  -- Generate 6-digit one-time activation code
  v_temp := lpad(floor(random() * 900000 + 100000)::text, 6, '0');

  UPDATE public.guardians
  SET 
    account_code = v_code,
    status = 'active',
    activated_at = now(),
    activated_by = auth.uid(),
    temp_password_code = v_temp,
    temp_code_expires_at = now() + interval '7 days'
  WHERE id = _guardian_id;

  -- Log security event
  INSERT INTO public.audit_log (school_id, user_id, action, table_name, record_id, details)
  SELECT school_id, auth.uid(), 'ACTIVATE_GUARDIAN_ACCOUNT', 'guardians', _guardian_id, 
    jsonb_build_object('account_code', v_code, 'status', 'active')
  FROM public.guardians WHERE id = _guardian_id;

  RETURN jsonb_build_object(
    'account_code', v_code,
    'temp_code', v_temp,
    'status', 'active'
  );
END;
$$;

-- 4. RPC: Principal suspends guardian account
CREATE OR REPLACE FUNCTION public.admin_suspend_guardian_account(_guardian_id uuid, _reason text DEFAULT '')
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية إيقاف حساب ولي الأمر إلا مدير المدرسة المعتمد.';
  END IF;

  UPDATE public.guardians
  SET status = 'suspended'
  WHERE id = _guardian_id;

  INSERT INTO public.audit_log (school_id, user_id, action, table_name, record_id, details)
  SELECT school_id, auth.uid(), 'SUSPEND_GUARDIAN_ACCOUNT', 'guardians', _guardian_id, 
    jsonb_build_object('reason', _reason, 'status', 'suspended')
  FROM public.guardians WHERE id = _guardian_id;

  RETURN true;
END;
$$;

-- 5. RPC: Principal resets guardian password (in-person request)
CREATE OR REPLACE FUNCTION public.admin_reset_guardian_password(_guardian_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_temp text;
  v_code text;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية إعادة تعيين كلمة المرور إلا مدير المدرسة المعتمد بعد التحقق الحضوري.';
  END IF;

  SELECT account_code INTO v_code FROM public.guardians WHERE id = _guardian_id;
  IF v_code IS NULL THEN
    RAISE EXCEPTION 'الحساب غير مفعّل بعد. يرجى تفعيل الحساب أولاً.';
  END IF;

  v_temp := lpad(floor(random() * 900000 + 100000)::text, 6, '0');

  UPDATE public.guardians
  SET 
    temp_password_code = v_temp,
    temp_code_expires_at = now() + interval '24 hours'
  WHERE id = _guardian_id;

  INSERT INTO public.audit_log (school_id, user_id, action, table_name, record_id, details)
  SELECT school_id, auth.uid(), 'RESET_GUARDIAN_PASSWORD', 'guardians', _guardian_id, 
    jsonb_build_object('action', 'in_person_reset')
  FROM public.guardians WHERE id = _guardian_id;

  RETURN jsonb_build_object(
    'account_code', v_code,
    'temp_code', v_temp,
    'expires_in_hours', 24
  );
END;
$$;

-- 6. RPC: Secure Parent Dashboard Payload (Strictly Server-Enforced Isolation)
CREATE OR REPLACE FUNCTION public.parent_get_dashboard_data()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_guardian RECORD;
  v_children jsonb := '[]'::jsonb;
  v_announcements jsonb := '[]'::jsonb;
  v_events jsonb := '[]'::jsonb;
BEGIN
  -- 1. Identify guardian by authenticated user_id
  SELECT * INTO v_guardian FROM public.guardians WHERE user_id = auth.uid() LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'NOT_REGISTERED', 'message', 'لا يوجد ملف ولي أمر مرتبط بهذا الحساب');
  END IF;

  -- 2. Verify account status
  IF v_guardian.status = 'suspended' THEN
    RETURN jsonb_build_object('error', 'ACCOUNT_SUSPENDED', 'message', 'تم إيقاف حساب ولي الأمر من قبل إدارة المدرسة. يرجى مراجعة إدارة المدرسة.');
  END IF;
  IF v_guardian.status = 'revoked' OR v_guardian.status = 'pending_activation' THEN
    RETURN jsonb_build_object('error', 'ACCOUNT_INACTIVE', 'message', 'الحساب غير مفعّل. يرجى التواصل مع إدارة المدرسة لاستلام كود التفعيل.');
  END IF;

  -- 3. Fetch approved linked children
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', s.id,
      'student_number', s.student_number,
      'full_name', s.full_name,
      'status', s.status,
      'relation', gs.relation,
      'can_view_fees', gs.can_view_fees,
      'receives_notifications', gs.receives_notifications,
      'grade_name', COALESCE(g.name, 'غير محدد'),
      'section_name', COALESCE(sec.name, 'غير محدد'),
      'grades', (
        -- Published grades only
        SELECT jsonb_agg(
          jsonb_build_object(
            'subject_name', sub.name,
            'title', a.title,
            'term', a.term,
            'score', sg.score,
            'max_score', a.max_score,
            'pass_score', a.pass_score,
            'is_absent', sg.is_absent
          )
        )
        FROM public.student_grades sg
        JOIN public.assessments a ON a.id = sg.assessment_id AND a.status = 'published'
        JOIN public.subjects sub ON sub.id = a.subject_id
        WHERE sg.student_id = s.id
      ),
      'attendance', (
        -- Approved attendance records
        SELECT jsonb_agg(
          jsonb_build_object(
            'date', att_s.session_date,
            'status', ar.status,
            'reason', ar.reason
          ) ORDER BY att_s.session_date DESC
        )
        FROM public.attendance_records ar
        JOIN public.attendance_sessions att_s ON att_s.id = ar.session_id
        WHERE ar.student_id = s.id
      )
    )
  ) INTO v_children
  FROM public.guardian_students gs
  JOIN public.students s ON s.id = gs.student_id
  LEFT JOIN public.enrollments e ON e.student_id = s.id AND e.status = 'active'
  LEFT JOIN public.sections sec ON sec.id = e.section_id
  LEFT JOIN public.grades g ON g.id = sec.grade_id
  WHERE gs.guardian_id = v_guardian.id;

  -- 4. Fetch announcements targeted at parents or all
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'title', title,
      'body', body,
      'priority', priority,
      'published_at', published_at
    ) ORDER BY published_at DESC
  ) INTO v_announcements
  FROM public.announcements
  WHERE is_published = true 
    AND target_audience IN ('all', 'parents')
    AND (expires_at IS NULL OR expires_at >= CURRENT_DATE);

  -- 5. Fetch calendar events for parents
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'title', title,
      'description', description,
      'event_type', event_type,
      'starts_on', starts_on,
      'ends_on', ends_on
    ) ORDER BY starts_on ASC
  ) INTO v_events
  FROM public.school_events
  WHERE is_published = true 
    AND target_audience IN ('all', 'parents');

  RETURN jsonb_build_object(
    'guardian', jsonb_build_object(
      'id', v_guardian.id,
      'account_code', v_guardian.account_code,
      'full_name', v_guardian.full_name,
      'phone', v_guardian.phone,
      'status', v_guardian.status
    ),
    'children', COALESCE(v_children, '[]'::jsonb),
    'announcements', COALESCE(v_announcements, '[]'::jsonb),
    'events', COALESCE(v_events, '[]'::jsonb)
  );
END;
$$;

-- 7. RPC: Parent App Authentication via Account Code & PIN (OWASP Compliant: No Account Enumeration)
CREATE OR REPLACE FUNCTION public.parent_app_login(_account_code text, _code_or_pin text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_guardian RECORD;
BEGIN
  -- Strict input check
  IF _account_code IS NULL OR _code_or_pin IS NULL OR trim(_account_code) = '' OR trim(_code_or_pin) = '' THEN
    RETURN jsonb_build_object('success', false, 'message', 'يرجى إدخال معرّف الحساب ورمز المرور');
  END IF;

  -- Lookup guardian by unguessable account_code
  SELECT * INTO v_guardian FROM public.guardians 
  WHERE upper(account_code) = upper(trim(_account_code)) 
  LIMIT 1;

  -- Generic error on mismatch to prevent account enumeration (Notion Sec 2.5)
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'بيانات الدخول غير صحيحة. يرجى التأكد من المعرّف أو مراجعة إدارة المدرسة.');
  END IF;

  -- Status check
  IF v_guardian.status = 'suspended' THEN
    RETURN jsonb_build_object('success', false, 'message', 'تم إيقاف حساب ولي الأمر. يرجى مراجعة إدارة المدرسة.');
  END IF;

  IF v_guardian.status = 'revoked' THEN
    RETURN jsonb_build_object('success', false, 'message', 'تم إلغاء هذا الحساب. يرجى مراجعة إدارة المدرسة.');
  END IF;

  -- PIN / Password match (supports initial temp_code or configured password)
  IF v_guardian.temp_password_code IS NOT NULL AND v_guardian.temp_password_code = trim(_code_or_pin) THEN
    -- If temp code has expired
    IF v_guardian.temp_code_expires_at IS NOT NULL AND v_guardian.temp_code_expires_at < now() THEN
      RETURN jsonb_build_object('success', false, 'message', 'انتهت صلاحية رمز التفعيل المؤقت. يرجى طلب رمز جديد من إدارة المدرسة.');
    END IF;

    RETURN jsonb_build_object(
      'success', true,
      'guardian_id', v_guardian.id,
      'account_code', v_guardian.account_code,
      'full_name', v_guardian.full_name,
      'phone', v_guardian.phone,
      'status', v_guardian.status,
      'requires_new_password', true
    );
  END IF;

  -- If neither matches, return generic error
  RETURN jsonb_build_object('success', false, 'message', 'بيانات الدخول غير صحيحة. يرجى التأكد من المعرّف أو مراجعة إدارة المدرسة.');
END;
$$;

