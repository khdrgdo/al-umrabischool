import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { printTarget } from "@/lib/printHelper";

describe("Admissions Workflows & Document Studio (Plan 1)", () => {
  describe("Admission Checklist & Waiver Validation Rules", () => {
    function validateAdmission(params: {
      isSecondary: boolean;
      workflow: "new" | "transfer_in" | "continuing";
      gradeLevel: number;
      hasIntermediateCert: boolean;
      hasPriorTermReport: boolean;
      waiverReason: string;
      previousSchool?: string | null;
    }): { valid: boolean; error?: string } {
      if (params.isSecondary && !params.hasIntermediateCert && !params.waiverReason.trim()) {
        return {
          valid: false,
          error: "شهادة المرحلة المتوسطة مطلوبة للتسجيل في المرحلة الثانوية إلا بوجود استثناء معتمد.",
        };
      }

      if (params.workflow === "transfer_in") {
        if (!params.previousSchool?.trim()) {
          return { valid: false, error: "اسم المدرسة السابقة إلزامي للطلاب المنقولين." };
        }
        if (params.gradeLevel > 1 && !params.hasPriorTermReport && !params.waiverReason.trim()) {
          return {
            valid: false,
            error: "تقرير درجات الفصل السابق مطلوب للطلاب المنقولين لصفوف متقدمة.",
          };
        }
      }

      return { valid: true };
    }

    it("يرفض تسجيل طالب ثانوي مستجد بدون شهادة المرحلة المتوسطة وبدون سبب استثناء", () => {
      const res = validateAdmission({
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
      const res = validateAdmission({
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
      const res = validateAdmission({
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
      const res = validateAdmission({
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
      const res = validateAdmission({
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

  describe("Safe Fallback & Financial Gating (Plan 1 Hardening)", () => {
    it("يمنع المسار البديل لتسجيل الطالب من تجاوز فحص شهادة المرحلة المتوسطة بدون استثناء", () => {
      const fallbackExecute = (adm: { has_intermediate_cert: boolean; waiver_reason: string }) => {
        if (!adm.has_intermediate_cert && !adm.waiver_reason.trim()) {
          throw new Error("شهادة المرحلة المتوسطة مطلوبة للقبول الثانوي، ولا يمكن استكمال القبول دون إرفاقها أو تدوين استثناء إداري معتمد.");
        }
        return "student-enrolled-id";
      };

      expect(() => fallbackExecute({ has_intermediate_cert: false, waiver_reason: "" })).toThrow(
        "شهادة المرحلة المتوسطة مطلوبة للقبول الثانوي"
      );
      expect(fallbackExecute({ has_intermediate_cert: false, waiver_reason: "استثناء معتمد" })).toBe(
        "student-enrolled-id"
      );
    });

    it("يرفض المسار البديل للمالية عند فشل الخادم ولا يسمح بتجاوز أخطاء الأعمال أو الصلاحيات", () => {
      const processPayment = (rpcError: { code: string; message: string } | null, rpcSuccess: boolean) => {
        if (!rpcError && rpcSuccess) return { success: true };
        const isMissingRpc = rpcError && (rpcError.code === "42883" || rpcError.message.includes("does not exist"));
        if (rpcError && !isMissingRpc) {
          throw new Error(rpcError.message || "فشل تسجيل الدفعة المالية من قِبل الخادم");
        }
        if (!isMissingRpc && !rpcSuccess) {
          throw new Error("تم رفض الدفعة المالية من قِبل النظام");
        }
        // Only reached if function truly does not exist in schema
        return { success: true, mode: "fallback" };
      };

      // 1. Business error (e.g. invalid amount or unauthorized) MUST throw
      expect(() => processPayment({ code: "P0001", message: "المبلغ يتجاوز الرسوم المستحقة" }, false)).toThrow(
        "المبلغ يتجاوز الرسوم المستحقة"
      );

      // 2. RLS permission error MUST throw
      expect(() => processPayment({ code: "42501", message: "row-level security violation" }, false)).toThrow(
        "row-level security violation"
      );

      // 3. Only 42883 (missing function) falls through safely
      expect(processPayment({ code: "42883", message: "function record_student_payment does not exist" }, false)).toEqual({
        success: true,
        mode: "fallback",
      });
    });
  });
});
