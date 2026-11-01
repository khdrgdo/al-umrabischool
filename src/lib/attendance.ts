/**
 * Attendance Rate Calculation & Threshold Classification
 * Domain logic for computing attendance summaries and status levels.
 */

export interface AttendanceRecordInput {
  date: string;
  status: "present" | "absent" | "late" | "excused";
  reason?: string | null;
}

export interface AttendanceSummary {
  totalSessions: number;
  presentCount: number;
  absentCount: number;
  excusedCount: number;
  lateCount: number;
  attendanceRate: number | null;
  statusLevel: "perfect" | "good" | "warning" | "critical" | "no_data";
}

export function computeAttendanceSummary(records: AttendanceRecordInput[]): AttendanceSummary {
  const totalSessions = records.length;

  if (totalSessions === 0) {
    return {
      totalSessions: 0,
      presentCount: 0,
      absentCount: 0,
      excusedCount: 0,
      lateCount: 0,
      attendanceRate: null,
      statusLevel: "no_data",
    };
  }

  const presentCount = records.filter((r) => r.status === "present").length;
  const absentCount = records.filter((r) => r.status === "absent").length;
  const excusedCount = records.filter((r) => r.status === "excused" || (r.status === "absent" && !!r.reason)).length;
  const lateCount = records.filter((r) => r.status === "late").length;

  // Rate formula: (total - absent) / total * 100
  const rate = Math.max(0, Math.min(100, Math.round(((totalSessions - absentCount) / totalSessions) * 100)));

  let statusLevel: AttendanceSummary["statusLevel"] = "good";
  if (rate === 100) statusLevel = "perfect";
  else if (rate >= 90) statusLevel = "good";
  else if (rate >= 75) statusLevel = "warning";
  else statusLevel = "critical";

  return {
    totalSessions,
    presentCount,
    absentCount,
    excusedCount,
    lateCount,
    attendanceRate: rate,
    statusLevel,
  };
}
