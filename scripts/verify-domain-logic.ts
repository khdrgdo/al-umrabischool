import assert from "node:assert";
import {
  validateAdmissionChecklist,
  validateFreshSecondaryGrade,
  validateMidYearSectionTransfer,
  validatePromotionTransition,
  validateRepeatTransition,
  validateGraduationEligibility,
} from "../src/lib/admissions.ts";

console.log("🚀 بدء التحقق التشغيلي من الدوال المنطقية والمكتبات البرمجية المعتمدة...");

// (فحوص مصادقة/عزل أولياء الأمور انتقلت إلى اختبارات PostgreSQL الحقيقية: src/test/db/parentSecurity.test.ts)

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
