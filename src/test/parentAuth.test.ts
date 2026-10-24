import { describe, it, expect } from "vitest";

// Al-Umrabi Parent Portal Authentication & OWASP Anti-Enumeration Spec
interface LoginInput {
  accountCode: string;
  pin: string;
}

interface GuardianAccount {
  accountCode: string;
  pin: string;
  status: "active" | "pending_activation" | "suspended" | "revoked";
  tempCodeExpiresAt?: Date;
}

const MOCK_ACCOUNTS: Record<string, GuardianAccount> = {
  "PAR-10101": {
    accountCode: "PAR-10101",
    pin: "449210",
    status: "active",
  },
  "PAR-20202": {
    accountCode: "PAR-20202",
    pin: "112233",
    status: "active",
  },
  "PAR-30303": {
    accountCode: "PAR-30303",
    pin: "998877",
    status: "suspended",
  },
  "PAR-50505": {
    accountCode: "PAR-50505",
    pin: "776655",
    status: "pending_activation",
  },
};

const GENERIC_AUTH_ERROR = "بيانات الدخول غير صحيحة. يرجى التأكد من المعرّف أو مراجعة إدارة المدرسة.";

function authenticateGuardian(input: LoginInput): { success: boolean; message?: string; status?: string } {
  const code = input.accountCode.trim().toUpperCase();
  const pin = input.pin.trim();

  if (!code || !pin) {
    return { success: false, message: "يرجى إدخال معرّف الحساب ورمز المرور" };
  }

  const account = MOCK_ACCOUNTS[code];

  // Anti-enumeration: Return generic error if account does not exist
  if (!account) {
    return { success: false, message: GENERIC_AUTH_ERROR };
  }

  // Account status verification
  if (account.status === "suspended") {
    return { success: false, message: "تم إيقاف حساب ولي الأمر من قبل إدارة المدرسة. يرجى مراجعة إدارة المدرسة." };
  }

  if (account.status === "pending_activation") {
    return { success: false, message: "الحساب قيد التفعيل. يرجى التواصل مع إدارة المدرسة لاستلام كود التفعيل المعتمد." };
  }

  if (account.status === "revoked") {
    return { success: false, message: "تم إلغاء هذا الحساب. يرجى مراجعة إدارة المدرسة." };
  }

  // Anti-enumeration: Return exact same generic error if PIN does not match
  if (account.pin !== pin) {
    return { success: false, message: GENERIC_AUTH_ERROR };
  }

  return { success: true, status: account.status };
}

describe("Suite 4: Parent Portal Authentication & Anti-Enumeration", () => {
  it("rejects empty account code or pin with clear required input guidance", () => {
    expect(authenticateGuardian({ accountCode: "", pin: "123" })).toEqual({
      success: false,
      message: "يرجى إدخال معرّف الحساب ورمز المرور",
    });
    expect(authenticateGuardian({ accountCode: "PAR-10101", pin: "" })).toEqual({
      success: false,
      message: "يرجى إدخال معرّف الحساب ورمز المرور",
    });
  });

  it("enforces OWASP anti-enumeration: returns identical generic error for non-existent account and wrong PIN", () => {
    const nonExistent = authenticateGuardian({ accountCode: "PAR-99999", pin: "449210" });
    const wrongPin = authenticateGuardian({ accountCode: "PAR-10101", pin: "WRONG_PIN" });

    expect(nonExistent.success).toBe(false);
    expect(wrongPin.success).toBe(false);
    expect(nonExistent.message).toBe(GENERIC_AUTH_ERROR);
    expect(wrongPin.message).toBe(GENERIC_AUTH_ERROR);
  });

  it("blocks suspended accounts with institutional administrative guidance", () => {
    const res = authenticateGuardian({ accountCode: "PAR-30303", pin: "998877" });
    expect(res.success).toBe(false);
    expect(res.message).toContain("تم إيقاف حساب ولي الأمر");
  });

  it("blocks unactivated accounts pending school activation", () => {
    const res = authenticateGuardian({ accountCode: "PAR-50505", pin: "776655" });
    expect(res.success).toBe(false);
    expect(res.message).toContain("الحساب قيد التفعيل");
  });

  it("authenticates valid active credentials with case-insensitive account code", () => {
    const resUpper = authenticateGuardian({ accountCode: "PAR-10101", pin: "449210" });
    const resLower = authenticateGuardian({ accountCode: "par-10101", pin: "449210" });

    expect(resUpper.success).toBe(true);
    expect(resUpper.status).toBe("active");
    expect(resLower.success).toBe(true);
  });
});
