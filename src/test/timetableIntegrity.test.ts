import { describe, it, expect } from "vitest";
import { validateTimetableSchedule } from "@/lib/timetable";
import type { TimetableSlot } from "@/lib/timetable";

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
