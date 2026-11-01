-- ==============================================================================
-- SEED_200_COMPREHENSIVE_STUDENTS.sql
-- مجموعة بيانات اختبار اصطناعية واقعية لنحو 210 طالب عبر المراحل الأربع:
-- (الروضة، الابتدائي، الأساس/المتوسط، الثانوي)
-- تم توليدها استجابة لمتطلبات وتوجيهات صفحة Notion: فحص
-- تتضمن: أسر متعددة الأبناء، قيود سنوية، رسوم، خصومات، مدفوعات، حضور، ودرجات
-- ومصممة بأمان: قابلة للتنظيف العكسي دون مساس بهيكل المخطط أو سجل التدقيق.
-- ==============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. التنظيف العكسي الآمن لبيانات الاختبار السابقة فقط (Safe Reverse Cleanup)
-- -----------------------------------------------------------------------------
DELETE FROM public.student_payment_allocations WHERE payment_id IN (
  SELECT id FROM public.student_payments WHERE receipt_number LIKE 'REC-TEST-%'
);
DELETE FROM public.student_payments WHERE receipt_number LIKE 'REC-TEST-%';
DELETE FROM public.student_fee_discounts WHERE reason LIKE '[SEED-200]%';
DELETE FROM public.attendance_records WHERE session_id IN (
  SELECT id FROM public.attendance_sessions WHERE attendance_date >= '2026-10-01' AND attendance_date <= '2026-10-31'
);
DELETE FROM public.student_grades WHERE assessment_id IN (
  SELECT id FROM public.assessments WHERE title LIKE '[SEED]%'
);
DELETE FROM public.assessments WHERE title LIKE '[SEED]%';
DELETE FROM public.guardian_students WHERE guardian_id IN (
  SELECT id FROM public.guardians WHERE account_code LIKE 'PAR-TEST-%'
);
DELETE FROM public.enrollments WHERE student_id IN (
  SELECT id FROM public.students WHERE student_number LIKE 'STD-TEST-%'
);
DELETE FROM public.students WHERE student_number LIKE 'STD-TEST-%';
DELETE FROM public.guardians WHERE account_code LIKE 'PAR-TEST-%';

-- -----------------------------------------------------------------------------
-- 2. إنشاء أولياء الأمور (110 أولياء أمور بحسابات متنوعة وأرقام حساب مستقلة)
-- -----------------------------------------------------------------------------
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000001', id, 'أ. مجذوب أحمد إبراهيم', '+2499120001', 'PAR-TEST-001', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000002', id, 'أ. أحمد عبد الله المهدي', '+2499120002', 'PAR-TEST-002', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000003', id, 'أ. عمر جاد الله عبد القادر', '+2499120003', 'PAR-TEST-003', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000004', id, 'أ. يوسف عبد العزيز إبراهيم', '+2499120004', 'PAR-TEST-004', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000005', id, 'أ. فيصل الفاضل الفادني', '+2499120005', 'PAR-TEST-005', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000006', id, 'أ. إبراهيم مصطفى الجاغريو', '+2499120006', 'PAR-TEST-006', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000007', id, 'أ. معاوية سليمان البشير', '+2499120007', 'PAR-TEST-007', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000008', id, 'أ. أحمد عبد الله عبد الله', '+2499120008', 'PAR-TEST-008', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000009', id, 'أ. البدوي الشريف عبد القادر', '+2499120009', 'PAR-TEST-009', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000010', id, 'أ. النذير عبد المنعم الجعلي', '+2499120010', 'PAR-TEST-010', 'active', '449210' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000011', id, 'أ. أحمد عبد الله الفادني', '+2499120011', 'PAR-TEST-011', 'active', '100011' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000012', id, 'أ. البدوي الشريف الأنصاري', '+2499120012', 'PAR-TEST-012', 'active', '100012' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000013', id, 'أ. مجذوب أحمد الأنصاري', '+2499120013', 'PAR-TEST-013', 'active', '100013' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000014', id, 'أ. الرشيد بشير الأرباب', '+2499120014', 'PAR-TEST-014', 'active', '100014' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000015', id, 'أ. عمر جاد الله عبد الجليل', '+2499120015', 'PAR-TEST-015', 'active', '100015' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000016', id, 'أ. مدثر عبد القيوم المهدي', '+2499120016', 'PAR-TEST-016', 'active', '100016' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000017', id, 'أ. تاج الدين النور عثمان', '+2499120017', 'PAR-TEST-017', 'active', '100017' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000018', id, 'أ. إسماعيل صديق الطيب', '+2499120018', 'PAR-TEST-018', 'active', '100018' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000019', id, 'أ. طه التوم الأرباب', '+2499120019', 'PAR-TEST-019', 'active', '100019' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000020', id, 'أ. محمد الهادي المهدي', '+2499120020', 'PAR-TEST-020', 'active', '100020' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000021', id, 'أ. يوسف عبد العزيز فضل الله', '+2499120021', 'PAR-TEST-021', 'active', '100021' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000022', id, 'أ. إسماعيل صديق الشريف', '+2499120022', 'PAR-TEST-022', 'active', '100022' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000023', id, 'أ. خالد حسن عبد الله', '+2499120023', 'PAR-TEST-023', 'active', '100023' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000024', id, 'أ. صالح إدريس إبراهيم', '+2499120024', 'PAR-TEST-024', 'active', '100024' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000025', id, 'أ. عبد الرحيم بابكر جاد الرب', '+2499120025', 'PAR-TEST-025', 'active', '100025' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000026', id, 'أ. حاتم السر المهدي', '+2499120026', 'PAR-TEST-026', 'active', '100026' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000027', id, 'أ. تاج الدين النور البشير', '+2499120027', 'PAR-TEST-027', 'active', '100027' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000028', id, 'أ. موسى النعيم عبد الجليل', '+2499120028', 'PAR-TEST-028', 'active', '100028' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000029', id, 'أ. الرشيد بشير إبراهيم', '+2499120029', 'PAR-TEST-029', 'active', '100029' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000030', id, 'أ. عوض الكريم سالم القرشي', '+2499120030', 'PAR-TEST-030', 'active', '100030' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000031', id, 'أ. إبراهيم مصطفى الفادني', '+2499120031', 'PAR-TEST-031', 'active', '100031' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000032', id, 'أ. الفكي كباشي الشايقي', '+2499120032', 'PAR-TEST-032', 'active', '100032' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000033', id, 'أ. حاتم السر جاد الرب', '+2499120033', 'PAR-TEST-033', 'active', '100033' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000034', id, 'أ. مدثر عبد القيوم فضل الله', '+2499120034', 'PAR-TEST-034', 'active', '100034' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000035', id, 'أ. طه التوم عبد الله', '+2499120035', 'PAR-TEST-035', 'active', '100035' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000036', id, 'أ. علي عثمان البطحاني', '+2499120036', 'PAR-TEST-036', 'active', '100036' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000037', id, 'أ. عمر جاد الله المبارك', '+2499120037', 'PAR-TEST-037', 'active', '100037' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000038', id, 'أ. إبراهيم مصطفى عبد القادر', '+2499120038', 'PAR-TEST-038', 'active', '100038' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000039', id, 'أ. بشير الفكي إبراهيم', '+2499120039', 'PAR-TEST-039', 'active', '100039' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000040', id, 'أ. صالح إدريس المهدي', '+2499120040', 'PAR-TEST-040', 'active', '100040' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000041', id, 'أ. عباس الزبير الشايقي', '+2499120041', 'PAR-TEST-041', 'active', '100041' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000042', id, 'أ. عبد الخالق حسن جاد الرب', '+2499120042', 'PAR-TEST-042', 'active', '100042' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000043', id, 'أ. الصادق التاج جاد الرب', '+2499120043', 'PAR-TEST-043', 'active', '100043' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000044', id, 'أ. عبد الرحيم بابكر فضل الله', '+2499120044', 'PAR-TEST-044', 'active', '100044' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000045', id, 'أ. فيصل الفاضل المهدي', '+2499120045', 'PAR-TEST-045', 'active', '100045' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000046', id, 'أ. طه التوم البطحاني', '+2499120046', 'PAR-TEST-046', 'active', '100046' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000047', id, 'أ. مجذوب أحمد عبد الله', '+2499120047', 'PAR-TEST-047', 'active', '100047' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000048', id, 'أ. حاتم السر الشايقي', '+2499120048', 'PAR-TEST-048', 'active', '100048' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000049', id, 'أ. الصادق التاج الفادني', '+2499120049', 'PAR-TEST-049', 'active', '100049' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000050', id, 'أ. موسى النعيم عبد القادر', '+2499120050', 'PAR-TEST-050', 'active', '100050' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000051', id, 'أ. الصادق التاج عبد الجليل', '+2499120051', 'PAR-TEST-051', 'active', '100051' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000052', id, 'أ. صالح إدريس المهدي', '+2499120052', 'PAR-TEST-052', 'active', '100052' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000053', id, 'أ. عوض الكريم سالم الشايقي', '+2499120053', 'PAR-TEST-053', 'active', '100053' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000054', id, 'أ. طه التوم الفادني', '+2499120054', 'PAR-TEST-054', 'active', '100054' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000055', id, 'أ. عمر جاد الله البطحاني', '+2499120055', 'PAR-TEST-055', 'active', '100055' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000056', id, 'أ. محمد الهادي البشير', '+2499120056', 'PAR-TEST-056', 'active', '100056' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000057', id, 'أ. عمر جاد الله البشير', '+2499120057', 'PAR-TEST-057', 'active', '100057' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000058', id, 'أ. تاج الدين النور الشريف', '+2499120058', 'PAR-TEST-058', 'active', '100058' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000059', id, 'أ. صالح إدريس المهدي', '+2499120059', 'PAR-TEST-059', 'active', '100059' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000060', id, 'أ. إبراهيم مصطفى فضل الله', '+2499120060', 'PAR-TEST-060', 'active', '100060' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000061', id, 'أ. عوض الكريم سالم الجاغريو', '+2499120061', 'PAR-TEST-061', 'active', '100061' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000062', id, 'أ. صلاح الدين علي الأنصاري', '+2499120062', 'PAR-TEST-062', 'active', '100062' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000063', id, 'أ. محمد الهادي فضل الله', '+2499120063', 'PAR-TEST-063', 'active', '100063' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000064', id, 'أ. مجذوب أحمد المامور', '+2499120064', 'PAR-TEST-064', 'active', '100064' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000065', id, 'أ. صالح إدريس الشايقي', '+2499120065', 'PAR-TEST-065', 'active', '100065' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000066', id, 'أ. عباس الزبير الصديق', '+2499120066', 'PAR-TEST-066', 'active', '100066' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000067', id, 'أ. المهدي النور الصديق', '+2499120067', 'PAR-TEST-067', 'active', '100067' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000068', id, 'أ. عمر جاد الله الفادني', '+2499120068', 'PAR-TEST-068', 'active', '100068' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000069', id, 'أ. الرشيد بشير المهدي', '+2499120069', 'PAR-TEST-069', 'active', '100069' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000070', id, 'أ. موسى النعيم الجاغريو', '+2499120070', 'PAR-TEST-070', 'active', '100070' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000071', id, 'أ. معاوية سليمان الجاغريو', '+2499120071', 'PAR-TEST-071', 'active', '100071' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000072', id, 'أ. صالح إدريس جاد الرب', '+2499120072', 'PAR-TEST-072', 'active', '100072' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000073', id, 'أ. عمر جاد الله الصديق', '+2499120073', 'PAR-TEST-073', 'active', '100073' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000074', id, 'أ. النذير عبد المنعم المامور', '+2499120074', 'PAR-TEST-074', 'active', '100074' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000075', id, 'أ. إبراهيم مصطفى البشير', '+2499120075', 'PAR-TEST-075', 'active', '100075' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000076', id, 'أ. بشير الفكي إبراهيم', '+2499120076', 'PAR-TEST-076', 'active', '100076' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000077', id, 'أ. يوسف عبد العزيز الشايقي', '+2499120077', 'PAR-TEST-077', 'active', '100077' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000078', id, 'أ. الصادق التاج البطحاني', '+2499120078', 'PAR-TEST-078', 'active', '100078' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000079', id, 'أ. معاوية سليمان الجعلي', '+2499120079', 'PAR-TEST-079', 'active', '100079' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000080', id, 'أ. إبراهيم مصطفى القرشي', '+2499120080', 'PAR-TEST-080', 'active', '100080' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000081', id, 'أ. صالح إدريس الجعلي', '+2499120081', 'PAR-TEST-081', 'active', '100081' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000082', id, 'أ. عباس الزبير المكي', '+2499120082', 'PAR-TEST-082', 'active', '100082' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000083', id, 'أ. المهدي النور الفادني', '+2499120083', 'PAR-TEST-083', 'active', '100083' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000084', id, 'أ. بشير الفكي عثمان', '+2499120084', 'PAR-TEST-084', 'active', '100084' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000085', id, 'أ. فيصل الفاضل إبراهيم', '+2499120085', 'PAR-TEST-085', 'active', '100085' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000086', id, 'أ. فيصل الفاضل الفادني', '+2499120086', 'PAR-TEST-086', 'active', '100086' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000087', id, 'أ. إسماعيل صديق المهدي', '+2499120087', 'PAR-TEST-087', 'active', '100087' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000088', id, 'أ. إسماعيل صديق الشايقي', '+2499120088', 'PAR-TEST-088', 'active', '100088' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000089', id, 'أ. محمد الهادي إبراهيم', '+2499120089', 'PAR-TEST-089', 'active', '100089' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000090', id, 'أ. الفكي كباشي الأرباب', '+2499120090', 'PAR-TEST-090', 'active', '100090' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000091', id, 'أ. الصادق التاج عبد الجليل', '+2499120091', 'PAR-TEST-091', 'pending_activation', '100091' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000092', id, 'أ. أحمد عبد الله المهدي', '+2499120092', 'PAR-TEST-092', 'pending_activation', '100092' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000093', id, 'أ. النذير عبد المنعم الطيب', '+2499120093', 'PAR-TEST-093', 'pending_activation', '100093' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000094', id, 'أ. النذير عبد المنعم إبراهيم', '+2499120094', 'PAR-TEST-094', 'pending_activation', '100094' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000095', id, 'أ. بشير الفكي الشايقي', '+2499120095', 'PAR-TEST-095', 'pending_activation', '100095' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000096', id, 'أ. الفكي كباشي الشايقي', '+2499120096', 'PAR-TEST-096', 'pending_activation', '100096' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000097', id, 'أ. النذير عبد المنعم الجعلي', '+2499120097', 'PAR-TEST-097', 'pending_activation', '100097' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000098', id, 'أ. البدوي الشريف الصديق', '+2499120098', 'PAR-TEST-098', 'pending_activation', '100098' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000099', id, 'أ. عبد الرحيم بابكر الطيب', '+2499120099', 'PAR-TEST-099', 'pending_activation', '100099' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000100', id, 'أ. الرشيد بشير المكي', '+2499120100', 'PAR-TEST-100', 'pending_activation', '100100' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000101', id, 'أ. عوض الكريم سالم عثمان', '+2499120101', 'PAR-TEST-101', 'pending_activation', '100101' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000102', id, 'أ. حاتم السر الشريف', '+2499120102', 'PAR-TEST-102', 'pending_activation', '100102' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000103', id, 'أ. جمال تاج السر عثمان', '+2499120103', 'PAR-TEST-103', 'suspended', '100103' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000104', id, 'أ. خالد حسن جاد الرب', '+2499120104', 'PAR-TEST-104', 'suspended', '100104' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000105', id, 'أ. صلاح الدين علي المبارك', '+2499120105', 'PAR-TEST-105', 'suspended', '100105' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000106', id, 'أ. عمر جاد الله البشير', '+2499120106', 'PAR-TEST-106', 'suspended', '100106' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000107', id, 'أ. عمر جاد الله الجاغريو', '+2499120107', 'PAR-TEST-107', 'suspended', '100107' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000108', id, 'أ. إبراهيم مصطفى عبد الله', '+2499120108', 'PAR-TEST-108', 'suspended', '100108' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000109', id, 'أ. موسى النعيم المامور', '+2499120109', 'PAR-TEST-109', 'suspended', '100109' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;
INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) SELECT 'c0000000-0000-0000-0000-000000000110', id, 'أ. عبد الخالق حسن عبد الله', '+2499120110', 'PAR-TEST-110', 'suspended', '100110' FROM public.schools LIMIT 1 ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 3. إنشاء الصفوف الدراسية والشعب لكافة المراحل الأربع إن لم تكن موجودة
-- -----------------------------------------------------------------------------

DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'المستوى الأول روضة (KG1)';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'المستوى الأول روضة (KG1)', 1)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 80000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'المستوى الثاني روضة (KG2)';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'المستوى الثاني روضة (KG2)', 2)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 80000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الأول الابتدائي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الأول الابتدائي', 3)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 100000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الثاني الابتدائي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الثاني الابتدائي', 4)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 100000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الثالث الابتدائي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الثالث الابتدائي', 5)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 100000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الرابع الابتدائي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الرابع الابتدائي', 6)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 110000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الخامس الابتدائي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الخامس الابتدائي', 7)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 110000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف السادس الابتدائي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف السادس الابتدائي', 8)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 120000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الأول المتوسط';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الأول المتوسط', 9)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 130000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الثاني المتوسط';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الثاني المتوسط', 10)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 130000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الثالث المتوسط';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الثالث المتوسط', 11)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 135000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الأول الثانوي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الأول الثانوي', 12)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 150000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الثاني الثانوي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الثاني الثانوي', 13)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 150000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_grade_id uuid;
  v_sec_a uuid;
  v_sec_b uuid;
  v_fee_type_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- الصف الدراسي
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = 'الصف الثالث الثانوي';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, 'الصف الثالث الثانوي', 14)
    RETURNING id INTO v_grade_id;
  END IF;

  -- الشعب (أ) و (ب)
  SELECT id INTO v_sec_a FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (أ)';
  IF v_sec_a IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (أ)', 40);
  END IF;

  SELECT id INTO v_sec_b FROM public.sections WHERE academic_year_id = v_year_id AND grade_id = v_grade_id AND name = 'شعبة (ب)';
  IF v_sec_b IS NULL THEN
    INSERT INTO public.sections (id, academic_year_id, grade_id, name, capacity)
    VALUES (gen_random_uuid(), v_year_id, v_grade_id, 'شعبة (ب)', 40);
  END IF;

  -- نوع وهيكل الرسوم
  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;
  IF v_fee_type_id IS NULL THEN
    INSERT INTO public.fee_types (id, school_id, name)
    VALUES (gen_random_uuid(), v_school_id, 'الرسوم الدراسية السنوية')
    RETURNING id INTO v_fee_type_id;
  END IF;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, description)
  VALUES (v_year_id, v_grade_id, v_fee_type_id, 160000, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;

-- -----------------------------------------------------------------------------
-- 4. إنشاء الطلاب وقيدهم وتوزيعهم وربطهم بأولياء الأمور (~210 طالب)
-- -----------------------------------------------------------------------------

DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000001', v_school_id, 'STD-TEST-0001', 'نزار أحمد عبد الله المهدي', 'male', '2022-02-02', 'أ. أحمد عبد الله المهدي', '+2499120002', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000001', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000002', v_school_id, 'STD-TEST-0002', 'إيثار عمر جاد الله عبد القادر', 'female', '2022-03-03', 'أ. عمر جاد الله عبد القادر', '+2499120003', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000002', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000003', v_school_id, 'STD-TEST-0003', 'عبد الله يوسف عبد العزيز إبراهيم', 'male', '2022-04-04', 'أ. يوسف عبد العزيز إبراهيم', '+2499120004', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000003', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000004', v_school_id, 'STD-TEST-0004', 'لمياء فيصل الفاضل الفادني', 'female', '2022-05-05', 'أ. فيصل الفاضل الفادني', '+2499120005', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000004', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000004', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000005', v_school_id, 'STD-TEST-0005', 'معاوية إبراهيم مصطفى الجاغريو', 'male', '2022-06-06', 'أ. إبراهيم مصطفى الجاغريو', '+2499120006', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000005', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000005', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000006', v_school_id, 'STD-TEST-0006', 'منى معاوية سليمان البشير', 'female', '2022-07-07', 'أ. معاوية سليمان البشير', '+2499120007', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000006', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000006', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000007', v_school_id, 'STD-TEST-0007', 'حمزة أحمد عبد الله عبد الله', 'male', '2022-08-08', 'أ. أحمد عبد الله عبد الله', '+2499120008', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000007', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000007', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000008', v_school_id, 'STD-TEST-0008', 'وفاء البدوي الشريف عبد القادر', 'female', '2022-09-09', 'أ. البدوي الشريف عبد القادر', '+2499120009', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000008', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000008', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000009', v_school_id, 'STD-TEST-0009', 'سيف النذير عبد المنعم الجعلي', 'male', '2022-10-10', 'أ. النذير عبد المنعم الجعلي', '+2499120010', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000009', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000009', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000010', v_school_id, 'STD-TEST-0010', 'ريان أحمد عبد الله الفادني', 'female', '2022-11-11', 'أ. أحمد عبد الله الفادني', '+2499120011', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000010', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000010', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000011', v_school_id, 'STD-TEST-0011', 'مازن البدوي الشريف الأنصاري', 'male', '2022-12-12', 'أ. البدوي الشريف الأنصاري', '+2499120012', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000011', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000011', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000012', v_school_id, 'STD-TEST-0012', 'صفاء مجذوب أحمد الأنصاري', 'female', '2022-01-13', 'أ. مجذوب أحمد الأنصاري', '+2499120013', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000013', 'a0000000-0000-0000-0000-000000000012', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000012', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000013', v_school_id, 'STD-TEST-0013', 'طارق الرشيد بشير الأرباب', 'male', '2022-02-14', 'أ. الرشيد بشير الأرباب', '+2499120014', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000014', 'a0000000-0000-0000-0000-000000000013', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000013', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000014', v_school_id, 'STD-TEST-0014', 'أميرة عمر جاد الله عبد الجليل', 'female', '2022-03-15', 'أ. عمر جاد الله عبد الجليل', '+2499120015', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000015', 'a0000000-0000-0000-0000-000000000014', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000014', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الأول روضة (KG1)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000015', v_school_id, 'STD-TEST-0015', 'معاذ مدثر عبد القيوم المهدي', 'male', '2022-04-16', 'أ. مدثر عبد القيوم المهدي', '+2499120016', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000016', 'a0000000-0000-0000-0000-000000000015', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000015', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000016', v_school_id, 'STD-TEST-0016', 'مها تاج الدين النور عثمان', 'female', '2021-05-17', 'أ. تاج الدين النور عثمان', '+2499120017', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000017', 'a0000000-0000-0000-0000-000000000016', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000016', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000017', v_school_id, 'STD-TEST-0017', 'أيمن إسماعيل صديق الطيب', 'male', '2021-06-18', 'أ. إسماعيل صديق الطيب', '+2499120018', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000018', 'a0000000-0000-0000-0000-000000000017', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000017', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000018', v_school_id, 'STD-TEST-0018', 'وفاء طه التوم الأرباب', 'female', '2021-07-19', 'أ. طه التوم الأرباب', '+2499120019', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000019', 'a0000000-0000-0000-0000-000000000018', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000018', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000019', v_school_id, 'STD-TEST-0019', 'أيمن محمد الهادي المهدي', 'male', '2021-08-20', 'أ. محمد الهادي المهدي', '+2499120020', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000020', 'a0000000-0000-0000-0000-000000000019', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000019', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000020', v_school_id, 'STD-TEST-0020', 'سارة يوسف عبد العزيز فضل الله', 'female', '2021-09-21', 'أ. يوسف عبد العزيز فضل الله', '+2499120021', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000020', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000020', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000021', v_school_id, 'STD-TEST-0021', 'بلال إسماعيل صديق الشريف', 'male', '2021-10-22', 'أ. إسماعيل صديق الشريف', '+2499120022', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000022', 'a0000000-0000-0000-0000-000000000021', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000021', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000022', v_school_id, 'STD-TEST-0022', 'سلمى خالد حسن عبد الله', 'female', '2021-11-23', 'أ. خالد حسن عبد الله', '+2499120023', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000023', 'a0000000-0000-0000-0000-000000000022', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000022', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000023', v_school_id, 'STD-TEST-0023', 'عثمان صالح إدريس إبراهيم', 'male', '2021-12-24', 'أ. صالح إدريس إبراهيم', '+2499120024', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000024', 'a0000000-0000-0000-0000-000000000023', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000023', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000024', v_school_id, 'STD-TEST-0024', 'سحر عبد الرحيم بابكر جاد الرب', 'female', '2021-01-25', 'أ. عبد الرحيم بابكر جاد الرب', '+2499120025', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000025', 'a0000000-0000-0000-0000-000000000024', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000024', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000025', v_school_id, 'STD-TEST-0025', 'أحمد حاتم السر المهدي', 'male', '2021-02-26', 'أ. حاتم السر المهدي', '+2499120026', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000026', 'a0000000-0000-0000-0000-000000000025', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000025', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000026', v_school_id, 'STD-TEST-0026', 'عبير تاج الدين النور البشير', 'female', '2021-03-27', 'أ. تاج الدين النور البشير', '+2499120027', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000027', 'a0000000-0000-0000-0000-000000000026', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000026', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000027', v_school_id, 'STD-TEST-0027', 'معاوية موسى النعيم عبد الجليل', 'male', '2021-04-01', 'أ. موسى النعيم عبد الجليل', '+2499120028', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000028', 'a0000000-0000-0000-0000-000000000027', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000027', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000028', v_school_id, 'STD-TEST-0028', 'سلمى الرشيد بشير إبراهيم', 'female', '2021-05-02', 'أ. الرشيد بشير إبراهيم', '+2499120029', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000029', 'a0000000-0000-0000-0000-000000000028', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000028', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000029', v_school_id, 'STD-TEST-0029', 'أمين عوض الكريم سالم القرشي', 'male', '2021-06-03', 'أ. عوض الكريم سالم القرشي', '+2499120030', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000030', 'a0000000-0000-0000-0000-000000000029', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000029', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'المستوى الثاني روضة (KG2)' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000030', v_school_id, 'STD-TEST-0030', 'سلمى مجذوب أحمد إبراهيم', 'female', '2021-07-04', 'أ. مجذوب أحمد إبراهيم', '+2499120001', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000030', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000030', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000031', v_school_id, 'STD-TEST-0031', 'محمد أحمد عبد الله المهدي', 'male', '2020-08-05', 'أ. أحمد عبد الله المهدي', '+2499120002', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000031', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000031', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000032', v_school_id, 'STD-TEST-0032', 'هدى عمر جاد الله عبد القادر', 'female', '2020-09-06', 'أ. عمر جاد الله عبد القادر', '+2499120003', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000032', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000032', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000033', v_school_id, 'STD-TEST-0033', 'علي يوسف عبد العزيز إبراهيم', 'male', '2020-10-07', 'أ. يوسف عبد العزيز إبراهيم', '+2499120004', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000033', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000033', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000034', v_school_id, 'STD-TEST-0034', 'سلمى فيصل الفاضل الفادني', 'female', '2020-11-08', 'أ. فيصل الفاضل الفادني', '+2499120005', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000034', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000034', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000035', v_school_id, 'STD-TEST-0035', 'عثمان إبراهيم مصطفى الجاغريو', 'male', '2020-12-09', 'أ. إبراهيم مصطفى الجاغريو', '+2499120006', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000035', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000035', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000036', v_school_id, 'STD-TEST-0036', 'مريم معاوية سليمان البشير', 'female', '2020-01-10', 'أ. معاوية سليمان البشير', '+2499120007', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000036', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000036', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000037', v_school_id, 'STD-TEST-0037', 'سامي أحمد عبد الله عبد الله', 'male', '2020-02-11', 'أ. أحمد عبد الله عبد الله', '+2499120008', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000037', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000037', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000038', v_school_id, 'STD-TEST-0038', 'هدى البدوي الشريف عبد القادر', 'female', '2020-03-12', 'أ. البدوي الشريف عبد القادر', '+2499120009', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000038', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000038', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000039', v_school_id, 'STD-TEST-0039', 'الصادق النذير عبد المنعم الجعلي', 'male', '2020-04-13', 'أ. النذير عبد المنعم الجعلي', '+2499120010', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000039', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000039', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000040', v_school_id, 'STD-TEST-0040', 'دعاء أحمد عبد الله الفادني', 'female', '2020-05-14', 'أ. أحمد عبد الله الفادني', '+2499120011', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000040', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000040', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000041', v_school_id, 'STD-TEST-0041', 'أنس البدوي الشريف الأنصاري', 'male', '2020-06-15', 'أ. البدوي الشريف الأنصاري', '+2499120012', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000041', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000041', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000042', v_school_id, 'STD-TEST-0042', 'نسرين مجذوب أحمد الأنصاري', 'female', '2020-07-16', 'أ. مجذوب أحمد الأنصاري', '+2499120013', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000013', 'a0000000-0000-0000-0000-000000000042', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000042', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000043', v_school_id, 'STD-TEST-0043', 'مازن الرشيد بشير الأرباب', 'male', '2020-08-17', 'أ. الرشيد بشير الأرباب', '+2499120014', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000014', 'a0000000-0000-0000-0000-000000000043', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000043', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000044', v_school_id, 'STD-TEST-0044', 'صفاء عمر جاد الله عبد الجليل', 'female', '2020-09-18', 'أ. عمر جاد الله عبد الجليل', '+2499120015', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000015', 'a0000000-0000-0000-0000-000000000044', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000044', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000045', v_school_id, 'STD-TEST-0045', 'عبد الله مدثر عبد القيوم المهدي', 'male', '2019-10-19', 'أ. مدثر عبد القيوم المهدي', '+2499120016', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000016', 'a0000000-0000-0000-0000-000000000045', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000045', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000046', v_school_id, 'STD-TEST-0046', 'حنين تاج الدين النور عثمان', 'female', '2019-11-20', 'أ. تاج الدين النور عثمان', '+2499120017', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000017', 'a0000000-0000-0000-0000-000000000046', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000046', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000047', v_school_id, 'STD-TEST-0047', 'نادر إسماعيل صديق الطيب', 'male', '2019-12-21', 'أ. إسماعيل صديق الطيب', '+2499120018', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000018', 'a0000000-0000-0000-0000-000000000047', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000047', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000048', v_school_id, 'STD-TEST-0048', 'لمياء طه التوم الأرباب', 'female', '2019-01-22', 'أ. طه التوم الأرباب', '+2499120019', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000019', 'a0000000-0000-0000-0000-000000000048', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000048', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000049', v_school_id, 'STD-TEST-0049', 'بلال محمد الهادي المهدي', 'male', '2019-02-23', 'أ. محمد الهادي المهدي', '+2499120020', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000020', 'a0000000-0000-0000-0000-000000000049', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000049', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000050', v_school_id, 'STD-TEST-0050', 'لمياء يوسف عبد العزيز فضل الله', 'female', '2019-03-24', 'أ. يوسف عبد العزيز فضل الله', '+2499120021', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000050', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000050', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000051', v_school_id, 'STD-TEST-0051', 'أسامة إسماعيل صديق الشريف', 'male', '2019-04-25', 'أ. إسماعيل صديق الشريف', '+2499120022', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000022', 'a0000000-0000-0000-0000-000000000051', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000051', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000052', v_school_id, 'STD-TEST-0052', 'رؤى خالد حسن عبد الله', 'female', '2019-05-26', 'أ. خالد حسن عبد الله', '+2499120023', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000023', 'a0000000-0000-0000-0000-000000000052', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000052', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000053', v_school_id, 'STD-TEST-0053', 'يوسف صالح إدريس إبراهيم', 'male', '2019-06-27', 'أ. صالح إدريس إبراهيم', '+2499120024', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000024', 'a0000000-0000-0000-0000-000000000053', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000053', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000054', v_school_id, 'STD-TEST-0054', 'آلاء عبد الرحيم بابكر جاد الرب', 'female', '2019-07-01', 'أ. عبد الرحيم بابكر جاد الرب', '+2499120025', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000025', 'a0000000-0000-0000-0000-000000000054', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000054', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000055', v_school_id, 'STD-TEST-0055', 'حاتم حاتم السر المهدي', 'male', '2019-08-02', 'أ. حاتم السر المهدي', '+2499120026', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000026', 'a0000000-0000-0000-0000-000000000055', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000055', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000056', v_school_id, 'STD-TEST-0056', 'نجلاء تاج الدين النور البشير', 'female', '2019-09-03', 'أ. تاج الدين النور البشير', '+2499120027', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000027', 'a0000000-0000-0000-0000-000000000056', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000056', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000057', v_school_id, 'STD-TEST-0057', 'حاتم موسى النعيم عبد الجليل', 'male', '2019-10-04', 'أ. موسى النعيم عبد الجليل', '+2499120028', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000028', 'a0000000-0000-0000-0000-000000000057', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000057', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000058', v_school_id, 'STD-TEST-0058', 'أماني الرشيد بشير إبراهيم', 'female', '2019-11-05', 'أ. الرشيد بشير إبراهيم', '+2499120029', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000029', 'a0000000-0000-0000-0000-000000000058', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000058', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000059', v_school_id, 'STD-TEST-0059', 'عمار عوض الكريم سالم القرشي', 'male', '2018-12-06', 'أ. عوض الكريم سالم القرشي', '+2499120030', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000030', 'a0000000-0000-0000-0000-000000000059', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000059', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000060', v_school_id, 'STD-TEST-0060', 'زينب مجذوب أحمد إبراهيم', 'female', '2018-01-07', 'أ. مجذوب أحمد إبراهيم', '+2499120001', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000060', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000060', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000061', v_school_id, 'STD-TEST-0061', 'يوسف صلاح الدين علي الأنصاري', 'male', '2018-02-08', 'أ. صلاح الدين علي الأنصاري', '+2499120062', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000062', 'a0000000-0000-0000-0000-000000000061', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000061', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000062', v_school_id, 'STD-TEST-0062', 'زينب محمد الهادي فضل الله', 'female', '2018-03-09', 'أ. محمد الهادي فضل الله', '+2499120063', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000063', 'a0000000-0000-0000-0000-000000000062', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000062', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000063', v_school_id, 'STD-TEST-0063', 'معاذ مجذوب أحمد المامور', 'male', '2018-04-10', 'أ. مجذوب أحمد المامور', '+2499120064', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000064', 'a0000000-0000-0000-0000-000000000063', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000063', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000064', v_school_id, 'STD-TEST-0064', 'سحر صالح إدريس الشايقي', 'female', '2018-05-11', 'أ. صالح إدريس الشايقي', '+2499120065', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000065', 'a0000000-0000-0000-0000-000000000064', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000064', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000065', v_school_id, 'STD-TEST-0065', 'يوسف عباس الزبير الصديق', 'male', '2018-06-12', 'أ. عباس الزبير الصديق', '+2499120066', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000066', 'a0000000-0000-0000-0000-000000000065', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000065', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000066', v_school_id, 'STD-TEST-0066', 'دعاء المهدي النور الصديق', 'female', '2018-07-13', 'أ. المهدي النور الصديق', '+2499120067', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000067', 'a0000000-0000-0000-0000-000000000066', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000066', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000067', v_school_id, 'STD-TEST-0067', 'طارق عمر جاد الله الفادني', 'male', '2018-08-14', 'أ. عمر جاد الله الفادني', '+2499120068', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000068', 'a0000000-0000-0000-0000-000000000067', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000067', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000068', v_school_id, 'STD-TEST-0068', 'رؤى الرشيد بشير المهدي', 'female', '2018-09-15', 'أ. الرشيد بشير المهدي', '+2499120069', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000069', 'a0000000-0000-0000-0000-000000000068', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000068', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000069', v_school_id, 'STD-TEST-0069', 'نزار موسى النعيم الجاغريو', 'male', '2018-10-16', 'أ. موسى النعيم الجاغريو', '+2499120070', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000070', 'a0000000-0000-0000-0000-000000000069', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000069', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000070', v_school_id, 'STD-TEST-0070', 'دانيا معاوية سليمان الجاغريو', 'female', '2018-11-17', 'أ. معاوية سليمان الجاغريو', '+2499120071', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000071', 'a0000000-0000-0000-0000-000000000070', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000070', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000071', v_school_id, 'STD-TEST-0071', 'عبد الله صالح إدريس جاد الرب', 'male', '2018-12-18', 'أ. صالح إدريس جاد الرب', '+2499120072', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000072', 'a0000000-0000-0000-0000-000000000071', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000071', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000072', v_school_id, 'STD-TEST-0072', 'ريان عمر جاد الله الصديق', 'female', '2018-01-19', 'أ. عمر جاد الله الصديق', '+2499120073', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000073', 'a0000000-0000-0000-0000-000000000072', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000072', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000073', v_school_id, 'STD-TEST-0073', 'حسن النذير عبد المنعم المامور', 'male', '2017-02-20', 'أ. النذير عبد المنعم المامور', '+2499120074', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000074', 'a0000000-0000-0000-0000-000000000073', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000073', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000074', v_school_id, 'STD-TEST-0074', 'رنا إبراهيم مصطفى البشير', 'female', '2017-03-21', 'أ. إبراهيم مصطفى البشير', '+2499120075', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000075', 'a0000000-0000-0000-0000-000000000074', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000074', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000075', v_school_id, 'STD-TEST-0075', 'عمار بشير الفكي إبراهيم', 'male', '2017-04-22', 'أ. بشير الفكي إبراهيم', '+2499120076', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000076', 'a0000000-0000-0000-0000-000000000075', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000075', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000076', v_school_id, 'STD-TEST-0076', 'دعاء يوسف عبد العزيز الشايقي', 'female', '2017-05-23', 'أ. يوسف عبد العزيز الشايقي', '+2499120077', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000077', 'a0000000-0000-0000-0000-000000000076', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000076', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000077', v_school_id, 'STD-TEST-0077', 'عثمان الصادق التاج البطحاني', 'male', '2017-06-24', 'أ. الصادق التاج البطحاني', '+2499120078', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000078', 'a0000000-0000-0000-0000-000000000077', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000077', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000078', v_school_id, 'STD-TEST-0078', 'دانيا معاوية سليمان الجعلي', 'female', '2017-07-25', 'أ. معاوية سليمان الجعلي', '+2499120079', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000079', 'a0000000-0000-0000-0000-000000000078', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000078', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000079', v_school_id, 'STD-TEST-0079', 'معاوية إبراهيم مصطفى القرشي', 'male', '2017-08-26', 'أ. إبراهيم مصطفى القرشي', '+2499120080', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000080', 'a0000000-0000-0000-0000-000000000079', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000079', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000080', v_school_id, 'STD-TEST-0080', 'آلاء صالح إدريس الجعلي', 'female', '2017-09-27', 'أ. صالح إدريس الجعلي', '+2499120081', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000081', 'a0000000-0000-0000-0000-000000000080', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000080', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000081', v_school_id, 'STD-TEST-0081', 'علي عباس الزبير المكي', 'male', '2017-10-01', 'أ. عباس الزبير المكي', '+2499120082', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000082', 'a0000000-0000-0000-0000-000000000081', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000081', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000082', v_school_id, 'STD-TEST-0082', 'صفاء المهدي النور الفادني', 'female', '2017-11-02', 'أ. المهدي النور الفادني', '+2499120083', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000083', 'a0000000-0000-0000-0000-000000000082', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000082', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000083', v_school_id, 'STD-TEST-0083', 'محمد بشير الفكي عثمان', 'male', '2017-12-03', 'أ. بشير الفكي عثمان', '+2499120084', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000084', 'a0000000-0000-0000-0000-000000000083', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000083', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000084', v_school_id, 'STD-TEST-0084', 'ريم فيصل الفاضل إبراهيم', 'female', '2017-01-04', 'أ. فيصل الفاضل إبراهيم', '+2499120085', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000085', 'a0000000-0000-0000-0000-000000000084', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000084', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000085', v_school_id, 'STD-TEST-0085', 'بلال فيصل الفاضل الفادني', 'male', '2017-02-05', 'أ. فيصل الفاضل الفادني', '+2499120086', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000086', 'a0000000-0000-0000-0000-000000000085', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000085', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الرابع الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000086', v_school_id, 'STD-TEST-0086', 'منى إسماعيل صديق المهدي', 'female', '2017-03-06', 'أ. إسماعيل صديق المهدي', '+2499120087', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000087', 'a0000000-0000-0000-0000-000000000086', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000086', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000087', v_school_id, 'STD-TEST-0087', 'أسامة إسماعيل صديق الشايقي', 'male', '2016-04-07', 'أ. إسماعيل صديق الشايقي', '+2499120088', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000088', 'a0000000-0000-0000-0000-000000000087', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000087', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000088', v_school_id, 'STD-TEST-0088', 'نسرين محمد الهادي إبراهيم', 'female', '2016-05-08', 'أ. محمد الهادي إبراهيم', '+2499120089', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000089', 'a0000000-0000-0000-0000-000000000088', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000088', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000089', v_school_id, 'STD-TEST-0089', 'محمود الفكي كباشي الأرباب', 'male', '2016-06-09', 'أ. الفكي كباشي الأرباب', '+2499120090', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000090', 'a0000000-0000-0000-0000-000000000089', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000089', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000090', v_school_id, 'STD-TEST-0090', 'شهد الصادق التاج عبد الجليل', 'female', '2016-07-10', 'أ. الصادق التاج عبد الجليل', '+2499120091', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000091', 'a0000000-0000-0000-0000-000000000090', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000090', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000091', v_school_id, 'STD-TEST-0091', 'معاذ أحمد عبد الله المهدي', 'male', '2016-08-11', 'أ. أحمد عبد الله المهدي', '+2499120092', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000092', 'a0000000-0000-0000-0000-000000000091', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000091', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000092', v_school_id, 'STD-TEST-0092', 'زينب النذير عبد المنعم الطيب', 'female', '2016-09-12', 'أ. النذير عبد المنعم الطيب', '+2499120093', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000093', 'a0000000-0000-0000-0000-000000000092', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000092', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000093', v_school_id, 'STD-TEST-0093', 'مصطفى النذير عبد المنعم إبراهيم', 'male', '2016-10-13', 'أ. النذير عبد المنعم إبراهيم', '+2499120094', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000094', 'a0000000-0000-0000-0000-000000000093', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000093', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000094', v_school_id, 'STD-TEST-0094', 'سلافة بشير الفكي الشايقي', 'female', '2016-11-14', 'أ. بشير الفكي الشايقي', '+2499120095', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000095', 'a0000000-0000-0000-0000-000000000094', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000094', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000095', v_school_id, 'STD-TEST-0095', 'محمد الفكي كباشي الشايقي', 'male', '2016-12-15', 'أ. الفكي كباشي الشايقي', '+2499120096', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000096', 'a0000000-0000-0000-0000-000000000095', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000095', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000096', v_school_id, 'STD-TEST-0096', 'سلافة النذير عبد المنعم الجعلي', 'female', '2016-01-16', 'أ. النذير عبد المنعم الجعلي', '+2499120097', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000097', 'a0000000-0000-0000-0000-000000000096', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000096', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000097', v_school_id, 'STD-TEST-0097', 'حمزة البدوي الشريف الصديق', 'male', '2016-02-17', 'أ. البدوي الشريف الصديق', '+2499120098', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000098', 'a0000000-0000-0000-0000-000000000097', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000097', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000098', v_school_id, 'STD-TEST-0098', 'إيمان عبد الرحيم بابكر الطيب', 'female', '2016-03-18', 'أ. عبد الرحيم بابكر الطيب', '+2499120099', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000099', 'a0000000-0000-0000-0000-000000000098', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000098', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000099', v_school_id, 'STD-TEST-0099', 'زياد الرشيد بشير المكي', 'male', '2016-04-19', 'أ. الرشيد بشير المكي', '+2499120100', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000100', 'a0000000-0000-0000-0000-000000000099', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000099', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الخامس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000100', v_school_id, 'STD-TEST-0100', 'ريان عوض الكريم سالم عثمان', 'female', '2016-05-20', 'أ. عوض الكريم سالم عثمان', '+2499120101', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000101', 'a0000000-0000-0000-0000-000000000100', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000100', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000101', v_school_id, 'STD-TEST-0101', 'معاوية حاتم السر الشريف', 'male', '2015-06-21', 'أ. حاتم السر الشريف', '+2499120102', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000102', 'a0000000-0000-0000-0000-000000000101', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000101', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000102', v_school_id, 'STD-TEST-0102', 'نسرين جمال تاج السر عثمان', 'female', '2015-07-22', 'أ. جمال تاج السر عثمان', '+2499120103', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000103', 'a0000000-0000-0000-0000-000000000102', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000102', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000103', v_school_id, 'STD-TEST-0103', 'عبد الرحمن خالد حسن جاد الرب', 'male', '2015-08-23', 'أ. خالد حسن جاد الرب', '+2499120104', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000104', 'a0000000-0000-0000-0000-000000000103', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000103', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000104', v_school_id, 'STD-TEST-0104', 'رؤى صلاح الدين علي المبارك', 'female', '2015-09-24', 'أ. صلاح الدين علي المبارك', '+2499120105', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000105', 'a0000000-0000-0000-0000-000000000104', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000104', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000105', v_school_id, 'STD-TEST-0105', 'زياد عمر جاد الله البشير', 'male', '2015-10-25', 'أ. عمر جاد الله البشير', '+2499120106', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000106', 'a0000000-0000-0000-0000-000000000105', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000105', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000106', v_school_id, 'STD-TEST-0106', 'شهد عمر جاد الله الجاغريو', 'female', '2015-11-26', 'أ. عمر جاد الله الجاغريو', '+2499120107', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000107', 'a0000000-0000-0000-0000-000000000106', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000106', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000107', v_school_id, 'STD-TEST-0107', 'علي إبراهيم مصطفى عبد الله', 'male', '2015-12-27', 'أ. إبراهيم مصطفى عبد الله', '+2499120108', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000108', 'a0000000-0000-0000-0000-000000000107', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000107', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000108', v_school_id, 'STD-TEST-0108', 'عبير موسى النعيم المامور', 'female', '2015-01-01', 'أ. موسى النعيم المامور', '+2499120109', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000109', 'a0000000-0000-0000-0000-000000000108', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000108', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000109', v_school_id, 'STD-TEST-0109', 'نزار عبد الخالق حسن عبد الله', 'male', '2015-02-02', 'أ. عبد الخالق حسن عبد الله', '+2499120110', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000110', 'a0000000-0000-0000-0000-000000000109', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000109', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000110', v_school_id, 'STD-TEST-0110', 'زينب مجذوب أحمد إبراهيم', 'female', '2015-03-03', 'أ. مجذوب أحمد إبراهيم', '+2499120001', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000110', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000110', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000111', v_school_id, 'STD-TEST-0111', 'وليد أحمد عبد الله المهدي', 'male', '2015-04-04', 'أ. أحمد عبد الله المهدي', '+2499120002', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000111', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000111', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000112', v_school_id, 'STD-TEST-0112', 'زينب عمر جاد الله عبد القادر', 'female', '2015-05-05', 'أ. عمر جاد الله عبد القادر', '+2499120003', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000112', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000112', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000113', v_school_id, 'STD-TEST-0113', 'علي يوسف عبد العزيز إبراهيم', 'male', '2015-06-06', 'أ. يوسف عبد العزيز إبراهيم', '+2499120004', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000113', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000113', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف السادس الابتدائي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000114', v_school_id, 'STD-TEST-0114', 'عبير فيصل الفاضل الفادني', 'female', '2015-07-07', 'أ. فيصل الفاضل الفادني', '+2499120005', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000114', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000114', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000115', v_school_id, 'STD-TEST-0115', 'محمود إبراهيم مصطفى الجاغريو', 'male', '2014-08-08', 'أ. إبراهيم مصطفى الجاغريو', '+2499120006', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000115', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000115', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000116', v_school_id, 'STD-TEST-0116', 'إسراء معاوية سليمان البشير', 'female', '2014-09-09', 'أ. معاوية سليمان البشير', '+2499120007', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000116', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000116', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000117', v_school_id, 'STD-TEST-0117', 'الهادي أحمد عبد الله عبد الله', 'male', '2014-10-10', 'أ. أحمد عبد الله عبد الله', '+2499120008', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000117', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000117', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000118', v_school_id, 'STD-TEST-0118', 'منى البدوي الشريف عبد القادر', 'female', '2014-11-11', 'أ. البدوي الشريف عبد القادر', '+2499120009', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000118', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000118', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000119', v_school_id, 'STD-TEST-0119', 'علي النذير عبد المنعم الجعلي', 'male', '2014-12-12', 'أ. النذير عبد المنعم الجعلي', '+2499120010', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000119', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000119', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000120', v_school_id, 'STD-TEST-0120', 'إسراء أحمد عبد الله الفادني', 'female', '2014-01-13', 'أ. أحمد عبد الله الفادني', '+2499120011', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000120', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000120', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000121', v_school_id, 'STD-TEST-0121', 'خالد البدوي الشريف الأنصاري', 'male', '2014-02-14', 'أ. البدوي الشريف الأنصاري', '+2499120012', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000121', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000121', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000122', v_school_id, 'STD-TEST-0122', 'نهى مجذوب أحمد الأنصاري', 'female', '2014-03-15', 'أ. مجذوب أحمد الأنصاري', '+2499120013', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000013', 'a0000000-0000-0000-0000-000000000122', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000122', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000123', v_school_id, 'STD-TEST-0123', 'عثمان الرشيد بشير الأرباب', 'male', '2014-04-16', 'أ. الرشيد بشير الأرباب', '+2499120014', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000014', 'a0000000-0000-0000-0000-000000000123', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000123', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000124', v_school_id, 'STD-TEST-0124', 'مي عمر جاد الله عبد الجليل', 'female', '2014-05-17', 'أ. عمر جاد الله عبد الجليل', '+2499120015', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000015', 'a0000000-0000-0000-0000-000000000124', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000124', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000125', v_school_id, 'STD-TEST-0125', 'عثمان مدثر عبد القيوم المهدي', 'male', '2014-06-18', 'أ. مدثر عبد القيوم المهدي', '+2499120016', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000016', 'a0000000-0000-0000-0000-000000000125', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000125', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000126', v_school_id, 'STD-TEST-0126', 'دعاء تاج الدين النور عثمان', 'female', '2014-07-19', 'أ. تاج الدين النور عثمان', '+2499120017', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000017', 'a0000000-0000-0000-0000-000000000126', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000126', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000127', v_school_id, 'STD-TEST-0127', 'معاذ إسماعيل صديق الطيب', 'male', '2014-08-20', 'أ. إسماعيل صديق الطيب', '+2499120018', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000018', 'a0000000-0000-0000-0000-000000000127', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000127', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000128', v_school_id, 'STD-TEST-0128', 'سارة طه التوم الأرباب', 'female', '2014-09-21', 'أ. طه التوم الأرباب', '+2499120019', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000019', 'a0000000-0000-0000-0000-000000000128', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000128', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000129', v_school_id, 'STD-TEST-0129', 'نادر محمد الهادي المهدي', 'male', '2013-10-22', 'أ. محمد الهادي المهدي', '+2499120020', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000020', 'a0000000-0000-0000-0000-000000000129', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000129', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000130', v_school_id, 'STD-TEST-0130', 'دعاء يوسف عبد العزيز فضل الله', 'female', '2013-11-23', 'أ. يوسف عبد العزيز فضل الله', '+2499120021', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000130', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000130', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000131', v_school_id, 'STD-TEST-0131', 'أمين إسماعيل صديق الشريف', 'male', '2013-12-24', 'أ. إسماعيل صديق الشريف', '+2499120022', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000022', 'a0000000-0000-0000-0000-000000000131', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000131', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000132', v_school_id, 'STD-TEST-0132', 'مي خالد حسن عبد الله', 'female', '2013-01-25', 'أ. خالد حسن عبد الله', '+2499120023', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000023', 'a0000000-0000-0000-0000-000000000132', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000132', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000133', v_school_id, 'STD-TEST-0133', 'عمر صالح إدريس إبراهيم', 'male', '2013-02-26', 'أ. صالح إدريس إبراهيم', '+2499120024', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000024', 'a0000000-0000-0000-0000-000000000133', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000133', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000134', v_school_id, 'STD-TEST-0134', 'مروة عبد الرحيم بابكر جاد الرب', 'female', '2013-03-27', 'أ. عبد الرحيم بابكر جاد الرب', '+2499120025', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000025', 'a0000000-0000-0000-0000-000000000134', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000134', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000135', v_school_id, 'STD-TEST-0135', 'خالد حاتم السر المهدي', 'male', '2013-04-01', 'أ. حاتم السر المهدي', '+2499120026', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000026', 'a0000000-0000-0000-0000-000000000135', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000135', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000136', v_school_id, 'STD-TEST-0136', 'أماني تاج الدين النور البشير', 'female', '2013-05-02', 'أ. تاج الدين النور البشير', '+2499120027', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000027', 'a0000000-0000-0000-0000-000000000136', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000136', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000137', v_school_id, 'STD-TEST-0137', 'أمين موسى النعيم عبد الجليل', 'male', '2013-06-03', 'أ. موسى النعيم عبد الجليل', '+2499120028', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000028', 'a0000000-0000-0000-0000-000000000137', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000137', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000138', v_school_id, 'STD-TEST-0138', 'حنين الرشيد بشير إبراهيم', 'female', '2013-07-04', 'أ. الرشيد بشير إبراهيم', '+2499120029', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000029', 'a0000000-0000-0000-0000-000000000138', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000138', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000139', v_school_id, 'STD-TEST-0139', 'الهادي عوض الكريم سالم القرشي', 'male', '2013-08-05', 'أ. عوض الكريم سالم القرشي', '+2499120030', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000030', 'a0000000-0000-0000-0000-000000000139', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000139', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000140', v_school_id, 'STD-TEST-0140', 'روان إبراهيم مصطفى الفادني', 'female', '2013-09-06', 'أ. إبراهيم مصطفى الفادني', '+2499120031', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000031', 'a0000000-0000-0000-0000-000000000140', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000140', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000141', v_school_id, 'STD-TEST-0141', 'حمزة الفكي كباشي الشايقي', 'male', '2013-10-07', 'أ. الفكي كباشي الشايقي', '+2499120032', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000032', 'a0000000-0000-0000-0000-000000000141', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000141', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000142', v_school_id, 'STD-TEST-0142', 'شهد حاتم السر جاد الرب', 'female', '2013-11-08', 'أ. حاتم السر جاد الرب', '+2499120033', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000033', 'a0000000-0000-0000-0000-000000000142', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000142', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000143', v_school_id, 'STD-TEST-0143', 'وليد مدثر عبد القيوم فضل الله', 'male', '2012-12-09', 'أ. مدثر عبد القيوم فضل الله', '+2499120034', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000034', 'a0000000-0000-0000-0000-000000000143', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000143', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000144', v_school_id, 'STD-TEST-0144', 'دعاء طه التوم عبد الله', 'female', '2012-01-10', 'أ. طه التوم عبد الله', '+2499120035', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000035', 'a0000000-0000-0000-0000-000000000144', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000144', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000145', v_school_id, 'STD-TEST-0145', 'حمزة علي عثمان البطحاني', 'male', '2012-02-11', 'أ. علي عثمان البطحاني', '+2499120036', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000036', 'a0000000-0000-0000-0000-000000000145', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000145', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000146', v_school_id, 'STD-TEST-0146', 'تقوى عمر جاد الله المبارك', 'female', '2012-03-12', 'أ. عمر جاد الله المبارك', '+2499120037', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000037', 'a0000000-0000-0000-0000-000000000146', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000146', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000147', v_school_id, 'STD-TEST-0147', 'عبد الله إبراهيم مصطفى عبد القادر', 'male', '2012-04-13', 'أ. إبراهيم مصطفى عبد القادر', '+2499120038', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000038', 'a0000000-0000-0000-0000-000000000147', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000147', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000148', v_school_id, 'STD-TEST-0148', 'أميرة بشير الفكي إبراهيم', 'female', '2012-05-14', 'أ. بشير الفكي إبراهيم', '+2499120039', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000039', 'a0000000-0000-0000-0000-000000000148', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000148', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000149', v_school_id, 'STD-TEST-0149', 'عمار صالح إدريس المهدي', 'male', '2012-06-15', 'أ. صالح إدريس المهدي', '+2499120040', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000040', 'a0000000-0000-0000-0000-000000000149', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000149', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000150', v_school_id, 'STD-TEST-0150', 'روان عباس الزبير الشايقي', 'female', '2012-07-16', 'أ. عباس الزبير الشايقي', '+2499120041', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000041', 'a0000000-0000-0000-0000-000000000150', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000150', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000151', v_school_id, 'STD-TEST-0151', 'عثمان عبد الخالق حسن جاد الرب', 'male', '2012-08-17', 'أ. عبد الخالق حسن جاد الرب', '+2499120042', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000042', 'a0000000-0000-0000-0000-000000000151', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000151', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000152', v_school_id, 'STD-TEST-0152', 'فاطمة الصادق التاج جاد الرب', 'female', '2012-09-18', 'أ. الصادق التاج جاد الرب', '+2499120043', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000043', 'a0000000-0000-0000-0000-000000000152', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000152', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000153', v_school_id, 'STD-TEST-0153', 'عمار عبد الرحيم بابكر فضل الله', 'male', '2012-10-19', 'أ. عبد الرحيم بابكر فضل الله', '+2499120044', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000044', 'a0000000-0000-0000-0000-000000000153', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000153', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000154', v_school_id, 'STD-TEST-0154', 'مروة فيصل الفاضل المهدي', 'female', '2012-11-20', 'أ. فيصل الفاضل المهدي', '+2499120045', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000045', 'a0000000-0000-0000-0000-000000000154', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000154', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000155', v_school_id, 'STD-TEST-0155', 'نادر طه التوم البطحاني', 'male', '2012-12-21', 'أ. طه التوم البطحاني', '+2499120046', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000046', 'a0000000-0000-0000-0000-000000000155', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000155', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث المتوسط' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000156', v_school_id, 'STD-TEST-0156', 'آلاء مجذوب أحمد عبد الله', 'female', '2012-01-22', 'أ. مجذوب أحمد عبد الله', '+2499120047', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000047', 'a0000000-0000-0000-0000-000000000156', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000156', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000157', v_school_id, 'STD-TEST-0157', 'عثمان حاتم السر الشايقي', 'male', '2011-02-23', 'أ. حاتم السر الشايقي', '+2499120048', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000048', 'a0000000-0000-0000-0000-000000000157', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000157', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000158', v_school_id, 'STD-TEST-0158', 'صفاء الصادق التاج الفادني', 'female', '2011-03-24', 'أ. الصادق التاج الفادني', '+2499120049', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000049', 'a0000000-0000-0000-0000-000000000158', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000158', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000159', v_school_id, 'STD-TEST-0159', 'مازن موسى النعيم عبد القادر', 'male', '2011-04-25', 'أ. موسى النعيم عبد القادر', '+2499120050', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000050', 'a0000000-0000-0000-0000-000000000159', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000159', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000160', v_school_id, 'STD-TEST-0160', 'إسراء الصادق التاج عبد الجليل', 'female', '2011-05-26', 'أ. الصادق التاج عبد الجليل', '+2499120051', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000051', 'a0000000-0000-0000-0000-000000000160', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000160', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000161', v_school_id, 'STD-TEST-0161', 'حمزة صالح إدريس المهدي', 'male', '2011-06-27', 'أ. صالح إدريس المهدي', '+2499120052', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000052', 'a0000000-0000-0000-0000-000000000161', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000161', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000162', v_school_id, 'STD-TEST-0162', 'إيثار عوض الكريم سالم الشايقي', 'female', '2011-07-01', 'أ. عوض الكريم سالم الشايقي', '+2499120053', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000053', 'a0000000-0000-0000-0000-000000000162', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000162', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000163', v_school_id, 'STD-TEST-0163', 'فيصل طه التوم الفادني', 'male', '2011-08-02', 'أ. طه التوم الفادني', '+2499120054', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000054', 'a0000000-0000-0000-0000-000000000163', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000163', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000164', v_school_id, 'STD-TEST-0164', 'هدى عمر جاد الله البطحاني', 'female', '2011-09-03', 'أ. عمر جاد الله البطحاني', '+2499120055', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000055', 'a0000000-0000-0000-0000-000000000164', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000164', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000165', v_school_id, 'STD-TEST-0165', 'بلال محمد الهادي البشير', 'male', '2011-10-04', 'أ. محمد الهادي البشير', '+2499120056', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000056', 'a0000000-0000-0000-0000-000000000165', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000165', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000166', v_school_id, 'STD-TEST-0166', 'مها عمر جاد الله البشير', 'female', '2011-11-05', 'أ. عمر جاد الله البشير', '+2499120057', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000057', 'a0000000-0000-0000-0000-000000000166', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000166', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000167', v_school_id, 'STD-TEST-0167', 'زياد تاج الدين النور الشريف', 'male', '2011-12-06', 'أ. تاج الدين النور الشريف', '+2499120058', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000058', 'a0000000-0000-0000-0000-000000000167', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000167', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000168', v_school_id, 'STD-TEST-0168', 'منى صالح إدريس المهدي', 'female', '2011-01-07', 'أ. صالح إدريس المهدي', '+2499120059', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000059', 'a0000000-0000-0000-0000-000000000168', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000168', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000169', v_school_id, 'STD-TEST-0169', 'أيمن إبراهيم مصطفى فضل الله', 'male', '2011-02-08', 'أ. إبراهيم مصطفى فضل الله', '+2499120060', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000060', 'a0000000-0000-0000-0000-000000000169', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000169', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000170', v_school_id, 'STD-TEST-0170', 'صفاء عوض الكريم سالم الجاغريو', 'female', '2011-03-09', 'أ. عوض الكريم سالم الجاغريو', '+2499120061', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000061', 'a0000000-0000-0000-0000-000000000170', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000170', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000171', v_school_id, 'STD-TEST-0171', 'حسام صلاح الدين علي الأنصاري', 'male', '2011-04-10', 'أ. صلاح الدين علي الأنصاري', '+2499120062', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000062', 'a0000000-0000-0000-0000-000000000171', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000171', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000172', v_school_id, 'STD-TEST-0172', 'مروة محمد الهادي فضل الله', 'female', '2011-05-11', 'أ. محمد الهادي فضل الله', '+2499120063', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000063', 'a0000000-0000-0000-0000-000000000172', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000172', v_year_id, v_sec_id, 'new', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000173', v_school_id, 'STD-TEST-0173', 'الهادي مجذوب أحمد المامور', 'male', '2011-06-12', 'أ. مجذوب أحمد المامور', '+2499120064', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000064', 'a0000000-0000-0000-0000-000000000173', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000173', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الأول الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000174', v_school_id, 'STD-TEST-0174', 'فاطمة صالح إدريس الشايقي', 'female', '2011-07-13', 'أ. صالح إدريس الشايقي', '+2499120065', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000065', 'a0000000-0000-0000-0000-000000000174', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000174', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000175', v_school_id, 'STD-TEST-0175', 'معاوية عباس الزبير الصديق', 'male', '2010-08-14', 'أ. عباس الزبير الصديق', '+2499120066', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000066', 'a0000000-0000-0000-0000-000000000175', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000175', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000176', v_school_id, 'STD-TEST-0176', 'أميرة المهدي النور الصديق', 'female', '2010-09-15', 'أ. المهدي النور الصديق', '+2499120067', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000067', 'a0000000-0000-0000-0000-000000000176', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000176', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000177', v_school_id, 'STD-TEST-0177', 'يوسف عمر جاد الله الفادني', 'male', '2010-10-16', 'أ. عمر جاد الله الفادني', '+2499120068', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000068', 'a0000000-0000-0000-0000-000000000177', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000177', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000178', v_school_id, 'STD-TEST-0178', 'إيثار الرشيد بشير المهدي', 'female', '2010-11-17', 'أ. الرشيد بشير المهدي', '+2499120069', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000069', 'a0000000-0000-0000-0000-000000000178', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000178', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000179', v_school_id, 'STD-TEST-0179', 'حمزة موسى النعيم الجاغريو', 'male', '2010-12-18', 'أ. موسى النعيم الجاغريو', '+2499120070', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000070', 'a0000000-0000-0000-0000-000000000179', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000179', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000180', v_school_id, 'STD-TEST-0180', 'سارة معاوية سليمان الجاغريو', 'female', '2010-01-19', 'أ. معاوية سليمان الجاغريو', '+2499120071', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000071', 'a0000000-0000-0000-0000-000000000180', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000180', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000181', v_school_id, 'STD-TEST-0181', 'يوسف صالح إدريس جاد الرب', 'male', '2010-02-20', 'أ. صالح إدريس جاد الرب', '+2499120072', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000072', 'a0000000-0000-0000-0000-000000000181', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000181', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000182', v_school_id, 'STD-TEST-0182', 'رحاب عمر جاد الله الصديق', 'female', '2010-03-21', 'أ. عمر جاد الله الصديق', '+2499120073', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000073', 'a0000000-0000-0000-0000-000000000182', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000182', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000183', v_school_id, 'STD-TEST-0183', 'عبد الرحمن النذير عبد المنعم المامور', 'male', '2010-04-22', 'أ. النذير عبد المنعم المامور', '+2499120074', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000074', 'a0000000-0000-0000-0000-000000000183', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000183', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000184', v_school_id, 'STD-TEST-0184', 'رنا إبراهيم مصطفى البشير', 'female', '2010-05-23', 'أ. إبراهيم مصطفى البشير', '+2499120075', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000075', 'a0000000-0000-0000-0000-000000000184', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000184', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000185', v_school_id, 'STD-TEST-0185', 'زياد بشير الفكي إبراهيم', 'male', '2010-06-24', 'أ. بشير الفكي إبراهيم', '+2499120076', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000076', 'a0000000-0000-0000-0000-000000000185', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000185', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000186', v_school_id, 'STD-TEST-0186', 'مي يوسف عبد العزيز الشايقي', 'female', '2010-07-25', 'أ. يوسف عبد العزيز الشايقي', '+2499120077', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000077', 'a0000000-0000-0000-0000-000000000186', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000186', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000187', v_school_id, 'STD-TEST-0187', 'مازن الصادق التاج البطحاني', 'male', '2010-08-26', 'أ. الصادق التاج البطحاني', '+2499120078', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000078', 'a0000000-0000-0000-0000-000000000187', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000187', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000188', v_school_id, 'STD-TEST-0188', 'سحر معاوية سليمان الجعلي', 'female', '2010-09-27', 'أ. معاوية سليمان الجعلي', '+2499120079', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000079', 'a0000000-0000-0000-0000-000000000188', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000188', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000189', v_school_id, 'STD-TEST-0189', 'مازن إبراهيم مصطفى القرشي', 'male', '2010-10-01', 'أ. إبراهيم مصطفى القرشي', '+2499120080', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000080', 'a0000000-0000-0000-0000-000000000189', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000189', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000190', v_school_id, 'STD-TEST-0190', 'يسرى صالح إدريس الجعلي', 'female', '2010-11-02', 'أ. صالح إدريس الجعلي', '+2499120081', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000081', 'a0000000-0000-0000-0000-000000000190', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000190', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000191', v_school_id, 'STD-TEST-0191', 'الصادق عباس الزبير المكي', 'male', '2010-12-03', 'أ. عباس الزبير المكي', '+2499120082', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000082', 'a0000000-0000-0000-0000-000000000191', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000191', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثاني الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000192', v_school_id, 'STD-TEST-0192', 'نسرين المهدي النور الفادني', 'female', '2010-01-04', 'أ. المهدي النور الفادني', '+2499120083', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000083', 'a0000000-0000-0000-0000-000000000192', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000192', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000193', v_school_id, 'STD-TEST-0193', 'حمزة بشير الفكي عثمان', 'male', '2009-02-05', 'أ. بشير الفكي عثمان', '+2499120084', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000084', 'a0000000-0000-0000-0000-000000000193', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000193', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000194', v_school_id, 'STD-TEST-0194', 'زينب فيصل الفاضل إبراهيم', 'female', '2009-03-06', 'أ. فيصل الفاضل إبراهيم', '+2499120085', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000085', 'a0000000-0000-0000-0000-000000000194', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000194', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000195', v_school_id, 'STD-TEST-0195', 'خالد فيصل الفاضل الفادني', 'male', '2009-04-07', 'أ. فيصل الفاضل الفادني', '+2499120086', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000086', 'a0000000-0000-0000-0000-000000000195', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000195', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000196', v_school_id, 'STD-TEST-0196', 'ريان إسماعيل صديق المهدي', 'female', '2009-05-08', 'أ. إسماعيل صديق المهدي', '+2499120087', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000087', 'a0000000-0000-0000-0000-000000000196', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000196', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000197', v_school_id, 'STD-TEST-0197', 'أنس إسماعيل صديق الشايقي', 'male', '2009-06-09', 'أ. إسماعيل صديق الشايقي', '+2499120088', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000088', 'a0000000-0000-0000-0000-000000000197', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000197', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000198', v_school_id, 'STD-TEST-0198', 'مريم محمد الهادي إبراهيم', 'female', '2009-07-10', 'أ. محمد الهادي إبراهيم', '+2499120089', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000089', 'a0000000-0000-0000-0000-000000000198', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000198', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000199', v_school_id, 'STD-TEST-0199', 'محمد الفكي كباشي الأرباب', 'male', '2009-08-11', 'أ. الفكي كباشي الأرباب', '+2499120090', 'graduated')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000090', 'a0000000-0000-0000-0000-000000000199', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000199', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000200', v_school_id, 'STD-TEST-0200', 'سحر الصادق التاج عبد الجليل', 'female', '2009-09-12', 'أ. الصادق التاج عبد الجليل', '+2499120091', 'withdrawn')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000091', 'a0000000-0000-0000-0000-000000000200', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000200', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000201', v_school_id, 'STD-TEST-0201', 'عبد الله أحمد عبد الله المهدي', 'male', '2009-10-13', 'أ. أحمد عبد الله المهدي', '+2499120092', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000092', 'a0000000-0000-0000-0000-000000000201', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000201', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000202', v_school_id, 'STD-TEST-0202', 'يسرى النذير عبد المنعم الطيب', 'female', '2009-11-14', 'أ. النذير عبد المنعم الطيب', '+2499120093', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000093', 'a0000000-0000-0000-0000-000000000202', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000202', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000203', v_school_id, 'STD-TEST-0203', 'مصطفى النذير عبد المنعم إبراهيم', 'male', '2009-12-15', 'أ. النذير عبد المنعم إبراهيم', '+2499120094', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000094', 'a0000000-0000-0000-0000-000000000203', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000203', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000204', v_school_id, 'STD-TEST-0204', 'دانيا بشير الفكي الشايقي', 'female', '2009-01-16', 'أ. بشير الفكي الشايقي', '+2499120095', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000095', 'a0000000-0000-0000-0000-000000000204', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000204', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000205', v_school_id, 'STD-TEST-0205', 'معاوية الفكي كباشي الشايقي', 'male', '2009-02-17', 'أ. الفكي كباشي الشايقي', '+2499120096', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000096', 'a0000000-0000-0000-0000-000000000205', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000205', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000206', v_school_id, 'STD-TEST-0206', 'ريان النذير عبد المنعم الجعلي', 'female', '2009-03-18', 'أ. النذير عبد المنعم الجعلي', '+2499120097', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000097', 'a0000000-0000-0000-0000-000000000206', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000206', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000207', v_school_id, 'STD-TEST-0207', 'معاوية البدوي الشريف الصديق', 'male', '2009-04-19', 'أ. البدوي الشريف الصديق', '+2499120098', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000098', 'a0000000-0000-0000-0000-000000000207', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000207', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000208', v_school_id, 'STD-TEST-0208', 'فاطمة عبد الرحيم بابكر الطيب', 'female', '2009-05-20', 'أ. عبد الرحيم بابكر الطيب', '+2499120099', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000099', 'a0000000-0000-0000-0000-000000000208', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000208', v_year_id, v_sec_id, 'continuing', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (أ)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000209', v_school_id, 'STD-TEST-0209', 'إبراهيم الرشيد بشير المكي', 'male', '2009-06-21', 'أ. الرشيد بشير المكي', '+2499120100', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000100', 'a0000000-0000-0000-0000-000000000209', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000209', v_year_id, v_sec_id, 'repeated', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;


DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec_id uuid;
  v_fee_type_id uuid;
  v_fee_struct_id uuid;
  v_payment_id uuid;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT s.id INTO v_sec_id 
  FROM public.sections s
  JOIN public.grades g ON g.id = s.grade_id
  WHERE s.academic_year_id = v_year_id AND g.name = 'الصف الثالث الثانوي' AND s.name = 'شعبة (ب)'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('a0000000-0000-0000-0000-000000000210', v_school_id, 'STD-TEST-0210', 'هدى عوض الكريم سالم عثمان', 'female', '2009-07-22', 'أ. عوض الكريم سالم عثمان', '+2499120101', 'active')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('c0000000-0000-0000-0000-000000000101', 'a0000000-0000-0000-0000-000000000210', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('a0000000-0000-0000-0000-000000000210', v_year_id, v_sec_id, 'transfer_in', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 5. إضافة الرسوم والمدفوعات والخصومات لعيّنة من الطلاب (نحو 120 معاملة)
-- -----------------------------------------------------------------------------

DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_fee_type_id uuid;
  v_std RECORD;
  v_struct RECORD;
  v_pay_amount numeric;
  v_rec_num text;
  v_idx int := 1;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  SELECT id INTO v_fee_type_id FROM public.fee_types WHERE school_id = v_school_id AND name = 'الرسوم الدراسية السنوية' LIMIT 1;

  FOR v_std IN 
    SELECT s.id, e.section_id, sec.grade_id 
    FROM public.students s
    JOIN public.enrollments e ON e.student_id = s.id AND e.academic_year_id = v_year_id
    JOIN public.sections sec ON sec.id = e.section_id
    WHERE s.student_number LIKE 'STD-TEST-%'
    LIMIT 120
  LOOP
    SELECT * INTO v_struct FROM public.fee_structures WHERE academic_year_id = v_year_id AND grade_id = v_std.grade_id LIMIT 1;
    IF v_struct.id IS NOT NULL THEN
      -- تمنح خصم إخوة أو منحة لبعض الطلاب
      IF v_idx % 4 = 0 THEN
        INSERT INTO public.student_fee_discounts (student_id, academic_year_id, fee_type_id, discount_type, amount, reason)
        VALUES (v_std.id, v_year_id, v_fee_type_id, 'sibling', 20000, '[SEED-200] خصم إخوة مسجلين بالمدرسة')
        ON CONFLICT DO NOTHING;
      END IF;

      -- سداد رسوم (كامل أو جزئي)
      IF v_idx % 3 = 0 THEN
        v_pay_amount := v_struct.amount; -- سداد كامل
      ELSIF v_idx % 3 = 1 THEN
        v_pay_amount := v_struct.amount / 2; -- سداد قسط أول
      ELSE
        v_pay_amount := 0; -- لم يسدد بعد
      END IF;

      IF v_pay_amount > 0 THEN
        v_rec_num := 'REC-TEST-' || LPAD(v_idx::text, 5, '0');
        INSERT INTO public.student_payments (
          student_id, academic_year_id, fee_type_id, amount, payment_method, receipt_number, notes
        ) VALUES (
          v_std.id, v_year_id, v_fee_type_id, v_pay_amount, 
          CASE WHEN v_idx % 2 = 0 THEN 'bank_transfer' ELSE 'cash' END,
          v_rec_num, '[SEED-200] إيصال سداد رسوم معتمد'
        ) ON CONFLICT DO NOTHING;
      END IF;
      v_idx := v_idx + 1;
    END IF;
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 6. إضافة سجلات الحضور والغياب الموثقة لأيام متعددة
-- -----------------------------------------------------------------------------

DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sec RECORD;
  v_sess_id uuid;
  v_std RECORD;
  v_date date;
  v_dates date[] := ARRAY['2026-10-18'::date, '2026-10-19'::date, '2026-10-20'::date, '2026-10-21'::date, '2026-10-22'::date];
  v_status text;
  v_reason text;
  i int;
  c int;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  FOR v_sec IN SELECT id FROM public.sections WHERE academic_year_id = v_year_id LOOP
    FOREACH v_date IN ARRAY v_dates LOOP
      -- إنشاء جلسة الحضور للشعبة
      INSERT INTO public.attendance_sessions (academic_year_id, section_id, attendance_date)
      VALUES (v_year_id, v_sec.id, v_date)
      ON CONFLICT (section_id, attendance_date) DO UPDATE SET attendance_date = EXCLUDED.attendance_date
      RETURNING id INTO v_sess_id;

      c := 1;
      FOR v_std IN SELECT student_id FROM public.enrollments WHERE section_id = v_sec.id LOOP
        IF (c + EXTRACT(DAY FROM v_date)::int) % 15 = 0 THEN
          v_status := 'absent';
          v_reason := 'غياب بدون عذر مسبق';
        ELSIF (c + EXTRACT(DAY FROM v_date)::int) % 12 = 0 THEN
          v_status := 'excused';
          v_reason := 'عذر مرضي مسبق بموافقة الإدارة';
        ELSIF (c + EXTRACT(DAY FROM v_date)::int) % 8 = 0 THEN
          v_status := 'late';
          v_reason := 'تأخر في طابور الصباح';
        ELSE
          v_status := 'present';
          v_reason := NULL;
        END IF;

        INSERT INTO public.attendance_records (session_id, student_id, status, reason)
        VALUES (v_sess_id, v_std.student_id, v_status, v_reason)
        ON CONFLICT (session_id, student_id) DO NOTHING;
        c := c + 1;
      END LOOP;
    END LOOP;
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 7. إضافة الامتحانات والدرجات الأكاديمية (المنشورة والمسودة)
-- -----------------------------------------------------------------------------

DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_sub_math uuid;
  v_sub_arabic uuid;
  v_sub_english uuid;
  v_sec RECORD;
  v_asm_midterm uuid;
  v_asm_quiz uuid;
  v_asm_draft uuid;
  v_std RECORD;
  v_score numeric;
  c int := 1;
BEGIN
  SELECT id INTO v_school_id FROM public.schools LIMIT 1;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN
    SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id ORDER BY starts_on DESC LIMIT 1;
  END IF;

  -- المواد الدراسية الأساسية
  SELECT id INTO v_sub_math FROM public.subjects WHERE school_id = v_school_id AND name = 'الرياضيات' LIMIT 1;
  IF v_sub_math IS NULL THEN
    INSERT INTO public.subjects (school_id, name, code) VALUES (v_school_id, 'الرياضيات', 'MATH') RETURNING id INTO v_sub_math;
  END IF;

  SELECT id INTO v_sub_arabic FROM public.subjects WHERE school_id = v_school_id AND name = 'اللغة العربية' LIMIT 1;
  IF v_sub_arabic IS NULL THEN
    INSERT INTO public.subjects (school_id, name, code) VALUES (v_school_id, 'اللغة العربية', 'ARAB') RETURNING id INTO v_sub_arabic;
  END IF;

  SELECT id INTO v_sub_english FROM public.subjects WHERE school_id = v_school_id AND name = 'اللغة الإنجليزية' LIMIT 1;
  IF v_sub_english IS NULL THEN
    INSERT INTO public.subjects (school_id, name, code) VALUES (v_school_id, 'اللغة الإنجليزية', 'ENG') RETURNING id INTO v_sub_english;
  END IF;

  FOR v_sec IN SELECT id, grade_id FROM public.sections WHERE academic_year_id = v_year_id LOOP
    -- 1. امتحان أعمال السنة منشور
    INSERT INTO public.assessments (academic_year_id, grade_id, subject_id, title, max_score, pass_score, term, status)
    VALUES (v_year_id, v_sec.grade_id, v_sub_math, '[SEED] اختبار أعمال السنة — الرياضيات', 100, 50, 'الفصل الأول', 'published')
    RETURNING id INTO v_asm_midterm;

    -- 2. امتحان لغة عربية منشور
    INSERT INTO public.assessments (academic_year_id, grade_id, subject_id, title, max_score, pass_score, term, status)
    VALUES (v_year_id, v_sec.grade_id, v_sub_arabic, '[SEED] امتحان منتصف الفصل — اللغة العربية', 100, 50, 'الفصل الأول', 'published')
    RETURNING id INTO v_asm_quiz;

    -- 3. امتحان مسودة (Draft) - للتحقق من عدم ظهوره لولي الأمر
    INSERT INTO public.assessments (academic_year_id, grade_id, subject_id, title, max_score, pass_score, term, status)
    VALUES (v_year_id, v_sec.grade_id, v_sub_english, '[SEED] مسودة امتحان نهائي تجريبي — لغة إنجليزية', 100, 50, 'الفصل الأول', 'draft')
    RETURNING id INTO v_asm_draft;

    -- رصد درجات الطلاب في الشعبة
    FOR v_std IN SELECT student_id FROM public.enrollments WHERE section_id = v_sec.id LOOP
      v_score := 60 + (c * 7) % 40; -- درجات واقعية بين 60 و 99
      INSERT INTO public.student_grades (assessment_id, student_id, score, is_absent)
      VALUES (v_asm_midterm, v_std.student_id, v_score, false)
      ON CONFLICT DO NOTHING;

      v_score := 55 + (c * 11) % 45;
      INSERT INTO public.student_grades (assessment_id, student_id, score, is_absent)
      VALUES (v_asm_quiz, v_std.student_id, v_score, false)
      ON CONFLICT DO NOTHING;

      c := c + 1;
    END LOOP;
  END LOOP;
END $$;

COMMIT;
-- ==============================================================================
-- نهاية ملف بيانات الاختبار الموثقة بنجاح.
-- ==============================================================================