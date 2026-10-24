import { describe, it, expect } from "vitest";

// Weekly School Timetable Collision & Validation Specification
type Weekday = "sunday" | "monday" | "tuesday" | "wednesday" | "thursday";

interface TimetableSlot {
  id: string;
  day: Weekday;
  period: number; // 1 to 7
  sectionId: string;
  teacherId: string;
  subjectId: string;
  roomId?: string;
}

interface ConflictReport {
  hasConflict: boolean;
  conflicts: Array<{
    type: "teacher_double_booked" | "section_double_booked" | "room_double_booked" | "invalid_period";
    message: string;
    slotIds: string[];
  }>;
}

const VALID_WEEKDAYS: Weekday[] = ["sunday", "monday", "tuesday", "wednesday", "thursday"];

function validateTimetableSchedule(slots: TimetableSlot[]): ConflictReport {
  const conflicts: ConflictReport["conflicts"] = [];

  // 1. Period bounds check (1 to 7)
  for (const slot of slots) {
    if (slot.period < 1 || slot.period > 7) {
      conflicts.push({
        type: "invalid_period",
        message: `الحصة رقم ${slot.period} خارج النطاق المدرسي المعتمد (1-7)`,
        slotIds: [slot.id],
      });
    }
  }

  // 2. Collision checks
  for (let i = 0; i < slots.length; i++) {
    for (let j = i + 1; j < slots.length; j++) {
      const a = slots[i];
      const b = slots[j];
      if (!a || !b) continue;

      // Only check slots occurring on the same day and period
      if (a.day !== b.day || a.period !== b.period) continue;

      // Teacher double-booked
      if (a.teacherId === b.teacherId) {
        conflicts.push({
          type: "teacher_double_booked",
          message: `تعارض: المعلم مسند لشعبتين مختلفتين في نفس الحصة (${a.day} - الحصة ${a.period})`,
          slotIds: [a.id, b.id],
        });
      }

      // Section double-booked
      if (a.sectionId === b.sectionId) {
        conflicts.push({
          type: "section_double_booked",
          message: `تعارض: الشعبة مسند لها مادتان في نفس الحصة (${a.day} - الحصة ${a.period})`,
          slotIds: [a.id, b.id],
        });
      }

      // Room double-booked
      if (a.roomId && b.roomId && a.roomId === b.roomId) {
        conflicts.push({
          type: "room_double_booked",
          message: `تعارض: القاعة الدراسية محجوزة لصفين في نفس التوقيت`,
          slotIds: [a.id, b.id],
        });
      }
    }
  }

  return {
    hasConflict: conflicts.length > 0,
    conflicts,
  };
}

describe("Suite 9: Timetable Integrity & Collision Detection", () => {
  it("approves a clean schedule without any teacher or section collisions", () => {
    const validSlots: TimetableSlot[] = [
      { id: "s-1", day: "sunday", period: 1, sectionId: "sec-1a", teacherId: "t-math", subjectId: "sub-math" },
      { id: "s-2", day: "sunday", period: 1, sectionId: "sec-1b", teacherId: "t-arab", subjectId: "sub-arab" },
      { id: "s-3", day: "sunday", period: 2, sectionId: "sec-1a", teacherId: "t-arab", subjectId: "sub-arab" },
    ];

    const report = validateTimetableSchedule(validSlots);
    expect(report.hasConflict).toBe(false);
    expect(report.conflicts).toHaveLength(0);
  });

  it("detects teacher double-booking collision across different sections", () => {
    const invalidSlots: TimetableSlot[] = [
      { id: "slot-a", day: "monday", period: 3, sectionId: "sec-1a", teacherId: "t-phys", subjectId: "sub-phys" },
      { id: "slot-b", day: "monday", period: 3, sectionId: "sec-2a", teacherId: "t-phys", subjectId: "sub-phys" },
    ];

    const report = validateTimetableSchedule(invalidSlots);
    expect(report.hasConflict).toBe(true);
    expect(report.conflicts[0]?.type).toBe("teacher_double_booked");
    expect(report.conflicts[0]?.slotIds).toEqual(["slot-a", "slot-b"]);
  });

  it("detects section double-booking collision (two subjects for one section at the same time)", () => {
    const invalidSlots: TimetableSlot[] = [
      { id: "slot-c", day: "tuesday", period: 2, sectionId: "sec-1a", teacherId: "t-chem", subjectId: "sub-chem" },
      { id: "slot-d", day: "tuesday", period: 2, sectionId: "sec-1a", teacherId: "t-eng", subjectId: "sub-eng" },
    ];

    const report = validateTimetableSchedule(invalidSlots);
    expect(report.hasConflict).toBe(true);
    expect(report.conflicts[0]?.type).toBe("section_double_booked");
  });

  it("flags invalid period index outside the 1 to 7 range", () => {
    const outOfBoundsSlot: TimetableSlot[] = [
      { id: "slot-e", day: "wednesday", period: 8, sectionId: "sec-1a", teacherId: "t-math", subjectId: "sub-math" },
    ];

    const report = validateTimetableSchedule(outOfBoundsSlot);
    expect(report.hasConflict).toBe(true);
    expect(report.conflicts[0]?.type).toBe("invalid_period");
  });
});
