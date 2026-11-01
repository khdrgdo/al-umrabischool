import assert from "node:assert";
import {
  validateGuardianLoginInput,
  evaluateGuardianAccountStatus,
  verifyGuardianPassword,
  verifyGuardianStudentAccess,
  GENERIC_AUTH_ERROR,
} from "../src/lib/guardianAuth.ts";
import {
  validateAdmissionChecklist,
  validateFreshSecondaryGrade,
  validateMidYearSectionTransfer,
  validatePromotionTransition,
  validateRepeatTransition,
  validateGraduationEligibility,
} from "../src/lib/admissions.ts";

console.log("🚀 بدء التحقق التشغيلي من الدوال المنطقية والمكتبات البرمجية المعتمدة...");

// 1. Guardian Auth & Security
console.log("➡️ [1/8] فحص التحقق من المدخلات الفارغة لولي الأمر...");
const emptyCheck = validateGuardianLoginInput("", "123");
assert.strictEqual(emptyCheck.success, false);
assert.strictEqual(emptyCheck.errorCode, "EMPTY_CREDENTIALS");

console.log("➡️ [2/8] فحص أمان OWASP Anti-Enumeration...");
const wrongPin = verifyGuardianPassword("449210", "WRONG_PIN");
assert.strictEqual(wrongPin.success, false);
assert.strictEqual(wrongPin.message, GENERIC_AUTH_ERROR);
assert.strictEqual(wrongPin.errorCode, "INVALID_CREDENTIALS");

console.log("➡️ [3/8] فحص حظر تجاوز PIN الفارغ أو غير المعرف (NULL PIN Security Gate)...");
const nullPin = verifyGuardianPassword(null, "123456");
assert.strictEqual(nullPin.success, false);
assert.strictEqual(nullPin.errorCode, "PASSWORD_NOT_SET");

const emptyStoredPin = verifyGuardianPassword("", "123456");
assert.strictEqual(emptyStoredPin.success, false);
assert.strictEqual(emptyStoredPin.errorCode, "PASSWORD_NOT_SET");

const validPin = verifyGuardianPassword("449210", "449210");
assert.strictEqual(validPin.success, true);

console.log("➡️ [4/8] فحص عزل البيانات ومنع الـ IDOR/BOLA...");
const sampleLinks = [
  { guardianId: "guard-1", studentId: "std-1" },
  { guardianId: "guard-1", studentId: "std-2" },
  { guardianId: "guard-2", studentId: "std-3" },
];
assert.strictEqual(verifyGuardianStudentAccess("guard-1", "std-1", sampleLinks).authorized, true);
assert.strictEqual(verifyGuardianStudentAccess("guard-2", "std-1", sampleLinks).authorized, false);
assert.strictEqual(verifyGuardianStudentAccess("intruder", "std-1", sampleLinks).authorized, false);

// 2. Admissions & Academic Transitions
console.log("➡️ [5/8] فحص قيود الطلاب المستجدين (الصف الأول فقط)...");
assert.strictEqual(validateFreshSecondaryGrade("new", 1).valid, true);
assert.strictEqual(validateFreshSecondaryGrade("new", 2).valid, false);
assert.strictEqual(validateFreshSecondaryGrade("new", 3).valid, false);
assert.strictEqual(validateFreshSecondaryGrade("transfer_in", 2).valid, true);

console.log("➡️ [6/8] فحص قيود النقل بين الشعب خلال العام الدراسي...");
assert.strictEqual(validateMidYearSectionTransfer(1, 1).valid, true);
assert.strictEqual(validateMidYearSectionTransfer(1, 2).valid, false);

console.log("➡️ [7/8] فحص مسارات الترقية السنوية والتخريج...");
assert.strictEqual(validatePromotionTransition(1, 2).valid, true);
assert.strictEqual(validatePromotionTransition(1, 3).valid, false);
assert.strictEqual(validateRepeatTransition(2, 2).valid, true);
assert.strictEqual(validateRepeatTransition(1, 2).valid, false);
assert.strictEqual(validateGraduationEligibility(3, 3).valid, true);
assert.strictEqual(validateGraduationEligibility(1, 3).valid, false);

console.log("➡️ [8/8] فحص متطلبات ملف القبول وشهادة الأساس/المتوسطة...");
assert.strictEqual(
  validateAdmissionChecklist({
    isSecondary: true,
    workflow: "new",
    gradeLevel: 1,
    hasIntermediateCert: false,
    hasPriorTermReport: false,
    waiverReason: "",
  }).valid,
  false
);
assert.strictEqual(
  validateAdmissionChecklist({
    isSecondary: true,
    workflow: "new",
    gradeLevel: 1,
    hasIntermediateCert: true,
    hasPriorTermReport: false,
    waiverReason: "",
  }).valid,
  true
);

console.log("\n✅ نجح الفحص التشغيلي الكامل لكافة الدوال والمنطق الأكاديمي والأمني بنسبة 100%!");
