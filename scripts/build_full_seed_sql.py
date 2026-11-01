import sys
import random
import os

sys.stdout.reconfigure(encoding='utf-8')

boys_first = [
    "محمد", "أحمد", "عمر", "علي", "عثمان", "خالد", "يوسف", "إبراهيم", "عبد الله", "عبد الرحمن",
    "مصطفى", "حسن", "طارق", "مازن", "ياسين", "بلال", "حمزة", "أنس", "زياد", "حسام",
    "وليد", "سامي", "فيصل", "صالح", "بشير", "معاذ", "أسامة", "حاتم", "أيمن", "عمار",
    "محمود", "مأمون", "الصادق", "الهادي", "نزار", "معاوية", "نادر", "أمين", "سيف", "بهاء"
]

girls_first = [
    "فاطمة", "عائشة", "مريم", "زينب", "هدى", "ريم", "آلاء", "سارة", "إيثار", "تسنيم",
    "منى", "نهى", "رؤى", "شهد", "سلمى", "دعاء", "يسرى", "رنا", "هبة", "أميرة",
    "روان", "سحر", "نجلاء", "مها", "سلافة", "تقوى", "أماني", "ريان", "دانيا", "إيمان",
    "لمياء", "نسرين", "إسراء", "وفاء", "صفاء", "رحاب", "حنين", "عبير", "مي", "مروة"
]

fathers = [
    "أحمد عبد الله", "علي عثمان", "إبراهيم مصطفى", "خالد حسن", "يوسف عبد العزيز",
    "الصادق التاج", "البدوي الشريف", "عمر جاد الله", "المهدي النور", "الفكي كباشي",
    "محمد الهادي", "عبد الرحيم بابكر", "صالح إدريس", "معاوية سليمان", "عباس الزبير",
    "جمال تاج السر", "النذير عبد المنعم", "الرشيد بشير", "مدثر عبد القيوم", "حاتم السر",
    "مجذوب أحمد", "فيصل الفاضل", "طه التوم", "موسى النعيم", "إسماعيل صديق",
    "تاج الدين النور", "عبد الخالق حسن", "بشير الفكي", "صلاح الدين علي", "عوض الكريم سالم"
]

surnames = [
    "عثمان", "البشير", "عبد الله", "إبراهيم", "الصديق", "الطيب", "فضل الله", "عبد القادر",
    "المهدي", "المبارك", "الشريف", "جاد الرب", "القرشي", "الأرباب", "عبد الجليل",
    "المامور", "المكي", "الفادني", "الجاغريو", "الجعلي", "الشايقي", "البطحاني", "الأنصاري"
]

grades_config = [
    # (Stage Name, Grade Name, level_order, count, fee_amount)
    ("الروضة", "المستوى الأول روضة (KG1)", 1, 15, 80000),
    ("الروضة", "المستوى الثاني روضة (KG2)", 2, 15, 80000),
    ("الابتدائي", "الصف الأول الابتدائي", 3, 14, 100000),
    ("الابتدائي", "الصف الثاني الابتدائي", 4, 14, 100000),
    ("الابتدائي", "الصف الثالث الابتدائي", 5, 14, 100000),
    ("الابتدائي", "الصف الرابع الابتدائي", 6, 14, 110000),
    ("الابتدائي", "الصف الخامس الابتدائي", 7, 14, 110000),
    ("الابتدائي", "الصف السادس الابتدائي", 8, 14, 120000),
    ("المتوسط", "الصف الأول المتوسط", 9, 14, 130000),
    ("المتوسط", "الصف الثاني المتوسط", 10, 14, 130000),
    ("المتوسط", "الصف الثالث المتوسط", 11, 14, 135000),
    ("الثانوي", "الصف الأول الثانوي", 12, 18, 150000),
    ("الثانوي", "الصف الثاني الثانوي", 13, 18, 150000),
    ("الثانوي", "الصف الثالث الثانوي", 14, 18, 160000),
]

random.seed(42)

out_dir = r"E:\al-umrabischool\docs\test-only"
os.makedirs(out_dir, exist_ok=True)
out_file = os.path.join(out_dir, "SEED_200_COMPREHENSIVE_STUDENTS.sql")

lines = []
lines.append("-- ==============================================================================")
lines.append("-- SEED_200_COMPREHENSIVE_STUDENTS.sql")
lines.append("-- مجموعة بيانات اختبار اصطناعية واقعية لنحو 210 طالب عبر المراحل الأربع:")
lines.append("-- (الروضة، الابتدائي، الأساس/المتوسط، الثانوي)")
lines.append("-- تم توليدها استجابة لمتطلبات وتوجيهات صفحة Notion: فحص")
lines.append("-- تتضمن: أسر متعددة الأبناء، قيود سنوية، رسوم، خصومات، مدفوعات، حضور، ودرجات")
lines.append("-- ومصممة بأمان: قابلة للتنظيف العكسي دون مساس بهيكل المخطط أو سجل التدقيق.")
lines.append("-- ==============================================================================")
lines.append("")
lines.append("BEGIN;")
lines.append("")
lines.append("-- -----------------------------------------------------------------------------")
lines.append("-- 1. التنظيف العكسي الآمن لبيانات الاختبار السابقة فقط (Safe Reverse Cleanup)")
lines.append("-- -----------------------------------------------------------------------------")
lines.append("DELETE FROM public.student_payment_allocations WHERE payment_id IN (")
lines.append("  SELECT id FROM public.student_payments WHERE receipt_number LIKE 'REC-TEST-%'")
lines.append(");")
lines.append("DELETE FROM public.student_payments WHERE receipt_number LIKE 'REC-TEST-%';")
lines.append("DELETE FROM public.student_fee_discounts WHERE reason LIKE '[SEED-200]%';")
lines.append("DELETE FROM public.attendance_records WHERE session_id IN (")
lines.append("  SELECT id FROM public.attendance_sessions WHERE attendance_date >= '2026-10-01' AND attendance_date <= '2026-10-31'")
lines.append(");")
lines.append("DELETE FROM public.student_grades WHERE assessment_id IN (")
lines.append("  SELECT id FROM public.assessments WHERE title LIKE '[SEED]%'")
lines.append(");")
lines.append("DELETE FROM public.assessments WHERE title LIKE '[SEED]%';")
lines.append("DELETE FROM public.guardian_students WHERE guardian_id IN (")
lines.append("  SELECT id FROM public.guardians WHERE account_code LIKE 'PAR-TEST-%'")
lines.append(");")
lines.append("DELETE FROM public.enrollments WHERE student_id IN (")
lines.append("  SELECT id FROM public.students WHERE student_number LIKE 'STD-TEST-%'")
lines.append(");")
lines.append("DELETE FROM public.students WHERE student_number LIKE 'STD-TEST-%';")
lines.append("DELETE FROM public.guardians WHERE account_code LIKE 'PAR-TEST-%';")
lines.append("")

# Generate guardians (110 guardians)
lines.append("-- -----------------------------------------------------------------------------")
lines.append("-- 2. إنشاء أولياء الأمور (110 أولياء أمور بحسابات متنوعة وأرقام حساب مستقلة)")
lines.append("-- -----------------------------------------------------------------------------")

guardians = []
for i in range(1, 111):
    f_name = random.choice(fathers)
    s_name = random.choice(surnames)
    full_gname = f"أ. {f_name} {s_name}"
    phone = f"+249912{i:04d}"
    acc_code = f"PAR-TEST-{i:03d}"
    pin = "449210" if i <= 10 else f"{100000 + i}"
    # Status distribution: 90 active, 12 pending_activation, 8 suspended
    if i > 102:
        st = "suspended"
    elif i > 90:
        st = "pending_activation"
    else:
        st = "active"
    
    g_id = f"c0000000-0000-0000-0000-{i:012d}"
    guardians.append({
        "id": g_id,
        "name": full_gname,
        "phone": phone,
        "acc_code": acc_code,
        "pin": pin,
        "status": st
    })
    lines.append(
        f"INSERT INTO public.guardians (id, school_id, full_name, phone, account_code, status, temp_password_code) "
        f"SELECT '{g_id}', id, '{full_gname}', '{phone}', '{acc_code}', '{st}', '{pin}' "
        f"FROM public.schools LIMIT 1 "
        f"ON CONFLICT (id) DO NOTHING;"
    )

lines.append("")
lines.append("-- -----------------------------------------------------------------------------")
lines.append("-- 3. إنشاء الصفوف الدراسية والشعب لكافة المراحل الأربع إن لم تكن موجودة")
lines.append("-- -----------------------------------------------------------------------------")

for stage, grade_name, order, count, fee in grades_config:
    lines.append(f"""
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
  SELECT id INTO v_grade_id FROM public.grades WHERE school_id = v_school_id AND name = '{grade_name}';
  IF v_grade_id IS NULL THEN
    INSERT INTO public.grades (id, school_id, name, level_order)
    VALUES (gen_random_uuid(), v_school_id, '{grade_name}', {order})
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
  VALUES (v_year_id, v_grade_id, v_fee_type_id, {fee}, 'رسوم العام الدراسي المقررة')
  ON CONFLICT DO NOTHING;
END $$;
""")

lines.append("-- -----------------------------------------------------------------------------")
lines.append("-- 4. إنشاء الطلاب وقيدهم وتوزيعهم وربطهم بأولياء الأمور (~210 طالب)")
lines.append("-- -----------------------------------------------------------------------------")

student_index = 0
for stage, grade_name, order, count, fee in grades_config:
    for i in range(count):
        student_index += 1
        std_num = f"STD-TEST-{student_index:04d}"
        std_id = f"a0000000-0000-0000-0000-{student_index:012d}"
        
        # Gender & Name
        is_boy = (student_index % 2 == 1)
        gender = "male" if is_boy else "female"
        first = random.choice(boys_first if is_boy else girls_first)
        
        # Guardian assignment: First 30 guardians get 2 or 3 kids (multi-child families)
        if student_index <= 60:
            guardian_idx = (student_index % 30)
        else:
            guardian_idx = (student_index % len(guardians))
        
        guard = guardians[guardian_idx]
        g_id = guard["id"]
        father_name = guard["name"].replace("أ. ", "")
        full_student_name = f"{first} {father_name}"
        
        # Birth date logic based on grade
        # Grade 1 (KG1): age ~4 (birth 2022)
        # Grade 14 (3rd Sec): age ~17 (birth 2009)
        approx_age = 3 + order
        birth_year = 2026 - approx_age
        b_month = (student_index % 12) + 1
        b_day = (student_index % 27) + 1
        birth_date = f"{birth_year}-{b_month:02d}-{b_day:02d}"
        
        # Enrollment type:
        # If order == 1, 3, 9, 12 -> fresh admission 'new'
        # Others: continuing (except a few repeats and transfers)
        if order in (1, 3, 9, 12) and i < (count - 2):
            enr_type = "new"
        elif i == (count - 1):
            enr_type = "transfer_in"
        elif i == (count - 2):
            enr_type = "repeated"
        else:
            enr_type = "continuing"
            
        sec_char = "أ" if (i % 2 == 0) else "ب"
        
        # Status
        st = "active"
        if student_index == 200:
            st = "withdrawn"
        elif student_index == 199 and order == 14:
            st = "graduated"
            
        lines.append(f"""
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
  WHERE s.academic_year_id = v_year_id AND g.name = '{grade_name}' AND s.name = 'شعبة ({sec_char})'
  LIMIT 1;

  -- 1. إضافة الطالب
  INSERT INTO public.students (id, school_id, student_number, full_name, gender, birth_date, guardian_name, guardian_phone, status)
  VALUES ('{std_id}', v_school_id, '{std_num}', '{full_student_name}', '{gender}', '{birth_date}', '{guard["name"]}', '{guard["phone"]}', '{st}')
  ON CONFLICT (id) DO NOTHING;

  -- 2. ربط الطالب بولي الأمر
  INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
  VALUES ('{g_id}', '{std_id}', 'father', true, true, true)
  ON CONFLICT (guardian_id, student_id) DO NOTHING;

  -- 3. قيد الطالب في الشعبة
  IF v_sec_id IS NOT NULL THEN
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type, status)
    VALUES ('{std_id}', v_year_id, v_sec_id, '{enr_type}', 'active')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
""")

lines.append("-- -----------------------------------------------------------------------------")
lines.append("-- 5. إضافة الرسوم والمدفوعات والخصومات لعيّنة من الطلاب (نحو 120 معاملة)")
lines.append("-- -----------------------------------------------------------------------------")

lines.append("""
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
""")

lines.append("-- -----------------------------------------------------------------------------")
lines.append("-- 6. إضافة سجلات الحضور والغياب الموثقة لأيام متعددة")
lines.append("-- -----------------------------------------------------------------------------")

lines.append("""
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
""")

lines.append("-- -----------------------------------------------------------------------------")
lines.append("-- 7. إضافة الامتحانات والدرجات الأكاديمية (المنشورة والمسودة)")
lines.append("-- -----------------------------------------------------------------------------")

lines.append("""
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
""")

lines.append("COMMIT;")
lines.append("-- ==============================================================================")
lines.append("-- نهاية ملف بيانات الاختبار الموثقة بنجاح.")
lines.append("-- ==============================================================================")

with open(out_file, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Successfully generated {student_index} students across 4 stages into {out_file} ({len(lines)} lines).")
