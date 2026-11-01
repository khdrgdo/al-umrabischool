import { describe, it, expect } from "vitest";
import { verifyGuardianStudentAccess } from "@/lib/guardianAuth";

describe("Suite 5: Guardian Data Isolation & IDOR/BOLA Protection", () => {
  const sampleLinks = [
    { guardianId: "guard-1", studentId: "std-1" },
    { guardianId: "guard-1", studentId: "std-2" },
    { guardianId: "guard-2", studentId: "std-3" },
    { guardianId: "guard-4", studentId: "std-5" },
  ];

  it("authorizes access when guardian is verifiably linked to requested student", () => {
    const res = verifyGuardianStudentAccess("guard-1", "std-1", sampleLinks);
    expect(res.authorized).toBe(true);
    expect(res.error).toBeUndefined();

    const resChild2 = verifyGuardianStudentAccess("guard-1", "std-2", sampleLinks);
    expect(resChild2.authorized).toBe(true);
  });

  it("prevents IDOR: strictly blocks guardian from accessing unlinked students", () => {
    // Guardian 2 attempts to access Student 1
    const res = verifyGuardianStudentAccess("guard-2", "std-1", sampleLinks);
    expect(res.authorized).toBe(false);
    expect(res.error).toContain("غير مصرح: لا يملك ولي الأمر صلاحية الوصول لبيانات هذا الطالب");
  });

  it("blocks requests with unknown guardian IDs", () => {
    const res = verifyGuardianStudentAccess("guard-intruder", "std-1", sampleLinks);
    expect(res.authorized).toBe(false);
    expect(res.error).toContain("غير مصرح");
  });
});
