import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  archiveDebtPlan,
  createDebtPlanWithSchedule,
  deleteDebtPlan,
  getDebtPlan,
  listDebtPlans,
  listRepaymentsForPlan,
  markRepayment,
  summarizeDebtPlans,
  updateDebtPlan,
} from '@/db/queries';
import type { NewDebtPlan } from '@/db/schema';

export const debtKeys = {
  all: ['debt-plans'] as const,
  list: (includeArchived = false) => [...debtKeys.all, 'list', { includeArchived }] as const,
  detail: (id: number) => [...debtKeys.all, 'detail', id] as const,
  summary: () => [...debtKeys.all, 'summary'] as const,
  repayments: (planId: number) => ['repayments', 'by-plan', planId] as const,
};

export function useDebtPlans(includeArchived = false) {
  return useQuery({
    queryKey: debtKeys.list(includeArchived),
    queryFn: () => listDebtPlans(includeArchived),
  });
}

export function useDebtPlan(id: number | null) {
  return useQuery({
    queryKey: id ? debtKeys.detail(id) : ['debt-plans', 'detail', 'none'],
    queryFn: () => (id ? getDebtPlan(id) : Promise.resolve(null)),
    enabled: id != null,
  });
}

export function useDebtPlansSummary() {
  return useQuery({
    queryKey: debtKeys.summary(),
    queryFn: summarizeDebtPlans,
  });
}

export function useRepaymentsForPlan(planId: number | null) {
  return useQuery({
    queryKey: planId ? debtKeys.repayments(planId) : ['repayments', 'by-plan', 'none'],
    queryFn: () => (planId ? listRepaymentsForPlan(planId) : Promise.resolve([])),
    enabled: planId != null,
  });
}

export function useCreateDebtPlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: NewDebtPlan) => createDebtPlanWithSchedule(input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['debt-plans'] });
      qc.invalidateQueries({ queryKey: ['repayments'] });
      qc.invalidateQueries({ queryKey: ['summary'] });
    },
  });
}

export function useUpdateDebtPlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, patch }: { id: number; patch: Partial<NewDebtPlan> }) =>
      updateDebtPlan(id, patch),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['debt-plans'] });
    },
  });
}

export function useArchiveDebtPlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, archived }: { id: number; archived: boolean }) => archiveDebtPlan(id, archived),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['debt-plans'] });
      qc.invalidateQueries({ queryKey: ['summary'] });
    },
  });
}

export function useDeleteDebtPlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => deleteDebtPlan(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['debt-plans'] });
      qc.invalidateQueries({ queryKey: ['repayments'] });
      qc.invalidateQueries({ queryKey: ['summary'] });
    },
  });
}

export function useMarkRepayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, paid }: { id: number; paid: boolean }) => markRepayment(id, paid),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['repayments'] });
      qc.invalidateQueries({ queryKey: ['debt-plans'] });
      qc.invalidateQueries({ queryKey: ['summary'] });
    },
  });
}
