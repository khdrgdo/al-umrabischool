import { describe, it, expect } from "vitest";
import { canManage } from "@/lib/staff";

describe("صلاحيات الإدارة", () => {
  it("المالك يستطيع الإدارة", () => expect(canManage(["owner"])).toBe(true));
  it("مدير المدرسة يستطيع الإدارة", () => expect(canManage(["principal"])).toBe(true));
  it("المشرف للقراءة فقط", () => expect(canManage(["supervisor"])).toBe(false));
  it("بدون دور لا صلاحية", () => expect(canManage([])).toBe(false));
});
