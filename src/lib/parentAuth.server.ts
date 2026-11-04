// منطق تفعيل/إعادة تعيين حساب ولي الأمر على الخادم (لا يُشحن للمتصفح).
// كلمة المرور تُدار في Supabase Auth حصراً؛ رمز التفعيل يُتحقَّق منه في قاعدة البيانات (hash + انتهاء + حد محاولات).
// account_code معرّف فقط. كل فشل تحقق يعطي نفس الرد العام لمنع تعداد الحسابات.

export const PARENT_LOGIN_EMAIL_DOMAIN = "parents.alumrabi.invalid";

export function parentLoginEmail(accountCode: string): string {
  return `${accountCode.trim().toLowerCase()}@${PARENT_LOGIN_EMAIL_DOMAIN}`;
}

export interface ParentAuthDeps {
  checkActivation(
    accountCode: string,
    code: string,
  ): Promise<{ guardian_id: string; user_id: string | null; purpose: "activate" | "reset" } | null>;
  completeActivation(guardianId: string, userId: string): Promise<boolean>;
  createAuthUser(email: string, password: string): Promise<{ id: string } | { error: "exists" | "weak_password" | "other" }>;
  /** يعيد المستخدم وهل هو حساب ولي أمر أنشأه الخادم (app_metadata.guardian === true) */
  findAuthUserByEmail(email: string): Promise<{ id: string; isGuardian: boolean } | null>;
  deleteAuthUser(id: string): Promise<void>;
  updateAuthPassword(id: string, password: string): Promise<boolean>;
}

export interface ParentAuthResult {
  status: number;
  body: Record<string, unknown>;
}

const GENERIC_INVALID: ParentAuthResult = {
  status: 401,
  body: { ok: false, error: "invalid_code", message: "رمز التفعيل أو رقم الحساب غير صحيح أو منتهي. تواصل مع إدارة المدرسة." },
};

export function validateNewPassword(password: unknown, accountCode: string): string | null {
  if (typeof password !== "string") return "كلمة المرور مطلوبة.";
  if (password.length < 8) return "كلمة المرور يجب ألا تقل عن 8 أحرف.";
  if (password.length > 72) return "كلمة المرور طويلة جداً (الحد 72 حرفاً).";
  if (/^(.)\1+$/.test(password)) return "كلمة المرور ضعيفة.";
  if (/^\d+$/.test(password)) return "كلمة المرور يجب ألا تكون أرقاماً فقط.";
  if (password.toLowerCase().includes(accountCode.trim().toLowerCase())) return "كلمة المرور يجب ألا تحتوي رقم الحساب.";
  return null;
}

/** تحديد معدل بسيط داخل الذاكرة (طبقة إضافية؛ الحد الحاسم هو عدّاد المحاولات في قاعدة البيانات). */
export class RateLimiter {
  private hits = new Map<string, { count: number; resetAt: number }>();
  constructor(private max: number, private windowMs: number, private now: () => number = Date.now) {}
  allow(key: string): boolean {
    const t = this.now();
    const cur = this.hits.get(key);
    if (!cur || cur.resetAt <= t) {
      this.hits.set(key, { count: 1, resetAt: t + this.windowMs });
      if (this.hits.size > 5000) for (const [k, v] of this.hits) if (v.resetAt <= t) this.hits.delete(k);
      return true;
    }
    cur.count += 1;
    return cur.count <= this.max;
  }
}

export async function handleParentActivation(
  input: { account_code?: unknown; activation_code?: unknown; password?: unknown },
  deps: ParentAuthDeps,
): Promise<ParentAuthResult> {
  const accountCode = typeof input.account_code === "string" ? input.account_code.trim().toUpperCase() : "";
  const code = typeof input.activation_code === "string" ? input.activation_code.trim() : "";
  if (!/^[A-Z0-9-]{4,24}$/.test(accountCode) || code.length < 4 || code.length > 40) {
    return { status: 400, body: { ok: false, error: "bad_request", message: "بيانات غير صالحة." } };
  }
  const pwErr = validateNewPassword(input.password, accountCode);
  if (pwErr) return { status: 400, body: { ok: false, error: "weak_password", message: pwErr } };
  const password = input.password as string;

  const chk = await deps.checkActivation(accountCode, code);
  if (!chk) return GENERIC_INVALID;

  const email = parentLoginEmail(accountCode);
  let userId: string;
  let createdHere = false;

  if (chk.purpose === "reset" && chk.user_id) {
    userId = chk.user_id;
    if (!(await deps.updateAuthPassword(userId, password))) {
      return { status: 500, body: { ok: false, error: "server_error", message: "تعذر تحديث كلمة المرور. حاول لاحقاً." } };
    }
  } else {
    let res = await deps.createAuthUser(email, password);
    if ("error" in res && res.error === "exists") {
      // حساب بنفس البريد المشتق: إما محجوز مسبقاً من طرف ثالث (لم ننشئه نحن) فيُحذف، أو حسابنا نفسه فيُرفض.
      const existing = await deps.findAuthUserByEmail(email);
      if (existing && !existing.isGuardian) {
        await deps.deleteAuthUser(existing.id);
        res = await deps.createAuthUser(email, password);
      } else {
        return { status: 409, body: { ok: false, error: "conflict", message: "تعذر إكمال التفعيل. تواصل مع إدارة المدرسة." } };
      }
    }
    if ("error" in res) {
      if (res.error === "weak_password") return { status: 400, body: { ok: false, error: "weak_password", message: "كلمة المرور ضعيفة." } };
      return { status: 500, body: { ok: false, error: "server_error", message: "تعذر إنشاء الحساب. حاول لاحقاً." } };
    }
    userId = res.id;
    createdHere = true;
  }

  let completed = false;
  try {
    completed = await deps.completeActivation(chk.guardian_id, userId);
  } catch {
    completed = false;
  }
  if (!completed) {
    if (createdHere) await deps.deleteAuthUser(userId).catch(() => undefined);
    return { status: 409, body: { ok: false, error: "conflict", message: "تعذر إكمال التفعيل. اطلب رمزاً جديداً من الإدارة." } };
  }
  return { status: 200, body: { ok: true, email } };
}
