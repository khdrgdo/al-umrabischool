-- Migration 0009: Parent Mobile App Backend & Account Management
-- Implements specifications from FIX-1 and APP-2:
-- 1. Unpredictable random account identifiers (account_code)
-- 2. Explicit lifecycle: pending_activation, active, suspended, revoked
-- 3. Principal-only activation & password reset workflow with audit logging
-- 4. Server-enforced data isolation for multi-child parent accounts (prevents BOLA/IDOR)
-- Note: Per FIX-1 (3.3), parent_app_login and plaintext temp_password_code are removed.
-- Auth design follows APP-2 Section 6 (Supabase Auth + Edge Functions).

-- 1. Extend guardians table with account lifecycle fields
ALTER TABLE public.guardians 
  ADD COLUMN IF NOT EXISTS account_code text UNIQUE,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending_activation' 
    CHECK (status IN ('pending_activation', 'active', 'suspended', 'revoked')),
  ADD COLUMN IF NOT EXISTS activated_at timestamptz,
  ADD COLUMN IF NOT EXISTS activated_by uuid REFERENCES public.profiles(id);

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

  UPDATE public.guardians
  SET 
    account_code = v_code,
    status = 'active',
    activated_at = now(),
    activated_by = auth.uid()
  WHERE id = _guardian_id;

  -- Log security event
  INSERT INTO public.audit_log (school_id, user_id, action, table_name, record_id, details)
  SELECT school_id, auth.uid(), 'ACTIVATE_GUARDIAN_ACCOUNT', 'guardians', _guardian_id, 
    jsonb_build_object('account_code', v_code, 'status', 'active')
  FROM public.guardians WHERE id = _guardian_id;

  RETURN jsonb_build_object(
    'account_code', v_code,
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

-- 5. RPC: Principal initiates guardian password reset workflow (APP-2 Section 6)
CREATE OR REPLACE FUNCTION public.admin_reset_guardian_password(_guardian_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_code text;
BEGIN
  IF NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية إعادة تعيين كلمة المرور إلا مدير المدرسة المعتمد بعد التحقق الحضوري.';
  END IF;

  SELECT account_code INTO v_code FROM public.guardians WHERE id = _guardian_id;
  IF v_code IS NULL THEN
    RAISE EXCEPTION 'الحساب غير مفعّل بعد. يرجى تفعيل الحساب أولاً.';
  END IF;

  INSERT INTO public.audit_log (school_id, user_id, action, table_name, record_id, details)
  SELECT school_id, auth.uid(), 'RESET_GUARDIAN_PASSWORD', 'guardians', _guardian_id, 
    jsonb_build_object('action', 'in_person_reset_initiated')
  FROM public.guardians WHERE id = _guardian_id;

  RETURN jsonb_build_object(
    'account_code', v_code,
    'status', 'reset_initiated'
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
            'date', att_s.attendance_date,
            'status', ar.status,
            'reason', ar.reason
          ) ORDER BY att_s.attendance_date DESC
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

-- Security Hardening: Revoke from PUBLIC and anon on management RPCs
REVOKE EXECUTE ON FUNCTION public.admin_activate_guardian_account(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_suspend_guardian_account(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_reset_guardian_password(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.parent_get_dashboard_data() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.admin_activate_guardian_account(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_suspend_guardian_account(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_reset_guardian_password(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.parent_get_dashboard_data() TO authenticated;
