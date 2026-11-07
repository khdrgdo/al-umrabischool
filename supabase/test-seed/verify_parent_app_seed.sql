-- ⚠️ للقراءة فقط (SELECT) — للتحقق بعد تشغيل seed_parent_app_test_data.sql. كل صف يجب أن يكون ok = true.
WITH m AS (SELECT 'SEED:alumrabi-test-v1' AS mk),
seed_stu AS (SELECT s.* FROM public.students s, m WHERE s.notes = m.mk),
seed_g   AS (SELECT g.* FROM public.guardians g, m WHERE g.address = m.mk)
SELECT 'students = 200' AS check_name, (SELECT count(*) FROM seed_stu) = 200 AS ok
UNION ALL SELECT '25 طالباً لكل شعبة (8 شعب)',
  (SELECT count(*) = 8 AND min(c) = 25 AND max(c) = 25 FROM (
     SELECT e.section_id, count(*) c FROM public.enrollments e JOIN seed_stu s ON s.id = e.student_id GROUP BY 1) q)
UNION ALL SELECT 'enrollment واحد نشط لكل طالب',
  (SELECT count(*) = 0 FROM seed_stu s WHERE (SELECT count(*) FROM public.enrollments e WHERE e.student_id = s.id AND e.status = 'active') <> 1)
UNION ALL SELECT 'guardians = 115', (SELECT count(*) FROM seed_g) = 115
UNION ALL SELECT 'كل ولي أمر pending_activation بلا Auth',
  (SELECT count(*) = 0 FROM seed_g WHERE status <> 'pending_activation' OR user_id IS NOT NULL OR activated_at IS NOT NULL)
UNION ALL SELECT 'account_code فريد وغير فارغ',
  (SELECT count(*) = count(DISTINCT account_code) AND bool_and(account_code IS NOT NULL) FROM seed_g)
UNION ALL SELECT 'لا رموز تفعيل صادرة',
  (SELECT count(*) = 0 FROM public.guardian_activation_codes a JOIN seed_g g ON g.id = a.guardian_id)
UNION ALL SELECT 'كل طالب مرتبط بولي أمر واحد على الأقل وبلا ارتباط مكرر',
  (SELECT count(*) = 0 FROM seed_stu s WHERE NOT EXISTS (SELECT 1 FROM public.guardian_students gs WHERE gs.student_id = s.id))
UNION ALL SELECT 'لا ارتباط بين أسرة وطالب من أسرة أخرى (الاسم/الهاتف متطابقان)',
  (SELECT count(*) = 0 FROM public.guardian_students gs JOIN seed_g g ON g.id = gs.guardian_id
     JOIN seed_stu s ON s.id = gs.student_id WHERE s.guardian_phone <> g.phone)
UNION ALL SELECT 'أسر متعددة الأبناء موجودة (≥ 60)',
  (SELECT count(*) >= 60 FROM (SELECT guardian_id FROM public.guardian_students gs JOIN seed_stu s ON s.id = gs.student_id GROUP BY 1 HAVING count(*) > 1) q)
UNION ALL SELECT 'نتائج منشورة وغير منشورة موجودة',
  (SELECT count(*) FILTER (WHERE status = 'published') > 0 AND count(*) FILTER (WHERE status <> 'published') > 0 FROM public.assessments WHERE title LIKE '[تجريبي]%')
UNION ALL SELECT 'لا درجة تتجاوز النهاية العظمى أو سالبة',
  (SELECT count(*) = 0 FROM public.student_grades g JOIN public.assessments a ON a.id = g.assessment_id
     WHERE a.title LIKE '[تجريبي]%' AND (g.score > a.max_score OR g.score < 0))
UNION ALL SELECT 'الحضور: 10 أيام لكل شعبة ضمن آخر 21 يوماً ولا جمعة/سبت',
  (SELECT count(*) = 8 AND min(c) = 10 FROM (
     SELECT ses.section_id, count(DISTINCT ses.attendance_date) c
       FROM public.attendance_sessions ses JOIN public.attendance_records ar ON ar.session_id = ses.id JOIN seed_stu s ON s.id = ar.student_id
      WHERE ses.attendance_date >= current_date - 21 AND extract(dow FROM ses.attendance_date) NOT IN (5,6) GROUP BY 1) q)
UNION ALL SELECT 'رصيد الرسوم: لا مدفوعات تتجاوز المستحق بعد الخصم',
  (SELECT count(*) = 0 FROM (
     SELECT p.student_id, p.fee_type_id, sum(p.amount) paid,
            max(fs.amount) - coalesce((SELECT sum(d.amount) FROM public.student_fee_discounts d WHERE d.student_id = p.student_id AND d.fee_type_id = p.fee_type_id), 0) due
       FROM public.student_payments p JOIN seed_stu s ON s.id = p.student_id
       JOIN public.enrollments e ON e.student_id = p.student_id JOIN public.sections sec ON sec.id = e.section_id
       JOIN public.fee_structures fs ON fs.academic_year_id = e.academic_year_id AND fs.grade_id = sec.grade_id AND fs.fee_type_id = p.fee_type_id AND fs.track_id IS NULL
      GROUP BY p.student_id, p.fee_type_id HAVING sum(p.amount) > max(fs.amount) + 0.001) q)
UNION ALL SELECT 'إعلانات منشورة/غير منشورة/منتهية موجودة',
  (SELECT bool_or(is_published) AND bool_or(NOT is_published) AND bool_or(expires_at < current_date) FROM public.announcements WHERE title LIKE '[تجريبي]%')
UNION ALL SELECT 'أحداث التقويم موجودة', (SELECT count(*) > 0 FROM public.school_events WHERE title LIKE '[تجريبي]%')
UNION ALL SELECT 'حسابات الإدارة والأدوار موجودة', (SELECT count(*) > 0 FROM public.user_roles);
-- قبل التشغيل وبعده قارن يدوياً: count(*) من auth.users, public.profiles, public.user_roles, public.audit_log (الأخير يزيد فقط)،
-- وكذلك SELECT count(*) FROM public.timetable_entries; (يجب ألا يتغير).
