import { useLocalSearchParams, useRouter } from 'expo-router';
import { useMemo } from 'react';
import { ActivityIndicator, View } from 'react-native';

import { useTheme } from '@/hooks/use-theme';
import { useDeleteSalary, useSalaries, useUpdateSalary } from '@/features/salary/hooks';
import { SalaryForm } from '@/features/salary/salary-form';

export default function EditSalaryScreen() {
  const router = useRouter();
  const theme = useTheme();
  const params = useLocalSearchParams<{ id: string }>();
  const id = Number(params.id);

  const { data: salaries = [] } = useSalaries();
  const updateSalary = useUpdateSalary();
  const deleteSalary = useDeleteSalary();

  const salary = useMemo(() => salaries.find((s) => s.id === id), [salaries, id]);

  if (!salary) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.background }}>
        <ActivityIndicator color={theme.accent} />
      </View>
    );
  }

  return (
    <SalaryForm
      initialValue={salary}
      submitting={updateSalary.isPending || deleteSalary.isPending}
      onSubmit={async (input) => {
        await updateSalary.mutateAsync({ id, patch: input });
        router.back();
      }}
      onDelete={async () => {
        await deleteSalary.mutateAsync(id);
        router.back();
      }}
    />
  );
}
