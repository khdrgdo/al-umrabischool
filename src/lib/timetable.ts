/**
 * Weekly School Timetable Collision & Validation
 * Domain logic for detecting scheduling conflicts in timetable entries.
 */

export type Weekday = "sunday" | "monday" | "tuesday" | "wednesday" | "thursday";

export interface TimetableSlot {
  id: string;
  day: Weekday;
  period: number; // 1 to 7
  sectionId: string;
  teacherId: string;
  subjectId: string;
  roomId?: string;
}

export interface ConflictReport {
  hasConflict: boolean;
  conflicts: Array<{
    type: "teacher_double_booked" | "section_double_booked" | "room_double_booked" | "invalid_period";
    message: string;
    slotIds: string[];
  }>;
}

export const VALID_WEEKDAYS: Weekday[] = ["sunday", "monday", "tuesday", "wednesday", "thursday"];

export function validateTimetableSchedule(slots: TimetableSlot[]): ConflictReport {
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
