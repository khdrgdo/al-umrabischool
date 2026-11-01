/**
 * Guardian Authentication & Access Control Library
 * Al-Umrabi School Management System
 */

export const GENERIC_AUTH_ERROR = "بيانات الدخول غير صحيحة. يرجى التأكد من المعرّف أو مراجعة إدارة المدرسة.";

export interface GuardianAuthResult {
  success: boolean;
  message?: string;
  errorCode?: "EMPTY_CREDENTIALS" | "INVALID_CREDENTIALS" | "PASSWORD_NOT_SET" | "ACCOUNT_SUSPENDED" | "ACCOUNT_INACTIVE";
}

/**
 * Validates guardian input credentials format
 */
export function validateGuardianLoginInput(accountCode: string, pin: string): GuardianAuthResult {
  const code = accountCode?.trim() || "";
  const p = pin?.trim() || "";

  if (!code || !p) {
    return {
      success: false,
      message: "يرجى إدخال معرّف الحساب ورمز المرور",
      errorCode: "EMPTY_CREDENTIALS",
    };
  }

  return { success: true };
}

/**
 * Evaluates guardian account lifecycle status
 */
export function evaluateGuardianAccountStatus(status: string): GuardianAuthResult {
  if (status === "suspended") {
    return {
      success: false,
      message: "تم إيقاف حساب ولي الأمر من قبل إدارة المدرسة. يرجى مراجعة إدارة المدرسة.",
      errorCode: "ACCOUNT_SUSPENDED",
    };
  }

  if (status === "pending_activation" || status === "revoked") {
    return {
      success: false,
      message: "الحساب غير مفعّل بعد. يرجى مراجعة إدارة المدرسة لتفعيل الحساب.",
      errorCode: "ACCOUNT_INACTIVE",
    };
  }

  return { success: true };
}

/**
 * Securely verifies PIN against stored hash/code, strictly rejecting uninitialized/NULL PINs
 */
export function verifyGuardianPassword(
  storedPin: string | null | undefined,
  inputPin: string
): GuardianAuthResult {
  const cleanInput = inputPin?.trim() || "";
  const cleanStored = storedPin?.trim() || "";

  if (!cleanStored) {
    return {
      success: false,
      message: "لم يتم ضبط كلمة مرور أو رمز دخول لهذا الحساب. يرجى مراجعة إدارة المدرسة لإصدار رمز الدخول.",
      errorCode: "PASSWORD_NOT_SET",
    };
  }

  if (cleanStored !== cleanInput) {
    return {
      success: false,
      message: GENERIC_AUTH_ERROR,
      errorCode: "INVALID_CREDENTIALS",
    };
  }

  return { success: true };
}

/**
 * Verifies guardian authorization to access a specific student record (IDOR Prevention)
 */
export function verifyGuardianStudentAccess(
  guardianId: string,
  studentId: string,
  links: Array<{ guardianId: string; studentId: string }>
): { authorized: boolean; error?: string } {
  const isLinked = links.some(
    (l) => l.guardianId === guardianId && l.studentId === studentId
  );

  if (!isLinked) {
    return {
      authorized: false,
      error: "غير مصرح: لا يملك ولي الأمر صلاحية الوصول لبيانات هذا الطالب",
    };
  }

  return { authorized: true };
}
