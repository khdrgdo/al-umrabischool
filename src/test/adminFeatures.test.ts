import { describe, expect, it, vi } from "vitest";
import { assignmentChanges, emptyTargets, expectedOptionalTotal, khartoumReportTime, optionalFeeSchema, paidUnassignments, readAll, replaceAnnouncementTargets, reportStatusSchema, targetRows, whatsappSchema } from "@/lib/adminFeatures";

const id = "00000000-0000-4000-8000-000000000001";
describe("admin additions", () => {
  it("accepts international WhatsApp digits from 8 to 15", () => {
    expect(whatsappSchema.parse("249912345678")).toBe("249912345678");
    expect(whatsappSchema.safeParse("12345678").success).toBe(true);
    expect(whatsappSchema.safeParse("123456789012345").success).toBe(true);
    for (const invalid of ["+249912345678", "1234567", "1234567890123456", "abcdefgh"]) expect(whatsappSchema.safeParse(invalid).success).toBe(false);
  });
  it("broadcast has no target rows", () => expect(targetRows(id, emptyTargets())).toEqual([]));
  it("mixed targeting has exactly one non-null target per row and deduplicates", () => {
    const rows = targetRows(id, { grades: [id, id], sections: [id], students: [id] });
    expect(rows).toHaveLength(3);
    expect(rows.every((r) => [r.grade_id, r.section_id, r.student_id].filter(Boolean).length === 1)).toBe(true);
  });
  it("invalid target identifiers are rejected", () => expect(() => targetRows(id, { ...emptyTargets(), students: ["invalid"] })).toThrow());
  it("does not publish if replacing targets fails", async () => {
    const finish = vi.fn(); const hide = vi.fn();
    await expect(replaceAnnouncementTargets({ hide, replace: async () => { throw new Error("network"); }, finish })).rejects.toThrow("network");
    expect(hide).toHaveBeenCalledOnce(); expect(finish).not.toHaveBeenCalled();
  });
  it("publishes only after successful targeting", async () => {
    const order: string[] = [];
    await replaceAnnouncementTargets({ hide: async () => { order.push("hide"); }, replace: async () => { order.push("targets"); }, finish: async () => { order.push("publish"); } });
    expect(order).toEqual(["hide", "targets", "publish"]);
  });
  it("optional fee requires a positive amount and a type", () => {
    const form = { grade_id: id, fee_type_id: id, new_type: "", amount: "125", due_date: "", description: "" };
    expect(optionalFeeSchema.parse(form).amount).toBe(125);
    expect(optionalFeeSchema.safeParse({ ...form, amount: 0 }).success).toBe(false);
    expect(optionalFeeSchema.safeParse({ ...form, fee_type_id: "" }).success).toBe(false);
  });
  it("only assigned students contribute to expected total", () => expect(expectedOptionalTotal(125, 3)).toBe(375));
  it("assignment edits add and remove only the selected difference", () => expect(assignmentChanges(["a", "b"], ["b", "c", "c"])).toEqual({ add: ["c"], remove: ["a"] }));
  it("warns for removed students with payments", () => expect(paidUnassignments(["a", "b"], [{ student_id: "a" }, { student_id: "c" }])).toEqual(["a"]));
  it("accepts only the three report statuses", () => {
    for (const value of ["new", "seen", "resolved"]) expect(reportStatusSchema.safeParse(value).success).toBe(true);
    expect(reportStatusSchema.safeParse("deleted").success).toBe(false);
  });
  it("uses Khartoum time (UTC+2)", () => expect(khartoumReportTime("2026-11-12T19:32:00Z")).toBe(new Intl.DateTimeFormat("ar-SD", { timeZone: "Africa/Khartoum", dateStyle: "short", timeStyle: "short" }).format(new Date("2026-11-12T21:32:00+02:00"))));
  it("paginates past row limits", async () => {
    const read = vi.fn(async (from: number) => ({ data: from === 0 ? Array.from({ length: 500 }, (_, i) => i) : [500], error: null }));
    expect(await readAll(read)).toHaveLength(501); expect(read).toHaveBeenCalledTimes(2);
  });
});