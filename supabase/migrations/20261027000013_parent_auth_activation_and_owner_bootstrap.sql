-- Migration 0013: Parent auth via Supabase Auth + one-time activation codes, owner bootstrap, anon lockdown
--
-- يعالج:
--  P0-02/03/04  إزالة المصادقة بـ PIN النصي عبر anon: حذف parent_app_login و parent_get_portal_data،
--               وحذف العمود guardians.temp_password_code (كان مقروءاً لكل staff ومنسوخاً في audit_log).
--  P0-05        أول مستخدم لم يعد يصبح owner تلقائياً؛ المالك الأول عبر bootstrap_first_owner (service_role فقط).
--  Defense      سحب EXECUTE من PUBLIC/anon على كل دوال public، وحصر صلاحيات أعمدة guardians الحساسة.
--
-- التصميم: كلمة مرور ولي الأمر تُدار حصراً عبر Supabase Auth. رمز التفعيل: 16 خانة hex عشوائية (CSPRNG)،
-- يُخزَّن salted-SHA256 في جدول لا يصل إليه أي دور API، صالح 72 ساعة، 5 محاولات، أحادي الاستخدام.
-- account_code معرّف فقط وليس وسيلة مصادقة.

-- ───────────────────────────── 1. جدول رموز التفعيل (خارج guardians وخارج audit) ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.guardian_activation_codes (
  guardian_id uuid PRIMARY KEY REFERENCES public.guardians(id) ON DELETE CASCADE,
  code_hash   text NOT NULL,
  purpose     text NOT NULL CHECK (purpose IN ('activate', 'reset')),
  expires_at  timestamptz NOT NULL,
  attempts    integer NOT NULL DEFAULT 0,
  issued_by   uuid REFERENCES public.profiles(id),
  issued_at   timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.guardian_activation_codes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.guardian_activation_codes FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.guardian_activation_codes TO service_role;

-- حساب Auth واحد لكل ولي أمر
CREATE UNIQUE INDEX IF NOT EXISTS guardians_user_id_uidx ON public.guardians (user_id) WHERE user_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public._guardian_code_hash(_salt text, _code text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT encode(sha256(convert_to(_salt || ':' || upper(regexp_replace(coalesce(_code, ''), '[^0-9A-Za-z]', '', 'g')), 'UTF8')), 'hex')
$$;

-- ───────────────────────────── 2. ترحيل الحسابات القديمة دون كسرها ─────────────────────────────
-- من كان لديه PIN قديم يصبح رمز تفعيل مؤقتاً (14 يوماً) مُجزَّأً؛ بعد التفعيل يختار كلمة مرور في Supabase Auth.
-- ثم يُحذف النص الصريح من العمود ومن نسخ audit_log.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'guardians' AND column_name = 'temp_password_code') THEN
    INSERT INTO public.guardian_activation_codes (guardian_id, code_hash, purpose, expires_at)
    SELECT g.id, s.salt || ':' || public._guardian_code_hash(s.salt, g.temp_password_code), 'activate', now() + interval '14 days'
    FROM public.guardians g
    CROSS JOIN LATERAL (SELECT replace(gen_random_uuid()::text, '-', '') AS salt) s
    WHERE nullif(btrim(g.temp_password_code), '') IS NOT NULL
      AND g.status IN ('active', 'pending_activation')
      AND g.user_id IS NULL
    ON CONFLICT (guardian_id) DO NOTHING;

    -- إزالة المفتاح السري فقط من سجلات التدقيق (لا حذف للسجلات)
    UPDATE public.audit_log
       SET old_data = old_data - 'temp_password_code',
           new_data = new_data - 'temp_password_code'
     WHERE table_name = 'guardians'
       AND (old_data ? 'temp_password_code' OR new_data ? 'temp_password_code');

    ALTER TABLE public.guardians DROP COLUMN temp_password_code;
  END IF;
END $$;

-- ───────────────────────────── 3. دوال الإدارة (المدير/المالك فقط) ─────────────────────────────
CREATE OR REPLACE FUNCTION public._issue_guardian_code(_guardian_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  g record;
  v_raw text;
  v_code text;
  v_salt text;
  v_purpose text;
  v_acct text;
  v_exp timestamptz := now() + interval '72 hours';
BEGIN
  SELECT * INTO g FROM public.guardians WHERE id = _guardian_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'سجل ولي الأمر غير موجود.'; END IF;

  v_acct := g.account_code;
  IF v_acct IS NULL OR v_acct = '' THEN
    LOOP
      v_acct := public.generate_guardian_account_code();
      EXIT WHEN NOT EXISTS (SELECT 1 FROM public.guardians WHERE account_code = v_acct);
    END LOOP;
    UPDATE public.guardians SET account_code = v_acct WHERE id = _guardian_id;
  END IF;

  v_purpose := CASE WHEN g.user_id IS NULL THEN 'activate' ELSE 'reset' END;
  -- 16 خانة hex عشوائية قوية (64 بت) من uuid v4؛ نتجنب خانة النسخة الثابتة
  v_raw  := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12) || substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));
  v_code := substr(v_raw, 1, 4) || '-' || substr(v_raw, 5, 4) || '-' || substr(v_raw, 9, 4) || '-' || substr(v_raw, 13, 4);
  v_salt := replace(gen_random_uuid()::text, '-', '');

  INSERT INTO public.guardian_activation_codes (guardian_id, code_hash, purpose, expires_at, attempts, issued_by, issued_at)
  VALUES (_guardian_id, v_salt || ':' || public._guardian_code_hash(v_salt, v_raw), v_purpose, v_exp, 0, auth.uid(), now())
  ON CONFLICT (guardian_id) DO UPDATE
    SET code_hash = EXCLUDED.code_hash, purpose = EXCLUDED.purpose, expires_at = EXCLUDED.expires_at,
        attempts = 0, issued_by = EXCLUDED.issued_by, issued_at = EXCLUDED.issued_at;

  INSERT INTO public.audit_log (table_name, record_id, action, new_data, actor_id)
  VALUES ('guardians', _guardian_id::text,
          CASE WHEN v_purpose = 'activate' THEN 'ISSUE_GUARDIAN_ACTIVATION' ELSE 'RESET_GUARDIAN_PASSWORD' END,
          jsonb_build_object('purpose', v_purpose, 'expires_at', v_exp), auth.uid());

  -- temp_code: اسم المفتاح الذي تقرؤه واجهة الإدارة؛ يظهر مرة واحدة فقط ولا يُخزَّن نصاً.
  RETURN jsonb_build_object('account_code', v_acct, 'temp_code', v_code, 'activation_code', v_code,
                            'expires_at', v_exp, 'purpose', v_purpose, 'status', g.status);
END $$;

CREATE OR REPLACE FUNCTION public.admin_issue_guardian_activation(_guardian_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_status text;
BEGIN
  IF auth.uid() IS NULL OR NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية إصدار رمز تفعيل ولي الأمر إلا مدير المدرسة المعتمد.';
  END IF;
  SELECT status INTO v_status FROM public.guardians WHERE id = _guardian_id;
  IF v_status IN ('suspended', 'revoked') THEN
    RAISE EXCEPTION 'الحساب موقوف أو ملغى. أعد تفعيله أولاً من إدارة الحساب.';
  END IF;
  RETURN public._issue_guardian_code(_guardian_id);
END $$;

-- يبقى الاسم القديم للتوافق: تفعيل/إعادة تفعيل. لا يجعل الحساب active قبل أن يختار ولي الأمر كلمة مرور.
CREATE OR REPLACE FUNCTION public.admin_activate_guardian_account(_guardian_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE g record;
BEGIN
  IF auth.uid() IS NULL OR NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية تفعيل حساب ولي الأمر إلا مدير المدرسة المعتمد.';
  END IF;
  SELECT * INTO g FROM public.guardians WHERE id = _guardian_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'سجل ولي الأمر غير موجود.'; END IF;

  IF g.status IN ('suspended', 'revoked') THEN
    UPDATE public.guardians
       SET status = CASE WHEN g.user_id IS NULL THEN 'pending_activation' ELSE 'active' END
     WHERE id = _guardian_id;
    INSERT INTO public.audit_log (table_name, record_id, action, new_data, actor_id)
    VALUES ('guardians', _guardian_id::text, 'REINSTATE_GUARDIAN_ACCOUNT', jsonb_build_object('from', g.status), auth.uid());
    IF g.user_id IS NOT NULL THEN
      RETURN jsonb_build_object('account_code', g.account_code, 'status', 'active', 'purpose', 'reinstated');
    END IF;
  ELSIF g.user_id IS NOT NULL THEN
    RETURN jsonb_build_object('account_code', g.account_code, 'status', g.status, 'purpose', 'already_activated');
  END IF;
  RETURN public._issue_guardian_code(_guardian_id);
END $$;

CREATE OR REPLACE FUNCTION public.admin_reset_guardian_password(_guardian_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT public.can_manage(auth.uid()) THEN
    RAISE EXCEPTION 'عفواً، لا يملك صلاحية إعادة تعيين كلمة المرور إلا مدير المدرسة المعتمد بعد التحقق من هوية ولي الأمر حضورياً.';
  END IF;
  IF (SELECT status FROM public.guardians WHERE id = _guardian_id) IN ('suspended', 'revoked') THEN
    RAISE EXCEPTION 'الحساب موقوف أو ملغى. أعد تفعيله أولاً.';
  END IF;
  RETURN public._issue_guardian_code(_guardian_id);
END $$;

-- ───────────────────────────── 4. دوال الخادم فقط (service_role) ─────────────────────────────
-- تُستدعى من نقطة /api/public/parent-auth على الخادم، لا من المتصفح ولا التطبيق مباشرة.
CREATE OR REPLACE FUNCTION public.parent_check_activation(_account_code text, _code text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  g record;
  c record;
  v_salt text;
BEGIN
  SELECT * INTO g FROM public.guardians WHERE account_code = upper(btrim(coalesce(_account_code, '')));
  IF NOT FOUND THEN RETURN NULL; END IF;

  SELECT * INTO c FROM public.guardian_activation_codes WHERE guardian_id = g.id FOR UPDATE;
  IF NOT FOUND OR c.expires_at < now() OR c.attempts >= 5 OR g.status IN ('suspended', 'revoked') THEN
    RETURN NULL;
  END IF;

  v_salt := split_part(c.code_hash, ':', 1);
  IF split_part(c.code_hash, ':', 2) = public._guardian_code_hash(v_salt, _code) THEN
    RETURN jsonb_build_object('guardian_id', g.id, 'user_id', g.user_id, 'purpose', c.purpose, 'full_name', g.full_name);
  END IF;

  UPDATE public.guardian_activation_codes SET attempts = attempts + 1 WHERE guardian_id = g.id;
  RETURN NULL;
END $$;

CREATE OR REPLACE FUNCTION public.parent_complete_activation(_guardian_id uuid, _user_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE c record;
BEGIN
  DELETE FROM public.guardian_activation_codes
   WHERE guardian_id = _guardian_id AND expires_at > now()
  RETURNING * INTO c;
  IF NOT FOUND THEN RETURN false; END IF;

  UPDATE public.guardians
     SET user_id = _user_id, status = 'active', activated_at = COALESCE(activated_at, now())
   WHERE id = _guardian_id AND (user_id IS NULL OR user_id = _user_id) AND status NOT IN ('suspended', 'revoked');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ACTIVATION_CONFLICT';  -- يتراجع الحذف أعلاه تلقائياً
  END IF;

  INSERT INTO public.audit_log (table_name, record_id, action, new_data, actor_id)
  VALUES ('guardians', _guardian_id::text,
          CASE WHEN c.purpose = 'activate' THEN 'GUARDIAN_ACTIVATION_COMPLETED' ELSE 'GUARDIAN_PASSWORD_RESET_COMPLETED' END,
          jsonb_build_object('purpose', c.purpose), _user_id);
  RETURN true;
END $$;

-- ───────────────────────────── 5. إزالة مسار PIN القديم ─────────────────────────────
DROP FUNCTION IF EXISTS public.parent_app_login(text, text);
DROP FUNCTION IF EXISTS public.parent_get_portal_data(uuid, text, text);

-- ───────────────────────────── 6. حصر صلاحيات أعمدة guardians الحساسة ─────────────────────────────
-- حتى المدير لا يضبط user_id/status/account_code مباشرة: تمر عبر الدوال أعلاه فقط (تُدقَّق وتُقيَّد).
REVOKE INSERT, UPDATE ON public.guardians FROM authenticated;
GRANT INSERT (school_id, full_name, phone, national_id, email, address) ON public.guardians TO authenticated;
GRANT UPDATE (full_name, phone, national_id, email, address) ON public.guardians TO authenticated;

-- ربط الأبناء: إدارة فقط (سياسات RLS الحالية) + ختم هوية المتحقِّق تلقائياً
CREATE OR REPLACE FUNCTION public.guardian_students_stamp_verifier()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.verified_by IS NULL THEN NEW.verified_by := auth.uid(); END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS guardian_students_stamp_verifier ON public.guardian_students;
CREATE TRIGGER guardian_students_stamp_verifier BEFORE INSERT ON public.guardian_students
  FOR EACH ROW EXECUTE FUNCTION public.guardian_students_stamp_verifier();

-- ───────────────────────────── 7. صلاحية المالك ─────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- ملف شخصي فقط. لا أدوار تُمنح بالتسجيل العام أبداً.
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END $$;

-- إجراء إداري محدود: يُنفَّذ مرة واحدة من SQL editor أو بمفتاح service_role، ويرفض إن وُجد owner.
CREATE OR REPLACE FUNCTION public.bootstrap_first_owner(_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid uuid;
BEGIN
  IF EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'owner') THEN
    RAISE EXCEPTION 'OWNER_ALREADY_EXISTS: لا يمكن استخدام هذا الإجراء بعد وجود مالك.';
  END IF;
  SELECT id INTO v_uid FROM public.profiles WHERE lower(email) = lower(btrim(coalesce(_email, '')));
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'لا يوجد مستخدم مسجّل بهذا البريد. سجّل الحساب أولاً ثم أعد المحاولة.';
  END IF;
  INSERT INTO public.user_roles (user_id, role) VALUES (v_uid, 'owner');
  INSERT INTO public.audit_log (table_name, record_id, action, new_data, actor_id)
  VALUES ('user_roles', v_uid::text, 'BOOTSTRAP_FIRST_OWNER', jsonb_build_object('email', lower(btrim(_email))), v_uid);
  RETURN jsonb_build_object('user_id', v_uid, 'role', 'owner');
END $$;

-- ───────────────────────────── 8. قفل صلاحيات التنفيذ ─────────────────────────────
-- (أ) لا PUBLIC ولا anon على أي دالة في public. الأدوار المسجلة تحتفظ بما منح لها صراحةً/افتراضياً.
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS sig
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.prokind = 'f'
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon', r.sig);
  END LOOP;
END $$;
-- (ب) أي دالة تُنشأ لاحقاً لا تُمنح لـ anon تلقائياً.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;
-- (ج) دوال الخادم/الداخلية: service_role فقط.
REVOKE EXECUTE ON FUNCTION public.parent_check_activation(text, text),
                           public.parent_complete_activation(uuid, uuid),
                           public.bootstrap_first_owner(text),
                           public._guardian_code_hash(text, text),
                           public._issue_guardian_code(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.parent_check_activation(text, text),
                          public.parent_complete_activation(uuid, uuid),
                          public.bootstrap_first_owner(text) TO service_role;
-- (د) دوال الإدارة: مستخدم مسجّل (والتحقق can_manage داخلها).
GRANT EXECUTE ON FUNCTION public.admin_issue_guardian_activation(uuid),
                          public.admin_activate_guardian_account(uuid),
                          public.admin_reset_guardian_password(uuid) TO authenticated;
