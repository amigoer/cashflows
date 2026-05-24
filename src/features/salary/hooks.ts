import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { createSalary, deleteSalary, listSalaries, updateSalary } from '@/db/queries';
import type { NewSalary } from '@/db/schema';

export const salaryKeys = {
  all: ['salaries'] as const,
  list: () => [...salaryKeys.all, 'list'] as const,
};

export function useSalaries() {
  return useQuery({
    queryKey: salaryKeys.list(),
    queryFn: listSalaries,
  });
}

export function useCreateSalary() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: NewSalary) => createSalary(input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['salaries'] });
      qc.invalidateQueries({ queryKey: ['summary'] });
    },
  });
}

export function useUpdateSalary() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, patch }: { id: number; patch: Partial<NewSalary> }) => updateSalary(id, patch),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['salaries'] });
      qc.invalidateQueries({ queryKey: ['summary'] });
    },
  });
}

export function useDeleteSalary() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => deleteSalary(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['salaries'] });
      qc.invalidateQueries({ queryKey: ['summary'] });
    },
  });
}
