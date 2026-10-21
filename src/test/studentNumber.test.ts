import { describe, it, expect } from "vitest";
import { matchesStudentNumber } from "@/lib/studentNumber";

describe("student number search", () => {
  it("finds new OMR numbers regardless of letter case", () => {
    expect(matchesStudentNumber("OMR-000012", "omr-0000")).toBe(true);
  });
  it("still finds old numeric numbers", () => {
    expect(matchesStudentNumber("241186", "2411")).toBe(true);
    expect(matchesStudentNumber("241186", "OMR")).toBe(false);
  });
});
