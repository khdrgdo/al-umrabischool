import { describe, it, expect } from "vitest";
import { canManage, canFinance } from "@/lib/staff";

describe("صلاحيات الإدارة والمالية (Plan 1 - Role Separation)", () => {
  it("المالك يستطيع الإدارة", () => expect(canManage(["owner"])).toBe(true));
  it("مدير المدرسة يستطيع الإدارة", () => expect(canManage(["principal"])).toBe(true));
  it("المشرف لا يستطيع الإدارة", () => expect(canManage(["supervisor"])).toBe(false));
  it("المحاسب لا يستطيع الإدارة الهيكلية أو تعديل المستخدمين", () => expect(canManage(["accountant"])).toBe(false));
  it("بدون دور لا صلاحية", () => expect(canManage([])).toBe(false));

  it("المالك يستطيع إدارة المالية", () => expect(canFinance(["owner"])).toBe(true));
  it("المدير يستطيع إدارة المالية", () => expect(canFinance(["principal"])).toBe(true));
  it("المحاسب المالي يملك صلاحية إدارة الرسوم والتحصيل", () => expect(canFinance(["accountant"])).toBe(true));
  it("المشرف لا يملك صلاحية إدارة الرسوم", () => expect(canFinance(["supervisor"])).toBe(false));
});
