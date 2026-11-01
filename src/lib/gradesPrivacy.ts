/**
 * Academic Grades Privacy & Publication Gating
 * Domain logic for filtering grades visible to parent portal.
 * Only published grades are exposed; draft/reviewing/approved grades are hidden.
 */

export interface AssessmentGradeRecord {
  id: string;
  subjectName: string;
  examTitle: string;
  score: number | null;
  maxScore: number;
  passScore: number;
  isAbsent: boolean;
  status: "draft" | "reviewing" | "approved" | "published";
  notes?: string;
}

export interface ParentGradeView {
  id: string;
  subjectName: string;
  examTitle: string;
  scoreDisplay: string;
  percentage: number | null;
  isPassing: boolean;
  isAbsent: boolean;
  requiresRemediation: boolean;
}

export function filterGradesForParentPortal(grades: AssessmentGradeRecord[]): ParentGradeView[] {
  // Strict institutional rule: filter out anything not explicitly published
  const published = grades.filter((g) => g.status === "published");

  return published.map((g) => {
    if (g.isAbsent) {
      return {
        id: g.id,
        subjectName: g.subjectName,
        examTitle: g.examTitle,
        scoreDisplay: "غائب",
        percentage: null,
        isPassing: false,
        isAbsent: true,
        requiresRemediation: true,
      };
    }

    const score = g.score ?? 0;
    const percentage = Math.round((score / g.maxScore) * 100);
    const isPassing = score >= g.passScore;

    return {
      id: g.id,
      subjectName: g.subjectName,
      examTitle: g.examTitle,
      scoreDisplay: `${score} / ${g.maxScore}`,
      percentage,
      isPassing,
      isAbsent: false,
      requiresRemediation: !isPassing,
    };
  });
}
