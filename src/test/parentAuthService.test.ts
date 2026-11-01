import { describe, it, expect, vi } from "vitest";
import {
  handleParentActivation, validateNewPassword, parentLoginEmail, RateLimiter, type ParentAuthDeps,
} from "@/lib/parentAuth.server";

function deps(over: Partial<ParentAuthDeps> = {}): ParentAuthDeps {
  return {
    checkActivation: vi.fn(async () => ({ guardian_id: "g1", user_id: null, purpose: "activate" as const })),
    completeActivation: vi.fn(async () => true),
    createAuthUser: vi.fn(async () => ({ id: "u1" })),
    findAuthUserByEmail: vi.fn(async () => null),
    deleteAuthUser: vi.fn(async () => undefined),
    updateAuthPassword: vi.fn(async () => true),
    ...over,
  };
}
const ok = { account_code: "par-ab12cd", activation_code: "AAAA-BBBB-CCCC-DDDD", password: "Str0ng-pass!" };

describe("parent activation service (منطق الخادم)", () => {
  it("يفعّل حساباً جديداً ويعيد البريد المشتق من account_code", async () => {
    const d = deps();
    const r = await handleParentActivation(ok, d);
    expect(r.status).toBe(200);
    expect(r.body).toEqual({ ok: true, email: "par-ab12cd@parents.alumrabi.invalid" });
    expect(d.createAuthUser).toHaveBeenCalledWith("par-ab12cd@parents.alumrabi.invalid", ok.password);
    expect(d.completeActivation).toHaveBeenCalledWith("g1", "u1");
  });
  it("رمز خاطئ أو حساب غير موجود: نفس الرد 401 ولا يُنشأ مستخدم", async () => {
    const d = deps({ checkActivation: vi.fn(async () => null) });
    const r = await handleParentActivation(ok, d);
    expect(r.status).toBe(401);
    expect(r.body["error"]).toBe("invalid_code");
    expect(d.createAuthUser).not.toHaveBeenCalled();
  });
  it("كلمة مرور ضعيفة تُرفض قبل أي تحقق من الرمز (لا تستهلك محاولات)", async () => {
    const d = deps();
    for (const pw of ["short", "12345678", "aaaaaaaaaa", "xx-par-ab12cd-xx", 123 as unknown as string]) {
      expect((await handleParentActivation({ ...ok, password: pw }, d)).status).toBe(400);
    }
    expect(d.checkActivation).not.toHaveBeenCalled();
  });
  it("مدخلات غير صالحة → 400", async () => {
    const d = deps();
    expect((await handleParentActivation({ account_code: "", activation_code: "x", password: ok.password }, d)).status).toBe(400);
    expect((await handleParentActivation({ account_code: "PAR-1", activation_code: "AAAA-BBBB-CCCC-DDDD" }, d)).status).toBe(400);
  });
  it("إعادة التعيين تحدّث كلمة مرور المستخدم الحالي ولا تنشئ مستخدماً", async () => {
    const d = deps({ checkActivation: vi.fn(async () => ({ guardian_id: "g1", user_id: "u9", purpose: "reset" as const })) });
    const r = await handleParentActivation(ok, d);
    expect(r.status).toBe(200);
    expect(d.updateAuthPassword).toHaveBeenCalledWith("u9", ok.password);
    expect(d.createAuthUser).not.toHaveBeenCalled();
    expect(d.completeActivation).toHaveBeenCalledWith("g1", "u9");
  });
  it("حساب محجوز مسبقاً من طرف ثالث (squatter) يُحذف ثم يُنشأ الحساب الصحيح", async () => {
    const create = vi.fn().mockResolvedValueOnce({ error: "exists" }).mockResolvedValueOnce({ id: "u2" });
    const d = deps({ createAuthUser: create, findAuthUserByEmail: vi.fn(async () => ({ id: "squat", isGuardian: false })) });
    const r = await handleParentActivation(ok, d);
    expect(r.status).toBe(200);
    expect(d.deleteAuthUser).toHaveBeenCalledWith("squat");
    expect(d.completeActivation).toHaveBeenCalledWith("g1", "u2");
  });
  it("حساب ولي أمر حقيقي موجود بنفس البريد لا يُحذف أبداً → 409", async () => {
    const d = deps({ createAuthUser: vi.fn(async () => ({ error: "exists" as const })), findAuthUserByEmail: vi.fn(async () => ({ id: "real", isGuardian: true })) });
    const r = await handleParentActivation(ok, d);
    expect(r.status).toBe(409);
    expect(d.deleteAuthUser).not.toHaveBeenCalled();
  });
  it("فشل إتمام التفعيل يتراجع: يُحذف المستخدم المُنشأ", async () => {
    const d = deps({ completeActivation: vi.fn(async () => false) });
    expect((await handleParentActivation(ok, d)).status).toBe(409);
    expect(d.deleteAuthUser).toHaveBeenCalledWith("u1");
  });
  it("استثناء أثناء الإتمام يتراجع أيضاً", async () => {
    const d = deps({ completeActivation: vi.fn(async () => { throw new Error("boom"); }) });
    expect((await handleParentActivation(ok, d)).status).toBe(409);
    expect(d.deleteAuthUser).toHaveBeenCalledWith("u1");
  });
});

describe("أدوات مساعدة", () => {
  it("validateNewPassword", () => {
    expect(validateNewPassword("Abcdef12!", "PAR-X")).toBeNull();
    expect(validateNewPassword("a".repeat(73), "PAR-X")).not.toBeNull();
  });
  it("parentLoginEmail يطبّع الحالة", () => {
    expect(parentLoginEmail(" PAR-AB12CD ")).toBe("par-ab12cd@parents.alumrabi.invalid");
  });
  it("RateLimiter يحجب بعد الحد ويفتح بعد النافذة", () => {
    let t = 0;
    const rl = new RateLimiter(2, 1000, () => t);
    expect([rl.allow("a"), rl.allow("a"), rl.allow("a")]).toEqual([true, true, false]);
    expect(rl.allow("b")).toBe(true);
    t = 1500;
    expect(rl.allow("a")).toBe(true);
  });
});
