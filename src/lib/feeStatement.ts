/**
 * Financial Privacy & Fee Statement Calculation
 * Domain logic for computing fee statements with privacy gating.
 */

export interface FeeStatementParams {
  canViewFees: boolean;
  baseAnnualFee: number;
  discounts: Array<{ amount: number; reason: string }>;
  payments: Array<{ amount: number; receiptNumber: string }>;
}

export interface FeeStatementResult {
  hasAccess: boolean;
  statement?: {
    baseAnnualFee: number;
    totalDiscounts: number;
    netDue: number;
    totalPaid: number;
    balance: number;
    paymentCount: number;
  };
}

export function calculateFeeStatement(params: FeeStatementParams): FeeStatementResult {
  if (!params.canViewFees) {
    return { hasAccess: false };
  }

  const totalDiscounts = params.discounts.reduce((sum, d) => sum + (Number(d.amount) || 0), 0);
  const netDue = Math.max(0, params.baseAnnualFee - totalDiscounts);
  const totalPaid = params.payments.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
  const balance = Math.max(0, netDue - totalPaid);

  return {
    hasAccess: true,
    statement: {
      baseAnnualFee: params.baseAnnualFee,
      totalDiscounts,
      netDue,
      totalPaid,
      balance,
      paymentCount: params.payments.length,
    },
  };
}
