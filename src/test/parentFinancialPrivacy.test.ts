import { describe, it, expect } from "vitest";
import { calculateFeeStatement } from "@/lib/feeStatement";

describe("Suite 6: Financial Privacy & Fee Statement Calculation", () => {
  it("strictly suppresses financial data when can_view_fees is false", () => {
    const result = calculateFeeStatement({
      canViewFees: false,
      baseAnnualFee: 300000,
      discounts: [{ amount: 50000, reason: "خصم إخوة" }],
      payments: [{ amount: 250000, receiptNumber: "REC-001" }],
    });

    expect(result.hasAccess).toBe(false);
    expect(result.statement).toBeUndefined();
  });

  it("calculates exact balance for fully paid student (Student 1 scenario)", () => {
    const result = calculateFeeStatement({
      canViewFees: true,
      baseAnnualFee: 300000,
      discounts: [],
      payments: [{ amount: 300000, receiptNumber: "REC-2026-001" }],
    });

    expect(result.hasAccess).toBe(true);
    expect(result.statement?.netDue).toBe(300000);
    expect(result.statement?.totalPaid).toBe(300000);
    expect(result.statement?.balance).toBe(0);
  });

  it("calculates partial payment balance correctly (Student 2 scenario)", () => {
    const result = calculateFeeStatement({
      canViewFees: true,
      baseAnnualFee: 350000,
      discounts: [],
      payments: [{ amount: 150000, receiptNumber: "REC-2026-002" }],
    });

    expect(result.hasAccess).toBe(true);
    expect(result.statement?.netDue).toBe(350000);
    expect(result.statement?.totalPaid).toBe(150000);
    expect(result.statement?.balance).toBe(200000);
  });

  it("handles 100% full scholarship waiver with zero remaining balance (Student 3 scenario)", () => {
    const result = calculateFeeStatement({
      canViewFees: true,
      baseAnnualFee: 300000,
      discounts: [{ amount: 300000, reason: "كفالة أيتام كاملة" }],
      payments: [],
    });

    expect(result.hasAccess).toBe(true);
    expect(result.statement?.totalDiscounts).toBe(300000);
    expect(result.statement?.netDue).toBe(0);
    expect(result.statement?.balance).toBe(0);
  });

  it("prevents negative balance on overpayment edge case", () => {
    const result = calculateFeeStatement({
      canViewFees: true,
      baseAnnualFee: 200000,
      discounts: [],
      payments: [{ amount: 250000, receiptNumber: "REC-OVERPAY" }],
    });

    expect(result.statement?.balance).toBe(0);
  });
});
