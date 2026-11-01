/**
 * Admissions, Grade Assignment & Rollover Integrity Library
 * Al-Umrabi School Management System
 */

export interface AdmissionChecklistParams {
  isSecondary: boolean;
  workflow: "new" | "transfer_in" | "continuing" | "re_enrollment" | "transfer_out";
  gradeLevel: number;
  hasIntermediateCert: boolean;
  hasPriorTermReport: boolean;
  waiverReason: string;
  previousSchool?: string | null;
}

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

/**
 * Validates the mandatory checklist of documents required for admissions
 */
export function validateAdmissionChecklist(params: AdmissionChecklistParams): ValidationResult {
  const waiver = params.waiverReason?.trim() || "";

  if (params.isSecondary && !params.hasIntermediateCert && !waiver) {
    return {
      valid: false,
      error: "شهادة المرحلة المتوسطة مطلوبة للتسجيل في المرحلة الثانوية إلا بوجود استثناء معتمد.",
    };
  }

  if (params.workflow === "transfer_in") {
    if (!params.previousSchool?.trim()) {
      return {
        valid: false,
        error: "اسم المدرسة السابقة إلزامي للطلاب المنقولين.",
      };
    }
    if (params.gradeLevel > 1 && !params.hasPriorTermReport && !waiver) {
      return {
        valid: false,
        error: "تقرير درجات الفصل السابق مطلوب للطلاب المنقولين لصفوف متقدمة.",
      };
    }
  }

  return { valid: true };
}

/**
 * Validates that fresh secondary admission is strictly restricted to Grade 1
 */
export function validateFreshSecondaryGrade(
  workflow: string,
  gradeLevelOrder: number
): ValidationResult {
  if (workflow === "new" && gradeLevelOrder > 1) {
    return {
      valid: false,
      error: "لا يمكن قيد طالب مستجد في الصف الثاني أو الثالث الثانوي. القبول المستجد مخصص للصف الأول فقط.",
    };
  }
  return { valid: true };
}

/**
 * Validates that mid-year section changes occur strictly between sections of the same grade level
 */
export function validateMidYearSectionTransfer(
  currentLevelOrder: number,
  targetLevelOrder: number
): ValidationResult {
  if (currentLevelOrder !== targetLevelOrder) {
    return {
      valid: false,
      error: "لا يمكن نقل الطالب إلى شعبة في صف دراسي مختلف خلال العام. النقل متاح فقط بين شعب نفس الصف.",
    };
  }
  return { valid: true };
}

/**
 * Validates annual promotion transitions (level_order + 1)
 */
export function validatePromotionTransition(
  fromLevelOrder: number,
  targetLevelOrder: number
): ValidationResult {
  if (targetLevelOrder !== fromLevelOrder + 1) {
    return {
      valid: false,
      error: "الترقية يجب أن تكون للصف التالي مباشرة (level + 1).",
    };
  }
  return { valid: true };
}

/**
 * Validates repeat retention transitions (same level_order)
 */
export function validateRepeatTransition(
  fromLevelOrder: number,
  targetLevelOrder: number
): ValidationResult {
  if (targetLevelOrder !== fromLevelOrder) {
    return {
      valid: false,
      error: "إعادة القيد يجب أن تكون في نفس الصف الدراسي تماماً.",
    };
  }
  return { valid: true };
}

/**
 * Validates graduation eligibility (strictly from terminal grade)
 */
export function validateGraduationEligibility(
  currentLevelOrder: number,
  maxLevelOrder: number = 3
): ValidationResult {
  if (currentLevelOrder < maxLevelOrder) {
    return {
      valid: false,
      error: `لا يمكن تخريج الطالب إلا من الصف النهائي المؤهل للتخرج (الصف ${maxLevelOrder}).`,
    };
  }
  return { valid: true };
}
