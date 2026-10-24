-- ============================================================================
-- مدرسة العمرابي الثانوية - سكريبت تنظيف وإعادة تهيئة البيانات التجريبية الشاملة
-- Comprehensive Production-Grade Seed Data with Realistic Edge & Anomaly Cases
-- Matches Notion "إصلاح الأخطاء" & "تطبيق العمرابي" Architecture Specifications
-- ============================================================================

BEGIN;

-- 1. تنظيف البيانات التجريبية السابقة مع مراعاة القيود والمفاتيح الأجنبية
TRUNCATE TABLE 
  public.student_grades,
  public.assessments,
  public.assessment_categories,
  public.attendance_records,
  public.attendance_sessions,
  public.student_payments,
  public.student_fee_discounts,
  public.guardian_students,
  public.guardians,
  public.enrollments,
  public.students,
  public.fee_structures,
  public.fee_types,
  public.school_events,
  public.announcements
CASCADE;

-- 2. التحقق من وجود المدرسة والسنة الدراسية الحالية
DO $$
DECLARE
  v_school_id uuid;
  v_year_id uuid;
  v_g1_id uuid;
  v_g2_id uuid;
  v_g3_id uuid;
  v_t_sci uuid;
  v_t_art uuid;
  v_sec1a uuid;
  v_sec1b uuid;
  v_sec2a uuid;
  v_sec3_sci uuid;
  v_sec3_art uuid;
  v_sub_math uuid;
  v_sub_arab uuid;
  v_sub_eng uuid;
  v_sub_phys uuid;
  v_sub_chem uuid;
  v_sub_islm uuid;
  v_fee_tuition uuid;
  v_fee_books uuid;
  v_std1 uuid;
  v_std2 uuid;
  v_std3 uuid;
  v_std4 uuid;
  v_std5 uuid;
  v_std6 uuid;
  v_std7 uuid;
  v_std8 uuid;
  v_guard1 uuid;
  v_guard2 uuid;
  v_guard3 uuid;
  v_guard4 uuid;
  v_guard5 uuid;
  v_ass1 uuid;
  v_ass2 uuid;
  v_ass3 uuid;
  v_ass_hidden uuid;
  v_ass_draft uuid;
  v_sess1 uuid;
  v_sess2 uuid;
  v_sess3 uuid;
  v_sess4 uuid;
  v_sess_unrecorded uuid;
BEGIN
  -- A. الحصول على المدرسة أو إنشاؤها
  SELECT id INTO v_school_id FROM public.schools WHERE name = 'مدرسة العمرابي الثانوية' LIMIT 1;
  IF v_school_id IS NULL THEN
    INSERT INTO public.schools (name, stage, is_active)
    VALUES ('مدرسة العمرابي الثانوية', 'secondary', true)
    RETURNING id INTO v_school_id;
  END IF;

  -- B. السنة الدراسية 2025/2026 (الحالية)
  UPDATE public.academic_years SET is_current = false WHERE school_id = v_school_id;
  SELECT id INTO v_year_id FROM public.academic_years WHERE school_id = v_school_id AND name = '2025/2026' LIMIT 1;
  IF v_year_id IS NULL THEN
    INSERT INTO public.academic_years (school_id, name, starts_on, ends_on, is_current)
    VALUES (v_school_id, '2025/2026', '2025-09-01', '2026-06-30', true)
    RETURNING id INTO v_year_id;
  ELSE
    UPDATE public.academic_years SET is_current = true, starts_on = '2025-09-01', ends_on = '2026-06-30' WHERE id = v_year_id;
  END IF;

  -- C. الصفوف الدراسية (Grades)
  SELECT id INTO v_g1_id FROM public.grades WHERE school_id = v_school_id AND level_order = 1 LIMIT 1;
  IF v_g1_id IS NULL THEN
    INSERT INTO public.grades (school_id, name, level_order) VALUES (v_school_id, 'الصف الأول الثانوي', 1) RETURNING id INTO v_g1_id;
  END IF;

  SELECT id INTO v_g2_id FROM public.grades WHERE school_id = v_school_id AND level_order = 2 LIMIT 1;
  IF v_g2_id IS NULL THEN
    INSERT INTO public.grades (school_id, name, level_order) VALUES (v_school_id, 'الصف الثاني الثانوي', 2) RETURNING id INTO v_g2_id;
  END IF;

  SELECT id INTO v_g3_id FROM public.grades WHERE school_id = v_school_id AND level_order = 3 LIMIT 1;
  IF v_g3_id IS NULL THEN
    INSERT INTO public.grades (school_id, name, level_order) VALUES (v_school_id, 'الصف الثالث الثانوي', 3) RETURNING id INTO v_g3_id;
  END IF;

  -- D. المسارات لصف ثالث
  SELECT id INTO v_t_sci FROM public.tracks WHERE grade_id = v_g3_id AND name = 'المسار العلمي' LIMIT 1;
  IF v_t_sci IS NULL THEN
    INSERT INTO public.tracks (grade_id, name) VALUES (v_g3_id, 'المسار العلمي') RETURNING id INTO v_t_sci;
  END IF;

  SELECT id INTO v_t_art FROM public.tracks WHERE grade_id = v_g3_id AND name = 'المسار الأدبي' LIMIT 1;
  IF v_t_art IS NULL THEN
    INSERT INTO public.tracks (grade_id, name) VALUES (v_g3_id, 'المسار الأدبي') RETURNING id INTO v_t_art;
  END IF;

  -- E. الفصول / الشعب الدراسية (Sections) للسنة الحالية
  DELETE FROM public.sections WHERE academic_year_id = v_year_id;

  INSERT INTO public.sections (academic_year_id, grade_id, name, capacity)
  VALUES (v_year_id, v_g1_id, 'شعبة (أ)', 35) RETURNING id INTO v_sec1a;

  INSERT INTO public.sections (academic_year_id, grade_id, name, capacity)
  VALUES (v_year_id, v_g1_id, 'شعبة (ب)', 35) RETURNING id INTO v_sec1b;

  INSERT INTO public.sections (academic_year_id, grade_id, name, capacity)
  VALUES (v_year_id, v_g2_id, 'شعبة (أ)', 40) RETURNING id INTO v_sec2a;

  INSERT INTO public.sections (academic_year_id, grade_id, track_id, name, capacity)
  VALUES (v_year_id, v_g3_id, v_t_sci, 'شعبة علمي (أ)', 30) RETURNING id INTO v_sec3_sci;

  INSERT INTO public.sections (academic_year_id, grade_id, track_id, name, capacity)
  VALUES (v_year_id, v_g3_id, v_t_art, 'شعبة أدبي (أ)', 30) RETURNING id INTO v_sec3_art;

  -- F. المواد الدراسية (Subjects)
  DELETE FROM public.subjects WHERE school_id = v_school_id;

  INSERT INTO public.subjects (school_id, name, code, is_active) VALUES (v_school_id, 'الرياضيات', 'MATH-01', true) RETURNING id INTO v_sub_math;
  INSERT INTO public.subjects (school_id, name, code, is_active) VALUES (v_school_id, 'اللغة العربية', 'ARAB-01', true) RETURNING id INTO v_sub_arab;
  INSERT INTO public.subjects (school_id, name, code, is_active) VALUES (v_school_id, 'اللغة الإنجليزية', 'ENG-01', true) RETURNING id INTO v_sub_eng;
  INSERT INTO public.subjects (school_id, name, code, is_active) VALUES (v_school_id, 'الفيزياء', 'PHYS-01', true) RETURNING id INTO v_sub_phys;
  INSERT INTO public.subjects (school_id, name, code, is_active) VALUES (v_school_id, 'الكيمياء', 'CHEM-01', true) RETURNING id INTO v_sub_chem;
  INSERT INTO public.subjects (school_id, name, code, is_active) VALUES (v_school_id, 'التربية الإسلامية', 'ISLM-01', true) RETURNING id INTO v_sub_islm;

  -- G. أنواع وهيكل الرسوم المدرسية (Fees)
  INSERT INTO public.fee_types (school_id, name, is_active) VALUES (v_school_id, 'رسوم دراسية سنوية', true) RETURNING id INTO v_fee_tuition;
  INSERT INTO public.fee_types (school_id, name, is_active) VALUES (v_school_id, 'رسوم التسجيل والكُتب', true) RETURNING id INTO v_fee_books;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, due_date, description)
  VALUES 
    (v_year_id, v_g1_id, v_fee_tuition, 300000.00, '2025-11-30', 'الرسوم الدراسية للصف الأول الثانوي'),
    (v_year_id, v_g2_id, v_fee_tuition, 320000.00, '2025-11-30', 'الرسوم الدراسية للصف الثاني الثانوي'),
    (v_year_id, v_g3_id, v_fee_tuition, 350000.00, '2025-11-30', 'الرسوم الدراسية للصف الثالث الثانوي');

  -- H. الطلاب والبيانات الشاذة والمتنوعة (Edge Cases)
  -- الطالب 1: متفوق، مسدد بالكامل، حضور منتظم
  INSERT INTO public.students (school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES (v_school_id, 'STD-2026-001', 'محمد عبد الله أحمد', 'male', '2010-04-12', 'د. عبد الله أحمد عبد الله', '+249912345678', 'active')
  RETURNING id INTO v_std1;

  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_std1, v_year_id, v_sec1a, 'new', 'active');

  -- الطالب 2: أخت الطالب 1 (حساب متعدد الأبناء)، سداد جزئي متبقي عليها مبالغ، غياب بعذر طبي
  INSERT INTO public.students (school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES (v_school_id, 'STD-2026-002', 'فاطمة عبد الله أحمد', 'female', '2008-07-25', 'د. عبد الله أحمد عبد الله', '+249912345678', 'active')
  RETURNING id INTO v_std2;

  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_std2, v_year_id, v_sec3_sci, 'continuing', 'active');

  -- الطالب 3: إعفاء كامل من الرسوم (منحة كفالة أيتام 100%)، درجات عالية
  INSERT INTO public.students (school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES (v_school_id, 'STD-2026-003', 'عمر عثمان علي', 'male', '2010-09-18', 'م. عثمان علي إبراهيم', '+249923456789', 'active')
  RETURNING id INTO v_std3;

  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_std3, v_year_id, v_sec1a, 'new', 'active');

  -- الطالب 4: حالة شاذة - طالب معلق (suspended) وموقوف عن الدراسة
  INSERT INTO public.students (school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES (v_school_id, 'STD-2026-004', 'يوسف طارق مهدي', 'male', '2009-02-14', 'أ. سلوى إبراهيم حسن', '+249934567890', 'suspended')
  RETURNING id INTO v_std4;

  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_std4, v_year_id, v_sec2a, 'continuing', 'withdrawn');

  -- الطالب 5: حالة رسوب وحد نجاح حرج (Borderline) وغياب متكرر ورسوم متأخرة
  INSERT INTO public.students (school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES (v_school_id, 'STD-2026-005', 'أحمد إبراهيم خالد', 'male', '2008-11-03', 'إبراهيم خالد مصطفى', '+249945678901', 'active')
  RETURNING id INTO v_std5;

  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_std5, v_year_id, v_sec3_art, 'continuing', 'active');

  -- الطالب 6: حالة منقول حديثاً في منتصف العام (transfer_in)
  INSERT INTO public.students (school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES (v_school_id, 'STD-2026-006', 'سارة كمال النور', 'female', '2010-01-30', 'سمية عادل عمر', '+249956789012', 'active')
  RETURNING id INTO v_std6;

  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_std6, v_year_id, v_sec1b, 'transfer_in', 'active');

  -- الطالب 7: الطالبة الأولى على المدرسة (100% حضور، ودرجات كاملة)
  INSERT INTO public.students (school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES (v_school_id, 'STD-2026-007', 'زينب صديق بابكر', 'female', '2009-06-15', 'صديق بابكر أحمد', '+249967890123', 'active')
  RETURNING id INTO v_std7;

  INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
  VALUES (v_std7, v_year_id, v_sec2a, 'continuing', 'active');

  -- I. أولياء الأمور وحسابات تطبيق ولي الأمر (Guardians & Mobile App Accounts)
  -- ولي أمر 1: د. عبد الله (متعدد الأبناء - محمد وفاطمة)
  -- كود الحساب: PAR-10101 | رمز المرور / PIN: 449210 | الحالة: active
  INSERT INTO public.guardians (school_id, full_name, phone, national_id, email, address, account_code, status, temp_password_code, activated_at)
  VALUES (v_school_id, 'د. عبد الله أحمد عبد الله', '+249912345678', '1980123456789', 'abdallah@example.com', 'الخرطوم - الرياض', 'PAR-10101', 'active', '449210', now())
  RETURNING id INTO v_guard1;

  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES 
    (v_guard1, v_std1, 'father', true, true, true),
    (v_guard1, v_std2, 'father', true, true, true);

  -- ولي أمر 2: م. عثمان علي (ولي أمر الطالب المعفى 100%)
  -- كود الحساب: PAR-20202 | رمز المرور: 112233 | الحالة: active
  INSERT INTO public.guardians (school_id, full_name, phone, national_id, email, address, account_code, status, temp_password_code, activated_at)
  VALUES (v_school_id, 'م. عثمان علي إبراهيم', '+249923456789', '1985987654321', 'osman@example.com', 'أم درمان - المهندسين', 'PAR-20202', 'active', '112233', now())
  RETURNING id INTO v_guard2;

  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES (v_guard2, v_std3, 'father', true, true, true);

  -- ولي أمر 3: حساب موقوف من قبل الإدارة (Suspended Guarding Testing)
  -- كود الحساب: PAR-30303 | رمز المرور: 998877 | الحالة: suspended
  INSERT INTO public.guardians (school_id, full_name, phone, national_id, email, address, account_code, status, temp_password_code)
  VALUES (v_school_id, 'أ. سلوى إبراهيم حسن', '+249934567890', '1988345678901', 'salwa@example.com', 'بحري - الصافية', 'PAR-30303', 'suspended', '998877')
  RETURNING id INTO v_guard3;

  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES (v_guard3, v_std4, 'mother', true, true, true);

  -- ولي أمر 4: ولي أمر الطالب الحرج والراسب (أحمد إبراهيم)
  -- كود الحساب: PAR-40404 | رمز المرور: 554433 | الحالة: active
  INSERT INTO public.guardians (school_id, full_name, phone, national_id, email, address, account_code, status, temp_password_code, activated_at)
  VALUES (v_school_id, 'إبراهيم خالد مصطفى', '+249945678901', '1979456789012', 'ibrahim@example.com', 'الخرطوم - العمارات', 'PAR-40404', 'active', '554433', now())
  RETURNING id INTO v_guard4;

  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES (v_guard4, v_std5, 'father', true, true, true);

  -- ولي أمر 5: حساب قيد التفعيل لم يكتمل بعد (Pending Activation Testing)
  -- كود الحساب: PAR-50505 | رمز المرور: 776655 | الحالة: pending_activation
  INSERT INTO public.guardians (school_id, full_name, phone, national_id, email, address, account_code, status, temp_password_code)
  VALUES (v_school_id, 'سمية عادل عمر', '+249956789012', '1989567890123', 'somaya@example.com', 'أم درمان - الثورة', 'PAR-50505', 'pending_activation', '776655')
  RETURNING id INTO v_guard5;

  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES (v_guard5, v_std6, 'mother', true, true, true);

  -- J. الرسوم والمدفوعات والإعفاءات (Payments & Financial Scenarios)
  -- 1) الطالب 1: سداد كامل لمبلغ 300,000 عن طريق تحويل بنكي
  INSERT INTO public.student_payments (student_id, academic_year_id, fee_type_id, amount, payment_method, receipt_number, notes)
  VALUES (v_std1, v_year_id, v_fee_tuition, 300000.00, 'bank_transfer', 'REC-2026-001', 'تم السداد كاملاً عبر بنكك بالرقم المرجعي BOK-99210');

  -- 2) الطالب 2: سداد جزئي 150,000 نقداً من إجمالي 350,000 (متبقي 200,000)
  INSERT INTO public.student_payments (student_id, academic_year_id, fee_type_id, amount, payment_method, receipt_number, notes)
  VALUES (v_std2, v_year_id, v_fee_tuition, 150000.00, 'cash', 'REC-2026-002', 'القسط الأول نقداً بالمكتب المالي');

  -- 3) الطالب 3: إعفاء كامل 100% (300,000)
  INSERT INTO public.student_fee_discounts (student_id, academic_year_id, fee_type_id, discount_type, amount, reason)
  VALUES (v_std3, v_year_id, v_fee_tuition, 'financial_aid', 300000.00, 'إعفاء كفالة اجتماعية وأيتام بموافقة مجلس الإدارة');

  -- 4) الطالب 5: لم يسدد أي مبالغ (مديونية كاملة 350,000 متأخرة)

  -- K. الاختبارات والتقييمات الأكاديمية (Assessments & Edge Case Grades)
  -- اختبار 1: رياضيات - الصف الأول (published)
  INSERT INTO public.assessments (academic_year_id, section_id, subject_id, title, term, max_score, pass_score, status)
  VALUES (v_year_id, v_sec1a, v_sub_math, 'امتحان منتصف الفصل الدراسي الأول - الرياضيات', 'midterm', 100.00, 50.00, 'published')
  RETURNING id INTO v_ass1;

  -- اختبار 2: فيزياء - الصف الثالث علمي (published)
  INSERT INTO public.assessments (academic_year_id, section_id, subject_id, title, term, max_score, pass_score, status)
  VALUES (v_year_id, v_sec3_sci, v_sub_phys, 'امتحان منتصف الفصل الدراسي الأول - الفيزياء', 'midterm', 100.00, 50.00, 'published')
  RETURNING id INTO v_ass2;

  -- اختبار 3: لغة عربية - الصف الثالث أدبي (published)
  INSERT INTO public.assessments (academic_year_id, section_id, subject_id, title, term, max_score, pass_score, status)
  VALUES (v_year_id, v_sec3_art, v_sub_arab, 'امتحان منتصف الفصل الدراسي الأول - اللغة العربية', 'midterm', 100.00, 50.00, 'published')
  RETURNING id INTO v_ass3;

  -- اختبار 4: كيمياء (approved - غير منشور للآباء per Notion Rule)
  INSERT INTO public.assessments (academic_year_id, section_id, subject_id, title, term, max_score, pass_score, status)
  VALUES (v_year_id, v_sec3_sci, v_sub_chem, 'اختبار الكيمياء الشهري', 'term_1', 50.00, 25.00, 'approved')
  RETURNING id INTO v_ass_hidden;

  -- درجات الطلاب:
  -- محمد عبد الله (متفوق): 96 من 100
  INSERT INTO public.student_grades (assessment_id, student_id, score, is_absent)
  VALUES (v_ass1, v_std1, 96.00, false);

  -- عمر عثمان (متفوق ومعفى): 92 من 100
  INSERT INTO public.student_grades (assessment_id, student_id, score, is_absent)
  VALUES (v_ass1, v_std3, 92.00, false);

  -- فاطمة عبد الله (جيد جداً): 74 من 100
  INSERT INTO public.student_grades (assessment_id, student_id, score, is_absent)
  VALUES (v_ass2, v_std2, 74.00, false);

  -- أحمد إبراهيم: درجات شاذة واختبار حالات الرسوب والحد الأدنى
  -- لغة عربية: 49.00 من 100 (راسب بنقطة واحدة! أقل من درجة النجاح 50)
  INSERT INTO public.student_grades (assessment_id, student_id, score, is_absent, notes)
  VALUES (v_ass3, v_std5, 49.00, false, 'راسب - يحتاج إلى معالجة أكاديمية وتقوية');

  -- L. الحضور والغياب وجلسات الغياب غير المرصودة (Attendance & Unrecorded Edge Cases)
  -- جلسة 1: الصف الأول (حضور تام لمحمد وعمر)
  INSERT INTO public.attendance_sessions (academic_year_id, section_id, attendance_date)
  VALUES (v_year_id, v_sec1a, CURRENT_DATE - INTERVAL '3 days')
  RETURNING id INTO v_sess1;

  INSERT INTO public.attendance_records (session_id, student_id, status)
  VALUES 
    (v_sess1, v_std1, 'present'),
    (v_sess1, v_std3, 'present');

  -- جلسة 2: الصف الأول (حضور لمحمد، وغياب بعذر لعمر)
  INSERT INTO public.attendance_sessions (academic_year_id, section_id, attendance_date)
  VALUES (v_year_id, v_sec1a, CURRENT_DATE - INTERVAL '2 days')
  RETURNING id INTO v_sess2;

  INSERT INTO public.attendance_records (session_id, student_id, status, reason)
  VALUES 
    (v_sess2, v_std1, 'present', NULL),
    (v_sess2, v_std3, 'absent', 'وعكة صحية وإجازة مرضية معتمدة');

  -- جلسة 3: الصف الثالث أدبي (غياب غير مبرر لأحمد إبراهيم)
  INSERT INTO public.attendance_sessions (academic_year_id, section_id, attendance_date)
  VALUES (v_year_id, v_sec3_art, CURRENT_DATE - INTERVAL '1 day')
  RETURNING id INTO v_sess3;

  INSERT INTO public.attendance_records (session_id, student_id, status, reason)
  VALUES (v_sess3, v_std5, 'absent', 'غياب بدون عذر أو إشعار مسبق');

  -- جلسة 4: حالة شاذة وفق قاعدة نوشا رقم 6 (جلسة ماضية بدون رصد سجلات لمعرفة كيفية إظهار "لم يُرصد")
  INSERT INTO public.attendance_sessions (academic_year_id, section_id, attendance_date)
  VALUES (v_year_id, v_sec1a, CURRENT_DATE - INTERVAL '4 days')
  RETURNING id INTO v_sess_unrecorded;
  -- لم يتم إدخال أي records لهذه الجلسة عمداً لاختبار Rule 6.

  -- M. الإعلانات والتقويم المدرسي (Announcements & School Events)
  INSERT INTO public.announcements (school_id, title, body, priority, target_audience, is_published, published_at, expires_at)
  VALUES 
    (v_school_id, 'بدء امتحانات منتصف الفصل الدراسي الأول', 'تُهيب إدارة المدرسة بجميع الطلاب وأولياء الأمور الكرام الالتزام بجدول امتحانات منتصف الفصل والحضور في تمام الساعة 7:30 صباحاً.', 'urgent', 'all', true, now(), CURRENT_DATE + INTERVAL '30 days'),
    (v_school_id, 'اجتماع مجلس الآباء والمعلمين الدوري', 'تدعوكم إدارة مدرسة العمرابي الثانوية لحضور الاجتماع الدوري لمناقشة الخطط التربوية ومستوى التحصيل.', 'important', 'parents', true, now(), CURRENT_DATE + INTERVAL '15 days'),
    (v_school_id, 'الالتزام التام بالزي المدرسي الموحد', 'نرجو من أولياء الأمور الكرام متابعة أبنائهم فيما يخص التقيد الكامل بالزي والمظهر العام المعتمد.', 'normal', 'parents', true, now(), CURRENT_DATE + INTERVAL '60 days');

  INSERT INTO public.school_events (school_id, academic_year_id, title, description, event_type, starts_on, ends_on, target_audience, is_published)
  VALUES 
    (v_school_id, v_year_id, 'امتحانات منتصف الفصل الدراسي الأول', 'فترة انعقاد الاختبارات النصفية لجميع الصفوف الدراسية', 'exam', CURRENT_DATE + INTERVAL '10 days', CURRENT_DATE + INTERVAL '20 days', 'all', true),
    (v_school_id, v_year_id, 'عطلة عيد الاستقلال المجيد', 'عطلة رسمية لكافة منسوبي المدرسة من طلاب ومعلمين', 'holiday', '2026-01-01', '2026-01-01', 'all', true),
    (v_school_id, v_year_id, 'اجتماع أولياء الأمور وتوزيع الشهادات', 'لقاء تقييمي مع أولياء الأمور لمناقشة النتائج النصف سنوية', 'meeting', CURRENT_DATE + INTERVAL '25 days', CURRENT_DATE + INTERVAL '25 days', 'parents', true);

END $$;

COMMIT;
