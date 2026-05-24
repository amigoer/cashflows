import { useQuery } from '@tanstack/react-query';

import { listRepaymentsInRange, listSalariesInRange, summarizeMonth } from '@/db/queries';
import { endOfMonth, startOfMonth } from '@/lib/date';

export const dashboardKeys = {
  all: ['summary'] as const,
  month: (yearMonthKey: string) => [...dashboardKeys.all, 'month', yearMonthKey] as const,
  monthRepayments: (yearMonthKey: string) => ['repayments', 'month', yearMonthKey] as const,
  monthSalaries: (yearMonthKey: string) => ['salaries', 'month', yearMonthKey] as const,
};

function ymKey(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
}

export function useMonthSummary(reference: Date) {
  const key = ymKey(reference);
  const start = startOfMonth(reference).getTime();
  const end = endOfMonth(reference).getTime() + 1;
  return useQuery({
    queryKey: dashboardKeys.month(key),
    queryFn: () => summarizeMonth(start, end),
  });
}

export function useMonthRepayments(reference: Date) {
  const key = ymKey(reference);
  const start = startOfMonth(reference).getTime();
  const end = endOfMonth(reference).getTime() + 1;
  return useQuery({
    queryKey: dashboardKeys.monthRepayments(key),
    queryFn: () => listRepaymentsInRange(start, end),
  });
}

export function useMonthSalaries(reference: Date) {
  const key = ymKey(reference);
  const start = startOfMonth(reference).getTime();
  const end = endOfMonth(reference).getTime() + 1;
  return useQuery({
    queryKey: dashboardKeys.monthSalaries(key),
    queryFn: () => listSalariesInRange(start, end),
  });
}
