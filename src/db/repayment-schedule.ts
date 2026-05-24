import { addMonths } from 'date-fns';

import type { NewRepayment } from './schema';

export type GenerateScheduleInput = {
  debtPlanId: number;
  totalPeriods: number;
  monthlyPaymentCents: number;
  firstDueDate: Date | number;
};

/**
 * Even-split monthly schedule. The last period absorbs any remainder cents so the
 * total of all amounts equals totalPeriods * monthlyPaymentCents exactly.
 */
export function generateRepaymentSchedule(input: GenerateScheduleInput): Omit<NewRepayment, 'id'>[] {
  const start = typeof input.firstDueDate === 'number' ? new Date(input.firstDueDate) : input.firstDueDate;
  return Array.from({ length: input.totalPeriods }, (_, i) => ({
    debtPlanId: input.debtPlanId,
    periodIndex: i + 1,
    dueDate: addMonths(start, i).getTime(),
    amountCents: input.monthlyPaymentCents,
    status: 'pending' as const,
    paidAt: null,
  }));
}
