-- 0015: parent_get_dashboard_data() now also returns, per linked child, 'fees' (only if the guardian
-- has can_view_fees) and 'schedule' (approved timetables only). Additive, read-only RPC; same auth.uid() scoping.
CREATE OR REPLACE FUNCTION public.parent_get_dashboard_data()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_guardian RECORD;
  v_children jsonb := '[]'::jsonb;
  v_announcements jsonb := '[]'::jsonb;
  v_events jsonb := '[]'::jsonb;
BEGIN
  SELECT * INTO v_guardian FROM public.guardians WHERE user_id = auth.uid() LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'NOT_REGISTERED', 'message', 'لا يوجد ملف ولي أمر مرتبط بهذا الحساب');
  END IF;

  IF v_guardian.status = 'suspended' THEN
    RETURN jsonb_build_object('error', 'ACCOUNT_SUSPENDED', 'message', 'تم إيقاف حساب ولي الأمر من قبل إدارة المدرسة. يرجى مراجعة إدارة المدرسة.');
  END IF;
  IF v_guardian.status = 'revoked' OR v_guardian.status = 'pending_activation' THEN
    RETURN jsonb_build_object('error', 'ACCOUNT_INACTIVE', 'message', 'الحساب غير مفعّل. يرجى التواصل مع إدارة المدرسة لاستلام كود التفعيل.');
  END IF;

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
      ),
      'fees', (
        CASE WHEN gs.can_view_fees AND e.academic_year_id IS NOT NULL AND sec.grade_id IS NOT NULL THEN (
          SELECT jsonb_build_object(
            'total_due', COALESCE(sum(x.amount), 0),
            'total_discounts', COALESCE(sum(x.discount), 0),
            'total_paid', COALESCE(sum(x.paid), 0),
            'items', COALESCE(jsonb_agg(jsonb_build_object(
                'name', x.name, 'description', x.description, 'amount', x.amount,
                'discount', x.discount, 'paid', x.paid, 'due_date', x.due_date
              ) ORDER BY x.due_date NULLS LAST, x.name), '[]'::jsonb),
            'payments', (
              SELECT COALESCE(jsonb_agg(jsonb_build_object(
                  'amount', pp.amount, 'payment_method', pp.payment_method,
                  'receipt_number', pp.receipt_number, 'created_at', pp.created_at,
                  'fee_name', ft2.name
                ) ORDER BY pp.created_at DESC), '[]'::jsonb)
              FROM public.student_payments pp
              LEFT JOIN public.fee_types ft2 ON ft2.id = pp.fee_type_id
              WHERE pp.student_id = s.id AND pp.academic_year_id = e.academic_year_id
                AND NOT pp.is_reversed AND pp.reversal_payment_id IS NULL
            )
          )
          FROM (
            SELECT ft.name, fs.description, fs.amount, fs.due_date,
                   LEAST(fs.amount, COALESCE(d.total, 0)) AS discount,
                   COALESCE(p.total, 0) AS paid
            FROM public.fee_structures fs
            JOIN public.fee_types ft ON ft.id = fs.fee_type_id
            LEFT JOIN LATERAL (
              SELECT sum(sd.amount) AS total FROM public.student_fee_discounts sd
              WHERE sd.student_id = s.id AND sd.academic_year_id = fs.academic_year_id AND sd.fee_type_id = fs.fee_type_id
            ) d ON true
            LEFT JOIN LATERAL (
              SELECT sum(sp.amount) AS total FROM public.student_payments sp
              WHERE sp.student_id = s.id AND sp.academic_year_id = fs.academic_year_id AND sp.fee_type_id = fs.fee_type_id
                AND NOT sp.is_reversed AND sp.reversal_payment_id IS NULL
            ) p ON true
            WHERE fs.academic_year_id = e.academic_year_id AND fs.grade_id = sec.grade_id AND fs.track_id IS NULL
          ) x
        ) ELSE NULL END
      ),
      'schedule', (
        CASE WHEN sec.id IS NOT NULL AND e.academic_year_id IS NOT NULL THEN (
          SELECT COALESCE(jsonb_agg(jsonb_build_object(
              'weekday', q.weekday, 'period_order', q.period_order, 'label', q.label,
              'starts_at', to_char(q.starts_at, 'HH24:MI'), 'ends_at', to_char(q.ends_at, 'HH24:MI'),
              'is_break', q.is_break, 'subject', COALESCE(q.subject, ''), 'room', q.room
            ) ORDER BY q.weekday, q.period_order), '[]'::jsonb)
          FROM (
            SELECT te.weekday, pr.period_order, pr.label, pr.starts_at, pr.ends_at, pr.is_break, sb.name AS subject, te.room
            FROM public.timetable_entries te
            JOIN public.section_timetables st ON st.section_id = te.section_id AND st.status = 'approved'
            JOIN public.periods pr ON pr.id = te.period_id
            LEFT JOIN public.subjects sb ON sb.id = te.subject_id
            WHERE te.section_id = sec.id AND te.academic_year_id = e.academic_year_id
            UNION ALL
            SELECT w.weekday, pr.period_order, pr.label, pr.starts_at, pr.ends_at, pr.is_break, NULL, NULL
            FROM (
              SELECT DISTINCT te.weekday FROM public.timetable_entries te
              JOIN public.section_timetables st ON st.section_id = te.section_id AND st.status = 'approved'
              WHERE te.section_id = sec.id AND te.academic_year_id = e.academic_year_id
            ) w
            CROSS JOIN public.periods pr
            WHERE pr.is_break
          ) q
        ) ELSE '[]'::jsonb END
      )
    )
  ) INTO v_children
  FROM public.guardian_students gs
  JOIN public.students s ON s.id = gs.student_id
  LEFT JOIN public.enrollments e ON e.student_id = s.id AND e.status = 'active'
  LEFT JOIN public.sections sec ON sec.id = e.section_id
  LEFT JOIN public.grades g ON g.id = sec.grade_id
  WHERE gs.guardian_id = v_guardian.id;

  SELECT jsonb_agg(
    jsonb_build_object('id', id, 'title', title, 'body', body, 'priority', priority, 'published_at', published_at)
    ORDER BY published_at DESC
  ) INTO v_announcements
  FROM public.announcements
  WHERE is_published = true
    AND target_audience IN ('all', 'parents')
    AND (expires_at IS NULL OR expires_at >= CURRENT_DATE);

  SELECT jsonb_agg(
    jsonb_build_object('id', id, 'title', title, 'description', description, 'event_type', event_type,
                       'starts_on', starts_on, 'ends_on', ends_on)
    ORDER BY starts_on ASC
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
$function$;
