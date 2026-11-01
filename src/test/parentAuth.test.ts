import { describe, it, expect } from "vitest";
import {
  validateGuardianLoginInput,
  evaluateGuardianAccountStatus,
  verifyGuardianPassword,
  GENERIC_AUTH_ERROR,
} from "@/lib/guardianAuth";

describe("Suite 4: Parent Portal Authentication & Anti-Enumeration", () => {
  it("rejects empty account code or pin with clear required input guidance", () => {
    expect(validateGuardianLoginInput("", "123")).toEqual({
      success: false,
      message: "يرجى إدخال معرّف الحساب ورمز المرور",
      errorCode: "EMPTY_CREDENTIALS",
    });
    expect(validateGuardianLoginInput("PAR-10101", "")).toEqual({
      success: false,
      message: "يرجى إدخال معرّف الحساب ورمز المرور",
      errorCode: "EMPTY_CREDENTIALS",
    });
  });

  it("enforces OWASP anti-enumeration: returns identical generic error for invalid credentials", () => {
    const wrongPin = verifyGuardianPassword("449210", "WRONG_PIN");
    expect(wrongPin.success).toBe(false);
    expect(wrongPin.message).toBe(GENERIC_AUTH_ERROR);
    expect(wrongPin.errorCode).toBe("INVALID_CREDENTIALS");
  });

  it("CRITICAL SECURITY FIX: strictly blocks login when stored PIN is NULL or empty (prevents bypass)", () => {
    const nullPinCheck = verifyGuardianPassword(null, "123456");
    expect(nullPinCheck.success).toBe(false);
    expect(nullPinCheck.errorCode).toBe("PASSWORD_NOT_SET");

    const emptyPinCheck = verifyGuardianPassword("", "123456");
    expect(emptyPinCheck.success).toBe(false);
    expect(emptyPinCheck.errorCode).toBe("PASSWORD_NOT_SET");

    const undefinedPinCheck = verifyGuardianPassword(undefined, "any_pin");
    expect(undefinedPinCheck.success).toBe(false);
    expect(undefinedPinCheck.errorCode).toBe("PASSWORD_NOT_SET");
  });

  it("blocks suspended accounts with institutional administrative guidance", () => {
    const res = evaluateGuardianAccountStatus("suspended");
    expect(res.success).toBe(false);
    expect(res.errorCode).toBe("ACCOUNT_SUSPENDED");
    expect(res.message).toContain("تم إيقاف حساب ولي الأمر");
  });

  it("blocks unactivated accounts pending school activation", () => {
    const res = evaluateGuardianAccountStatus("pending_activation");
    expect(res.success).toBe(false);
    expect(res.errorCode).toBe("ACCOUNT_INACTIVE");
    expect(res.message).toContain("الحساب غير مفعّل بعد");
  });

  it("authenticates valid credentials when PIN matches", () => {
    const res = verifyGuardianPassword("449210", "449210");
    expect(res.success).toBe(true);
    expect(res.message).toBeUndefined();
  });
});
