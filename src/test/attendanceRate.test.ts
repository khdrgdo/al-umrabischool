import { describe, it, expect } from "vitest";
import { computeAttendanceSummary } from "@/lib/attendance";
import type { AttendanceRecordInput } from "@/lib/attendance";

describe("Suite 8: Attendance Rate Calculation & Edge Cases", () => {
  it("handles zero sessions edge case: returns null attendanceRate and 'no_data' status", () => {
    const summary = computeAttendanceSummary([]);
    expect(summary.totalSessions).toBe(0);
    expect(summary.attendanceRate).toBeNull();
    expect(summary.statusLevel).toBe("no_data");
  });

  it("handles 100% full attendance (Student 1 & Student 7 scenario)", () => {
    const records: AttendanceRecordInput[] = [
      { date: "2026-10-18", status: "present" },
      { date: "2026-10-19", status: "present" },
      { date: "2026-10-20", status: "present" },
      { date: "2026-10-21", status: "present" },
      { date: "2026-10-22", status: "present" },
    ];
    const summary = computeAttendanceSummary(records);
    expect(summary.totalSessions).toBe(5);
    expect(summary.absentCount).toBe(0);
    expect(summary.attendanceRate).toBe(100);
    expect(summary.statusLevel).toBe("perfect");
  });

  it("handles partial attendance with medical excused absence (Student 2 scenario)", () => {
    const records: AttendanceRecordInput[] = [
      { date: "2026-10-18", status: "present" },
      { date: "2026-10-19", status: "present" },
      { date: "2026-10-20", status: "present" },
      { date: "2026-10-21", status: "absent", reason: "إجازة مرضية معتمدة" },
    ];
    const summary = computeAttendanceSummary(records);
    expect(summary.totalSessions).toBe(4);
    expect(summary.absentCount).toBe(1);
    expect(summary.excusedCount).toBe(1);
    expect(summary.attendanceRate).toBe(75);
    expect(summary.statusLevel).toBe("warning");
  });

  it("handles critical absence below 75% threshold (Student 5 scenario)", () => {
    const records: AttendanceRecordInput[] = [
      { date: "2026-10-18", status: "present" },
      { date: "2026-10-19", status: "absent", reason: null },
      { date: "2026-10-20", status: "absent", reason: null },
      { date: "2026-10-21", status: "absent", reason: null },
    ];
    const summary = computeAttendanceSummary(records);
    expect(summary.totalSessions).toBe(4);
    expect(summary.absentCount).toBe(3);
    expect(summary.attendanceRate).toBe(25);
    expect(summary.statusLevel).toBe("critical");
  });

  it("handles 100% absence edge case correctly returning 0% (never negative or NaN)", () => {
    const records: AttendanceRecordInput[] = [
      { date: "2026-10-20", status: "absent" },
      { date: "2026-10-21", status: "absent" },
    ];
    const summary = computeAttendanceSummary(records);
    expect(summary.attendanceRate).toBe(0);
    expect(summary.statusLevel).toBe("critical");
  });
});
