-- 0016: رقم ولي الأمر عشوائي من 6 أرقام (بدل PAR-XXXXXX). الحسابات المفعّلة تحتفظ برقمها القديم لأن بريد الدخول مشتق منه.
CREATE OR REPLACE FUNCTION public.generate_guardian_account_code()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v text;
BEGIN
  -- رقم ولي أمر عشوائي من 6 أرقام (غير متسلسل، بلا صفر في البداية) وفريد.
  LOOP
    v := (100000 + floor(random() * 900000))::int::text;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.guardians WHERE account_code = v);
  END LOOP;
  RETURN v;
END;
$function$;

-- تحويل الحسابات غير المفعّلة (بلا مستخدم Auth) إلى الصيغة الجديدة؛ رموز التفعيل مرتبطة بمعرّف ولي الأمر فلا تتأثر.
UPDATE public.guardians g
   SET account_code = public.generate_guardian_account_code()
 WHERE g.account_code LIKE 'PAR-%' AND g.user_id IS NULL AND g.status = 'pending_activation';
