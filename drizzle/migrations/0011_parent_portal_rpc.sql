-- Migration 0011: Parent Portal Secure RPC
-- Resolves RLS restriction for non-JWT authenticated guardians by providing a secure SECURITY DEFINER RPC.
-- Validates (guardian_id, account_code) pair before returning linked students, grades, attendance, and fees.

CREATE OR REPLACE FUNCTION public.parent_get_portal_data(_guardian_id uuid, _account_code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_guardian RECORD;
  v_children jsonb := '[]'::jsonb;
  v_announcements jsonb := '[]'::jsonb;
  v_events jsonb := '[]'::jsonb;
BEGIN
  -- 1. Strict verification of guardian identity
  SELECT * INTO v_guardian 
  FROM public.guardians 
  WHERE id = _guardian_id 
    AND upper(account_code) = upper(trim(_account_code))
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED', 'message', 'بيانات الحساب غير مطابقة.');
  END IF;

  IF v_guardian.status = 'suspended' THEN
    RETURN jsonb_build_object('success', false, 'error', 'ACCOUNT_SUSPENDED', 'message', 'تم إيقاف حساب ولي الأمر من قبل إدارة المدرسة.');
  END IF;

  IF v_guardian.status = 'revoked' OR v_guardian.status = 'pending_activation' THEN
    RETURN jsonb_build_object('success', false, 'error', 'ACCOUNT_INACTIVE', 'message', 'الحساب غير مفعّل. يرجى التواصل مع إدارة المدرسة.');
  END IF;

  -- 2. Fetch linked children with assessments, attendance, and fees
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
      'grades', COALESCE((
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
      ), '[]'::jsonb),
      'attendance', COALESCE((
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
      ), '[]'::jsonb),
      'fees', CASE WHEN gs.can_view_fees THEN (
        SELECT jsonb_build_object(
          'total_due', COALESCE((SELECT SUM(amount) FROM public.fee_structures fs WHERE fs.grade_id = sec.grade_id), 0),
          'total_discounts', COALESCE((SELECT SUM(amount) FROM public.student_fee_discounts sfd WHERE sfd.student_id = s.id), 0),
          'total_paid', COALESCE((SELECT SUM(amount) FROM public.student_payments sp WHERE sp.student_id = s.id), 0),
          'payments', COALESCE((
            SELECT jsonb_agg(
              jsonb_build_object(
                'amount', sp.amount,
                'payment_method', sp.payment_method,
                'receipt_number', sp.receipt_number,
                'created_at', sp.created_at
              ) ORDER BY sp.created_at DESC
            )
            FROM public.student_payments sp
            WHERE sp.student_id = s.id
          ), '[]'::jsonb)
        )
      ) ELSE NULL END
    )
  ) INTO v_children
  FROM public.guardian_students gs
  JOIN public.students s ON s.id = gs.student_id
  LEFT JOIN public.enrollments e ON e.student_id = s.id AND e.status = 'active'
  LEFT JOIN public.sections sec ON sec.id = e.section_id
  LEFT JOIN public.grades g ON g.id = sec.grade_id
  WHERE gs.guardian_id = v_guardian.id;

  -- 3. Fetch announcements
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

  -- 4. Fetch events
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
    'success', true,
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

GRANT EXECUTE ON FUNCTION public.parent_get_portal_data TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.parent_app_login TO anon, authenticated;
