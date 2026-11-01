import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { printTarget } from "@/lib/printHelper";
import {
  validateAdmissionChecklist,
  validateFreshSecondaryGrade,
  validateMidYearSectionTransfer,
  validatePromotionTransition,
  validateRepeatTransition,
  validateGraduationEligibility,
} from "@/lib/admissions";

describe("Admissions Workflows & Document Studio (Plan 1 & Fahs Audit)", () => {
  describe("Admission Checklist & Waiver Validation Rules", () => {
    it("يرفض تسجيل طالب ثانوي مستجد بدون شهادة المرحلة المتوسطة وبدون سبب استثناء", () => {
      const res = validateAdmissionChecklist({
        isSecondary: true,
        workflow: "new",
        gradeLevel: 1,
        hasIntermediateCert: false,
        hasPriorTermReport: false,
        waiverReason: "",
      });
      expect(res.valid).toBe(false);
      expect(res.error).toContain("شهادة المرحلة المتوسطة مطلوبة");
    });

    it("يقبل تسجيل الطالب عند توفر شهادة المرحلة المتوسطة الأصلية", () => {
      const res = validateAdmissionChecklist({
        isSecondary: true,
        workflow: "new",
        gradeLevel: 1,
        hasIntermediateCert: true,
        hasPriorTermReport: false,
        waiverReason: "",
      });
      expect(res.valid).toBe(true);
      expect(res.error).toBeUndefined();
    });

    it("يقبل تسجيل الطالب بدون الشهادة في حال وجود استثناء رسمي معتمد مع تدوين السبب", () => {
      const res = validateAdmissionChecklist({
        isSecondary: true,
        workflow: "new",
        gradeLevel: 1,
        hasIntermediateCert: false,
        hasPriorTermReport: false,
        waiverReason: "تعهد خطي من ولي الأمر بإحضار الشهادة خلال أسبوعين بموافقة المدير",
      });
      expect(res.valid).toBe(true);
    });

    it("يرفض قيد طالب منقول للصف الثاني ثانوي بدون تقرير الفصل السابق وبدون استثناء", () => {
      const res = validateAdmissionChecklist({
        isSecondary: true,
        workflow: "transfer_in",
        gradeLevel: 2,
        hasIntermediateCert: true,
        hasPriorTermReport: false,
        waiverReason: "",
        previousSchool: "مدرسة بحري الثانوية",
      });
      expect(res.valid).toBe(false);
      expect(res.error).toContain("تقرير درجات الفصل السابق مطلوب");
    });

    it("يقبل قيد الطالب المنقول عند إرفاق تقرير درجات الفصل السابق والمدرسة السابقة", () => {
      const res = validateAdmissionChecklist({
        isSecondary: true,
        workflow: "transfer_in",
        gradeLevel: 2,
        hasIntermediateCert: true,
        hasPriorTermReport: true,
        waiverReason: "",
        previousSchool: "مدرسة بحري الثانوية",
      });
      expect(res.valid).toBe(true);
    });
  });

  describe("Academic Transitions & Integrity Rules (Fahs Stage & Section Audits)", () => {
    it("يمنع قيد طالب مستجد في الصف الثاني أو الثالث الثانوي", () => {
      const checkGrade2 = validateFreshSecondaryGrade("new", 2);
      expect(checkGrade2.valid).toBe(false);
      expect(checkGrade2.error).toContain("لا يمكن قيد طالب مستجد في الصف الثاني أو الثالث");

      const checkGrade3 = validateFreshSecondaryGrade("new", 3);
      expect(checkGrade3.valid).toBe(false);

      const checkGrade1 = validateFreshSecondaryGrade("new", 1);
      expect(checkGrade1.valid).toBe(true);
    });

    it("يسمح للطلاب المنقولين بالتسجيل في الصف الثاني أو الثالث", () => {
      const transferGrade2 = validateFreshSecondaryGrade("transfer_in", 2);
      expect(transferGrade2.valid).toBe(true);
      const transferGrade3 = validateFreshSecondaryGrade("transfer_in", 3);
      expect(transferGrade3.valid).toBe(true);
    });

    it("يمنع النقل بين شعب صفوف مختلفة خلال العام الدراسي (mid-year section transfer)", () => {
      // Trying to move a student from Grade 1 section to Grade 2 section
      const crossGradeTransfer = validateMidYearSectionTransfer(1, 2);
      expect(crossGradeTransfer.valid).toBe(false);
      expect(crossGradeTransfer.error).toContain("لا يمكن نقل الطالب إلى شعبة في صف دراسي مختلف خلال العام");

      // Moving between sections of same grade (Grade 1 -> Grade 1)
      const sameGradeTransfer = validateMidYearSectionTransfer(1, 1);
      expect(sameGradeTransfer.valid).toBe(true);
    });

    it("يتحقق من صحة الترقية السنوية: للصف التالي مباشرة فقط", () => {
      expect(validatePromotionTransition(1, 2).valid).toBe(true);
      expect(validatePromotionTransition(2, 3).valid).toBe(true);
      // Skipping from Grade 1 directly to Grade 3
      expect(validatePromotionTransition(1, 3).valid).toBe(false);
      // Demoting during promotion
      expect(validatePromotionTransition(2, 1).valid).toBe(false);
    });

    it("يتحقق من صحة إعادة القيد: في نفس الصف الدراسي فقط", () => {
      expect(validateRepeatTransition(2, 2).valid).toBe(true);
      expect(validateRepeatTransition(1, 2).valid).toBe(false);
    });

    it("يمنع تخريج الطالب إلا من الصف النهائي المؤهل للتخرج", () => {
      expect(validateGraduationEligibility(3, 3).valid).toBe(true);
      // Attempting to graduate Grade 1 or 2
      expect(validateGraduationEligibility(1, 3).valid).toBe(false);
      expect(validateGraduationEligibility(2, 3).valid).toBe(false);
    });
  });

  describe("Document Studio Template Placeholders Interpolation", () => {
    function interpolateTemplate(
      template: string,
      dict: Record<string, string>
    ): string {
      let output = template;
      for (const [key, value] of Object.entries(dict)) {
        output = output.replaceAll(key, value);
      }
      return output;
    }

    it("يقوم بالتعويض الصحيح لكافة المتغيرات الرسمية المعتمدة", () => {
      const template =
        "تشهد @school.name بأن الطالب @student.full_name (رقم: @student.school_number) مقيد بـ @student.grade_section بتاريخ @document.issue_date.";
      const dict = {
        "@school.name": "مدرسة العمرابي الثانوية بنين",
        "@student.full_name": "عمر خالد حسن",
        "@student.school_number": "UMR-2026-0042",
        "@student.grade_section": "الصف الثاني ثانوي / الشعبة أ",
        "@document.issue_date": "2026-10-26",
      };

      const result = interpolateTemplate(template, dict);
      expect(result).toBe(
        "تشهد مدرسة العمرابي الثانوية بنين بأن الطالب عمر خالد حسن (رقم: UMR-2026-0042) مقيد بـ الصف الثاني ثانوي / الشعبة أ بتاريخ 2026-10-26."
      );
      expect(result).not.toContain("@student");
      expect(result).not.toContain("@school");
    });
  });

  describe("Target-Only Print Helper", () => {
    beforeEach(() => {
      document.body.className = "";
      document.body.innerHTML = `
        <div id="school-receipt-print">محتوى الإيصال المستهدف</div>
        <div id="sidebar">القائمة الجانبية</div>
      `;
      vi.spyOn(window, "print").mockImplementation(() => {});
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it("يقوم بتفعيل وضع الطباعة المستهدفة ووضع السمة data-print-target-active", () => {
      printTarget("school-receipt-print", { documentTitle: "إيصال سداد رسوم" });
      const target = document.getElementById("school-receipt-print");
      expect(target?.getAttribute("data-print-target-active")).toBe("true");
      expect(document.body.classList.contains("printing-target-mode")).toBe(true);
    });
  });
});
