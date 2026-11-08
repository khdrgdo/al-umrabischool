-- ⚠️ بيانات اختبار فقط — لا يوضع في supabase/migrations ولا يُشغَّل تلقائياً.
-- ============================================================================
-- Seed آمن لاختبار تطبيق أولياء الأمور (العمرابي) — v1
--
-- يعمل على قاعدة اختبار فقط، ويُشغَّل يدوياً بحساب يتجاوز RLS (postgres/service_role):
--   PGOPTIONS="-c app.seed_environment=test -c app.seed_confirm=I-CONFIRM-THIS-IS-A-DISPOSABLE-TEST-DATABASE" \
--   psql "$TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/test-seed/seed_parent_app_test_data.sql
--
-- الضمانات:
--  * ذرّي: كتلة واحدة داخل معاملة واحدة؛ أي خطأ يلغي كل شيء.
--  * قابل لإعادة التشغيل بلا تكرار: يمسح أولاً بياناته المعلّمة فقط ثم يعيد إنشاءها.
--  * لا يلمس: auth.users، profiles، user_roles، audit_log، إعدادات المؤسسة، schools/grades/
--    academic_years/sections/tracks/subjects/teachers/periods/timetable (الجدول يبقى كما هو).
--  * لا يُنشئ حسابات Auth ولا كلمات مرور ولا PIN ولا أي رمز تفعيل. الأسر تبقى pending_activation
--    وتُصدَر رموز التفعيل لاحقاً من لوحة الإدارة (_issue_guardian_code) كما في الإنتاج.
--  * account_code يولَّد بالدالة الفعلية public.generate_guardian_account_code().
--  * يتوقف (دون تغيير) إذا وُجدت بيانات طلاب لا يمكن إثبات أنها اختبارية، أو إذا لم تكن
--    الشعب الحالية ثماني بالضبط، أو إذا كان أحد أولياء الأمور المعلّمين مفعَّلاً (user_id).
--
-- العلامات التي تثبت أن السجل اختباري:
--   students.notes / guardians.address = 'SEED:alumrabi-test-v1'
--   (وللطلاب القدامى: student_number يبدأ بـ STD-2026- أو DEMO-)
--   assessments/announcements/school_events.title تبدأ بـ '[تجريبي]'
--   fee_structures.description = العلامة، student_payments.receipt_number يبدأ بـ SEED-
--   student_fee_discounts.reason يبدأ بـ '[تجريبي]'، fee_types.name تنتهي بـ '(تجريبي)'
--
-- حالة الاختبار: نُفِّذ مرة واحدة على قاعدة Lovable الحية في 2026-11-08 (بعد نسخ احتياطي _bak_20261108_*) ونجحت كل فحوص
-- verify_parent_app_seed.sql.
-- ============================================================================
BEGIN;

DO $seed$
DECLARE
  c_marker constant text := 'SEED:alumrabi-test-v1';
  c_tag    constant text := '[تجريبي]';
  v_n bigint;
  v_cnt int;
  v_fee_tuition uuid;
  v_fee_act uuid;
  v_receipt int := 0;
  v_code text;
  r record;
  v_male_first text[] := ARRAY['أحمد','محمد','عمر','علي','خالد','يوسف','إبراهيم','عثمان','حسن','مصعب','طارق','بكري','هاشم','ياسر','مازن'];
  v_female_first text[] := ARRAY['فاطمة','مريم','آمنة','سارة','هدى','رقية','نهى','إيمان','ريم','سلمى','تسنيم','أسماء','عائشة','لينا','نور'];
  v_mid text[] := ARRAY['عبدالله','الطيب','إدريس','صالح','آدم','بشير','النور','الفاتح','سليمان','عوض'];
  v_family text[] := ARRAY['الحاج','الأمين','عبدالرحمن','التوم','مصطفى','دفع الله','الجعلي','حامد','كمال','الماحي','بابكر','الزين'];
BEGIN
  -- ───────── 1. حراس الأمان ─────────
  IF coalesce(current_setting('app.seed_environment', true), '') <> 'test'
     OR coalesce(current_setting('app.seed_confirm', true), '') <> 'I-CONFIRM-THIS-IS-A-DISPOSABLE-TEST-DATABASE' THEN
    RAISE EXCEPTION 'SEED BLOCKED: اضبط app.seed_environment=test و app.seed_confirm (انظر رأس الملف). لا يُشغَّل على الإنتاج.';
  END IF;

  SELECT count(*) INTO v_n FROM public.students
   WHERE coalesce(notes,'') <> c_marker
     AND student_number NOT LIKE 'STD-2026-%' AND student_number NOT LIKE 'DEMO-%';
  IF v_n > 0 THEN
    RAISE EXCEPTION 'SEED BLOCKED: يوجد % طالب/طلاب لا يمكن إثبات أنهم بيانات اختبار. لن يُمسح أو يُضاف شيء.', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM public.guardians WHERE address = c_marker AND user_id IS NOT NULL;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'SEED BLOCKED: % من أولياء أمر الاختبار لديهم حساب Auth مفعَّل. لا يُحذف أي حساب.', v_n;
  END IF;

  -- ───────── 2. الشعب الحالية (يجب أن تكون ثماني بالضبط) ─────────
  CREATE TEMP TABLE _sec ON COMMIT DROP AS
  SELECT row_number() OVER (ORDER BY sc.stage, g.level_order, sec.name, sec.id)::int AS sidx,
         sec.id AS section_id, ay.id AS year_id, sc.id AS school_id, g.id AS grade_id,
         sc.stage, g.level_order,
         CASE WHEN (sc.name || ' ' || sec.name) LIKE '%بنات%' THEN 'female'
              WHEN (sc.name || ' ' || sec.name) LIKE '%بنين%' THEN 'male' END AS gender_hint
    FROM public.sections sec
    JOIN public.academic_years ay ON ay.id = sec.academic_year_id AND ay.is_current
    JOIN public.grades g ON g.id = sec.grade_id
    JOIN public.schools sc ON sc.id = ay.school_id AND sc.is_active;
  SELECT count(*) INTO v_cnt FROM _sec;
  IF v_cnt <> 8 THEN
    RAISE EXCEPTION 'SEED STOPPED: وُجدت % شعبة في السنوات الحالية بدل 8. طابق الحالة الحية ثم عدّل الخطة؛ لم يُغيَّر شيء.', v_cnt;
  END IF;

  -- ───────── 3. مسح بيانات الاختبار المُثبَتة فقط (بترتيب المفاتيح الأجنبية) ─────────
  CREATE TEMP TABLE _old_stu ON COMMIT DROP AS
    SELECT id FROM public.students
     WHERE notes = c_marker OR student_number LIKE 'STD-2026-%' OR student_number LIKE 'DEMO-%';

  DELETE FROM public.guardian_students WHERE student_id IN (SELECT id FROM _old_stu);
  DELETE FROM public.guardians WHERE address = c_marker;            -- user_id محجوز NULL بالحارس أعلاه
  DELETE FROM public.attendance_records WHERE student_id IN (SELECT id FROM _old_stu);
  DELETE FROM public.attendance_sessions s
   WHERE NOT EXISTS (SELECT 1 FROM public.attendance_records ar WHERE ar.session_id = s.id)
     AND s.section_id IN (SELECT section_id FROM _sec);
  DELETE FROM public.student_grades WHERE student_id IN (SELECT id FROM _old_stu);
  DELETE FROM public.assessments WHERE title LIKE c_tag || '%';
  DELETE FROM public.student_payments WHERE student_id IN (SELECT id FROM _old_stu) AND reversal_payment_id IS NOT NULL;
  DELETE FROM public.student_payments WHERE student_id IN (SELECT id FROM _old_stu);
  DELETE FROM public.student_fee_discounts WHERE student_id IN (SELECT id FROM _old_stu);
  DELETE FROM public.fee_structures WHERE description = c_marker;
  DELETE FROM public.enrollments WHERE student_id IN (SELECT id FROM _old_stu);
  DELETE FROM public.students WHERE id IN (SELECT id FROM _old_stu);
  DELETE FROM public.announcements WHERE title LIKE c_tag || '%';
  DELETE FROM public.school_events WHERE title LIKE c_tag || '%';

  -- ───────── 4. الطلاب (25 لكل شعبة = 200) والأسر (115) ─────────
  -- توزيع الأسر: 15 أسرة × 3 أبناء، 55 × 2، 45 × 1. التبديل (×37 mod 200) يفرّق الإخوة على الشعب.
  CREATE TEMP TABLE _stu (idx int PRIMARY KEY, sidx int, fam int, rnk int, gender text, id uuid, guardian_id uuid) ON COMMIT DROP;
  INSERT INTO _stu (idx, sidx, fam, rnk, gender)
  SELECT idx, (idx - 1) / 25 + 1,
         CASE WHEN pos <= 45  THEN (pos - 1) / 3 + 1
              WHEN pos <= 155 THEN 15 + (pos - 46) / 2 + 1
              ELSE 70 + (pos - 155) END,
         CASE WHEN pos <= 45  THEN (pos - 1) % 3 + 1
              WHEN pos <= 155 THEN (pos - 46) % 2 + 1
              ELSE 1 END,
         NULL
    FROM (SELECT i AS idx, ((i - 1) * 37) % 200 + 1 AS pos FROM generate_series(1, 200) i) p;

  UPDATE _stu t SET gender = coalesce(s.gender_hint, CASE WHEN t.idx % 2 = 0 THEN 'female' ELSE 'male' END)
    FROM _sec s WHERE s.sidx = t.sidx;

  -- أولياء الأمور (account_code من الدالة الفعلية؛ الحالة pending_activation؛ بلا Auth/رمز تفعيل)
  FOR r IN SELECT t.fam, (array_agg(s.school_id))[1] AS school_id
             FROM _stu t JOIN _sec s ON s.sidx = t.sidx
            GROUP BY t.fam ORDER BY t.fam LOOP
    LOOP
      v_code := public.generate_guardian_account_code();
      EXIT WHEN NOT EXISTS (SELECT 1 FROM public.guardians WHERE account_code = v_code);
    END LOOP;
    INSERT INTO public.guardians (school_id, full_name, phone, address, account_code, status)
    VALUES (r.school_id,
            v_male_first[r.fam % 15 + 1] || ' ' || v_mid[(r.fam / 10) % 10 + 1] || ' ' || v_family[r.fam % 12 + 1],
            '09' || lpad((10000000 + (r.fam * 7919) % 80000000)::text, 8, '0'),
            c_marker, v_code, 'pending_activation');
  END LOOP;

  -- ربط معرّف ولي الأمر بالطالب عبر الهاتف الاصطناعي الفريد للأسرة
  UPDATE _stu t SET guardian_id = g.id
    FROM public.guardians g
   WHERE g.address = c_marker
     AND g.phone = '09' || lpad((10000000 + (t.fam * 7919) % 80000000)::text, 8, '0');
  IF EXISTS (SELECT 1 FROM _stu WHERE guardian_id IS NULL)
     OR (SELECT count(DISTINCT guardian_id) FROM _stu) <> 115 THEN
    RAISE EXCEPTION 'SEED STOPPED: تعارض في ربط الأسر (هاتف اصطناعي مكرر). أُلغيت المعاملة.';
  END IF;

  -- الطلاب والتسجيلات (الرقم المدرسي يولده trigger النظام)
  FOR r IN SELECT t.idx, t.fam, t.rnk, t.gender, s.section_id, s.year_id, s.school_id, s.stage, s.level_order, g.full_name AS gname, g.phone AS gphone
             FROM _stu t JOIN _sec s ON s.sidx = t.sidx JOIN public.guardians g ON g.id = t.guardian_id ORDER BY t.idx LOOP
    INSERT INTO public.students (school_id, full_name, gender, birth_date, guardian_name, guardian_relation, guardian_phone, notes)
    VALUES (r.school_id,
            CASE WHEN r.gender = 'male' THEN v_male_first[(r.idx * 7) % 15 + 1] ELSE v_female_first[(r.idx * 7) % 15 + 1] END
              || ' ' || split_part(r.gname, ' ', 1) || ' ' || split_part(r.gname, ' ', 2) || ' ' || split_part(r.gname, ' ', 3),
            r.gender,
            make_date(extract(year FROM current_date)::int
                        - (CASE lower(r.stage) WHEN 'secondary' THEN 15 WHEN 'intermediate' THEN 12
                                               WHEN 'primary' THEN 7 WHEN 'basic' THEN 7
                                               WHEN 'kindergarten' THEN 4 WHEN 'kg' THEN 4 ELSE 10 END)
                        - greatest(r.level_order - 1, 0),
                      1 + r.idx % 12, 1 + r.idx % 28),
            r.gname, CASE WHEN r.fam % 2 = 0 THEN 'father' ELSE 'mother' END, r.gphone, c_marker)
    RETURNING id INTO v_code;  -- مؤقتاً نستخدم المتغير النصي لتفادي متغير جديد
    UPDATE _stu SET id = v_code::uuid WHERE idx = r.idx;
    INSERT INTO public.enrollments (student_id, academic_year_id, section_id, enrollment_type)
    VALUES (v_code::uuid, r.year_id, r.section_id, 'continuing');
    INSERT INTO public.guardian_students (guardian_id, student_id, relation, is_primary, can_view_fees, receives_notifications)
    SELECT t.guardian_id, t.id, CASE WHEN t.fam % 2 = 0 THEN 'father' ELSE 'mother' END, true, true, true
      FROM _stu t WHERE t.idx = r.idx;
  END LOOP;

  -- ───────── 5. الحضور: آخر 10 أيام دراسية (الأحد–الخميس) ─────────
  CREATE TEMP TABLE _days ON COMMIT DROP AS
  SELECT d::date AS d FROM generate_series(current_date - 21, current_date, interval '1 day') d
   WHERE extract(dow FROM d) NOT IN (5, 6) ORDER BY d DESC LIMIT 10;

  INSERT INTO public.attendance_sessions (academic_year_id, section_id, attendance_date)
  SELECT s.year_id, s.section_id, dd.d FROM _sec s CROSS JOIN _days dd
  ON CONFLICT (section_id, attendance_date) DO NOTHING;

  INSERT INTO public.attendance_records (session_id, student_id, status, reason)
  SELECT ses.id, t.id,
         CASE WHEN abs(hashtext(t.idx::text || dd.d::text)) % 14 = 0 THEN 'absent' ELSE 'present' END,
         CASE WHEN abs(hashtext(t.idx::text || dd.d::text)) % 14 = 0 THEN 'غياب بعذر (بيانات تجريبية)' END
    FROM _stu t JOIN _sec s ON s.sidx = t.sidx CROSS JOIN _days dd
    JOIN public.attendance_sessions ses ON ses.section_id = s.section_id AND ses.attendance_date = dd.d
  ON CONFLICT (session_id, student_id) DO NOTHING;

  -- ───────── 6. النتائج: اختبار منشور وآخر غير منشور لكل مادة (حتى 3 مواد لكل مدرسة) ─────────
  FOR r IN SELECT s.section_id, s.year_id, sub.id AS subject_id, sub.name AS subject_name
             FROM _sec s
             JOIN LATERAL (SELECT id, name FROM public.subjects WHERE school_id = s.school_id AND is_active ORDER BY name LIMIT 3) sub ON true LOOP
    INSERT INTO public.assessments (academic_year_id, section_id, subject_id, title, term, max_score, pass_score, status)
    VALUES (r.year_id, r.section_id, r.subject_id, c_tag || ' اختبار منتصف الفصل', 'midterm', 100, 50, 'draft'),
           (r.year_id, r.section_id, r.subject_id, c_tag || ' تقييم الفصل الثاني (غير منشور)', 'term_2', 100, 50, 'draft');
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM public.assessments WHERE title LIKE c_tag || '%') THEN
    RAISE EXCEPTION 'SEED STOPPED: لا توجد مواد نشطة للمدارس؛ لا يمكن إنشاء نتائج. أُلغيت المعاملة.';
  END IF;

  -- الدرجات تُرصد والاختبار draft (الـ trigger يمنع الرصد بعد النشر)، ثم يُنشر الأول فقط
  INSERT INTO public.student_grades (assessment_id, student_id, score, is_absent, absence_reason)
  SELECT a.id, t.id,
         CASE WHEN abs(hashtext(t.idx::text || a.id::text)) % 40 = 0 THEN NULL
              ELSE 35 + abs(hashtext(a.id::text || t.idx::text)) % 60 END,
         abs(hashtext(t.idx::text || a.id::text)) % 40 = 0,
         CASE WHEN abs(hashtext(t.idx::text || a.id::text)) % 40 = 0 THEN 'غياب عن الاختبار (بيانات تجريبية)' END
    FROM public.assessments a JOIN _sec s ON s.section_id = a.section_id JOIN _stu t ON t.sidx = s.sidx
   WHERE a.title LIKE c_tag || '%';
  UPDATE public.assessments SET status = 'published' WHERE title = c_tag || ' اختبار منتصف الفصل';

  -- ───────── 7. الرسوم والخصومات والمدفوعات ─────────
  FOR r IN SELECT DISTINCT school_id FROM _sec LOOP
    SELECT id INTO v_fee_tuition FROM public.fee_types WHERE school_id = r.school_id AND name = 'رسوم دراسية (تجريبي)' LIMIT 1;
    IF v_fee_tuition IS NULL THEN INSERT INTO public.fee_types (school_id, name) VALUES (r.school_id, 'رسوم دراسية (تجريبي)'); END IF;
    SELECT id INTO v_fee_act FROM public.fee_types WHERE school_id = r.school_id AND name = 'رسوم أنشطة (تجريبي)' LIMIT 1;
    IF v_fee_act IS NULL THEN INSERT INTO public.fee_types (school_id, name) VALUES (r.school_id, 'رسوم أنشطة (تجريبي)'); END IF;
  END LOOP;

  INSERT INTO public.fee_structures (academic_year_id, grade_id, fee_type_id, amount, due_date, description)
  SELECT DISTINCT s.year_id, s.grade_id, ft.id,
         CASE WHEN ft.name LIKE 'رسوم دراسية%' THEN 300000 + s.level_order * 50000 ELSE 40000 END,
         CASE WHEN ft.name LIKE 'رسوم دراسية%' THEN current_date + 30 ELSE current_date - 20 END,
         c_marker
    FROM _sec s JOIN public.fee_types ft ON ft.school_id = s.school_id AND ft.name IN ('رسوم دراسية (تجريبي)', 'رسوم أنشطة (تجريبي)')
  ON CONFLICT ON CONSTRAINT fee_structures_unique_academic_grade_track_fee DO NOTHING;

  -- خصم الإخوة 10% من الرسوم الدراسية للابن الثاني فما فوق
  INSERT INTO public.student_fee_discounts (student_id, academic_year_id, fee_type_id, discount_type, amount, reason)
  SELECT t.id, s.year_id, ft.id, 'sibling', round(fs.amount * 0.10, 2), c_tag || ' خصم إخوة'
    FROM _stu t JOIN _sec s ON s.sidx = t.sidx
    JOIN public.fee_types ft ON ft.school_id = s.school_id AND ft.name = 'رسوم دراسية (تجريبي)'
    JOIN public.fee_structures fs ON fs.academic_year_id = s.year_id AND fs.grade_id = s.grade_id AND fs.fee_type_id = ft.id AND fs.track_id IS NULL
   WHERE t.rnk >= 2;

  -- مدفوعات: دراسية (idx%3: 0 لا شيء، 1 نصف، 2 كاملة بعد الخصم) وأنشطة (الأزواج تدفع)
  FOR r IN SELECT t.id AS student_id, t.idx, t.rnk, s.year_id,
                  ft.id AS fee_type_id, ft.name AS fee_name, fs.amount
             FROM _stu t JOIN _sec s ON s.sidx = t.sidx
             JOIN public.fee_types ft ON ft.school_id = s.school_id AND ft.name IN ('رسوم دراسية (تجريبي)', 'رسوم أنشطة (تجريبي)')
             JOIN public.fee_structures fs ON fs.academic_year_id = s.year_id AND fs.grade_id = s.grade_id AND fs.fee_type_id = ft.id AND fs.track_id IS NULL
            ORDER BY t.idx, ft.name LOOP
    DECLARE v_pay numeric(12,2) := 0;
    BEGIN
      IF r.fee_name LIKE 'رسوم دراسية%' THEN
        v_pay := CASE r.idx % 3 WHEN 1 THEN round(r.amount * 0.5, 2)
                                WHEN 2 THEN r.amount - CASE WHEN r.rnk >= 2 THEN round(r.amount * 0.10, 2) ELSE 0 END
                                ELSE 0 END;
      ELSIF r.idx % 2 = 0 THEN
        v_pay := r.amount;
      END IF;
      IF v_pay > 0 THEN
        v_receipt := v_receipt + 1;
        INSERT INTO public.student_payments (student_id, academic_year_id, fee_type_id, amount, payment_method, receipt_number, notes)
        VALUES (r.student_id, r.year_id, r.fee_type_id, v_pay,
                (ARRAY['cash','bank_transfer','cheque','pos'])[v_receipt % 4 + 1],
                'SEED-' || lpad(v_receipt::text, 6, '0'), c_tag || ' دفعة تجريبية');
      END IF;
    END;
  END LOOP;

  -- ───────── 8. الإعلانات والتقويم ─────────
  INSERT INTO public.announcements (school_id, title, body, priority, target_audience, is_published, expires_at)
  SELECT sc.school_id, x.title, x.body, x.priority, x.aud, x.pub, x.exp
    FROM (SELECT DISTINCT school_id FROM _sec) sc
    CROSS JOIN (VALUES
      (c_tag || ' بدء الامتحانات النصفية', 'تبدأ الامتحانات النصفية الأسبوع القادم. يرجى مراجعة الجدول مع أبنائكم.', 'important', 'parents', true, current_date + 14),
      (c_tag || ' اجتماع أولياء الأمور', 'ندعوكم لحضور اجتماع أولياء الأمور لمناقشة المستوى الدراسي.', 'normal', 'all', true, NULL::date),
      (c_tag || ' إغلاق مؤقت للمدرسة', 'تعطّل الدراسة غداً لظروف طارئة؛ ستُعلَن العودة لاحقاً.', 'urgent', 'parents', true, current_date + 3),
      (c_tag || ' إعلان قديم منتهٍ', 'إعلان منتهي الصلاحية للتحقق من إخفائه.', 'normal', 'parents', true, current_date - 5),
      (c_tag || ' مسودة غير منشورة', 'لا يجب أن يظهر في تطبيق ولي الأمر.', 'normal', 'parents', false, NULL::date),
      (c_tag || ' للموظفين فقط', 'لا يجب أن يظهر لأولياء الأمور.', 'normal', 'staff_only', true, NULL::date)
    ) AS x(title, body, priority, aud, pub, exp);

  INSERT INTO public.school_events (school_id, academic_year_id, title, description, event_type, starts_on, ends_on, target_audience, is_published)
  SELECT s.school_id, s.year_id, x.title, x.descr, x.typ, x.st, x.en, 'all', x.pub
    FROM (SELECT DISTINCT ON (school_id) school_id, year_id FROM _sec ORDER BY school_id, sidx) s
    CROSS JOIN (VALUES
      (c_tag || ' امتحان منتصف الفصل', 'جدول الامتحانات لدى إدارة المدرسة.', 'exam', current_date + 7, current_date + 11, true),
      (c_tag || ' إجازة رسمية', NULL, 'holiday', current_date + 20, current_date + 20, true),
      (c_tag || ' اجتماع أولياء الأمور', NULL, 'meeting', current_date + 5, NULL::date, true),
      (c_tag || ' نهاية الفصل', NULL, 'term_date', current_date + 60, NULL::date, true),
      (c_tag || ' حدث غير منشور', NULL, 'event', current_date + 9, NULL::date, false)
    ) AS x(title, descr, typ, st, en, pub);

  RAISE NOTICE 'SEED OK: % طالب، % أسرة، % دفعة', (SELECT count(*) FROM _stu), (SELECT count(DISTINCT guardian_id) FROM _stu), v_receipt;
END
$seed$;

COMMIT;
