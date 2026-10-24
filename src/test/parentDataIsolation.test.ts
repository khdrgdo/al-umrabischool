import { describe, it, expect } from "vitest";

// Guardian to Student relationship isolation and IDOR prevention
interface GuardianStudentLink {
  guardianId: string;
  studentId: string;
  relation: string;
  canViewFees: boolean;
}

interface StudentRecord {
  id: string;
  studentNumber: string;
  fullName: string;
  gradeName: string;
}

const DATABASE_STUDENTS: Record<string, StudentRecord> = {
  "std-1": { id: "std-1", studentNumber: "STD-2026-001", fullName: "محمد عبد الله أحمد", gradeName: "الصف الأول الثانوي" },
  "std-2": { id: "std-2", studentNumber: "STD-2026-002", fullName: "فاطمة عبد الله أحمد", gradeName: "الصف الثالث الثانوي" },
  "std-3": { id: "std-3", studentNumber: "STD-2026-003", fullName: "عمر عثمان علي", gradeName: "الصف الأول الثانوي" },
  "std-5": { id: "std-5", studentNumber: "STD-2026-005", fullName: "أحمد إبراهيم خالد", gradeName: "الصف الثالث الثانوي" },
};

const GUARDIAN_STUDENT_LINKS: GuardianStudentLink[] = [
  { guardianId: "guard-1", studentId: "std-1", relation: "father", canViewFees: true },
  { guardianId: "guard-1", studentId: "std-2", relation: "father", canViewFees: true },
  { guardianId: "guard-2", studentId: "std-3", relation: "father", canViewFees: true },
  { guardianId: "guard-4", studentId: "std-5", relation: "father", canViewFees: true },
];

function getLinkedStudentsForGuardian(authenticatedGuardianId: string): StudentRecord[] {
  const allowedStudentIds = GUARDIAN_STUDENT_LINKS
    .filter((link) => link.guardianId === authenticatedGuardianId)
    .map((link) => link.studentId);

  return allowedStudentIds.map((id) => DATABASE_STUDENTS[id]).filter(Boolean);
}

function getStudentDetailsForGuardian(
  authenticatedGuardianId: string,
  requestedStudentId: string
): { authorized: boolean; student?: StudentRecord; error?: string } {
  const isLinked = GUARDIAN_STUDENT_LINKS.some(
    (link) => link.guardianId === authenticatedGuardianId && link.studentId === requestedStudentId
  );

  if (!isLinked) {
    return {
      authorized: false,
      error: "غير مصرح: لا يملك ولي الأمر صلاحية الوصول لبيانات هذا الطالب",
    };
  }

  return {
    authorized: true,
    student: DATABASE_STUDENTS[requestedStudentId],
  };
}

describe("Suite 5: Guardian Data Isolation & IDOR/BOLA Protection", () => {
  it("isolates multi-child family records strictly to linked children", () => {
    const children = getLinkedStudentsForGuardian("guard-1");
    expect(children).toHaveLength(2);
    expect(children.map((c) => c.id)).toEqual(["std-1", "std-2"]);
  });

  it("isolates single-child family records without cross-leakage", () => {
    const children = getLinkedStudentsForGuardian("guard-2");
    expect(children).toHaveLength(1);
    expect(children[0].id).toBe("std-3");
    expect(children[0].fullName).toBe("عمر عثمان علي");
  });

  it("returns empty list for guardian with no linked students", () => {
    const children = getLinkedStudentsForGuardian("guard-unknown");
    expect(children).toHaveLength(0);
  });

  it("prevents IDOR: blocks guardian from directly fetching unlinked student records", () => {
    // Guardian 2 attempts to directly access Student 1 (Dr. Abdallah's son)
    const result = getStudentDetailsForGuardian("guard-2", "std-1");
    expect(result.authorized).toBe(false);
    expect(result.student).toBeUndefined();
    expect(result.error).toContain("غير مصرح");
  });

  it("allows access when guardian is verifiably linked to requested student", () => {
    const result = getStudentDetailsForGuardian("guard-1", "std-2");
    expect(result.authorized).toBe(true);
    expect(result.student?.fullName).toBe("فاطمة عبد الله أحمد");
  });
});
