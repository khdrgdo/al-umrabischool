import { describe, it, expect } from "vitest";
import { filterGradesForParentPortal } from "@/lib/gradesPrivacy";
import type { AssessmentGradeRecord } from "@/lib/gradesPrivacy";

describe("Suite 7: Academic Grades Publication Gating & Evaluation", () => {
  const mixedGrades: AssessmentGradeRecord[] = [
    {
      id: "g-1",
      subjectName: "الرياضيات",
      examTitle: "امتحان منتصف الفصل",
      score: 96,
      maxScore: 100,
      passScore: 50,
      isAbsent: false,
      status: "published",
    },
    {
      id: "g-2",
      subjectName: "الكيمياء",
      examTitle: "اختبار دوري لشهر أكتوبر",
      score: 42,
      maxScore: 50,
      passScore: 25,
      isAbsent: false,
      status: "approved", // NOT published yet
    },
    {
      id: "g-3",
      subjectName: "الفيزياء",
      examTitle: "امتحان تجريبي معملي",
      score: 30,
      maxScore: 50,
      passScore: 25,
      isAbsent: false,
      status: "draft", // NOT published
    },
    {
      id: "g-4",
      subjectName: "اللغة العربية",
      examTitle: "امتحان منتصف الفصل",
      score: 49, // Borderline fail (1 mark below passScore 50)
      maxScore: 100,
      passScore: 50,
      isAbsent: false,
      status: "published",
    },
    {
      id: "g-5",
      subjectName: "اللغة الإنجليزية",
      examTitle: "امتحان منتصف الفصل",
      score: null,
      maxScore: 100,
      passScore: 50,
      isAbsent: true,
      status: "published",
    },
  ];

  it("strictly filters out draft, reviewing, or approved (non-published) assessments", () => {
    const parentView = filterGradesForParentPortal(mixedGrades);
    const ids = parentView.map((g) => g.id);

    expect(ids).toContain("g-1");
    expect(ids).toContain("g-4");
    expect(ids).toContain("g-5");

    // Hidden grades must NEVER reach parent portal
    expect(ids).not.toContain("g-2");
    expect(ids).not.toContain("g-3");
    expect(parentView).toHaveLength(3);
  });

  it("correctly identifies high academic achievement", () => {
    const parentView = filterGradesForParentPortal(mixedGrades);
    const math = parentView.find((g) => g.id === "g-1");

    expect(math?.scoreDisplay).toBe("96 / 100");
    expect(math?.percentage).toBe(96);
    expect(math?.isPassing).toBe(true);
    expect(math?.requiresRemediation).toBe(false);
  });

  it("detects borderline failure (49/100) and flags need for academic remediation", () => {
    const parentView = filterGradesForParentPortal(mixedGrades);
    const arabic = parentView.find((g) => g.id === "g-4");

    expect(arabic?.scoreDisplay).toBe("49 / 100");
    expect(arabic?.isPassing).toBe(false);
    expect(arabic?.requiresRemediation).toBe(true);
  });

  it("handles student absence from examination gracefully", () => {
    const parentView = filterGradesForParentPortal(mixedGrades);
    const english = parentView.find((g) => g.id === "g-5");

    expect(english?.scoreDisplay).toBe("غائب");
    expect(english?.isAbsent).toBe(true);
    expect(english?.isPassing).toBe(false);
    expect(english?.requiresRemediation).toBe(true);
  });
});
