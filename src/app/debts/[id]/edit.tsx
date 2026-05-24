import { useLocalSearchParams, useRouter } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';

import { useTheme } from '@/hooks/use-theme';
import {
  useDebtPlan,
  useDeleteDebtPlan,
  useUpdateDebtPlan,
} from '@/features/debts/hooks';
import { DebtForm } from '@/features/debts/debt-form';

export default function EditDebtScreen() {
  const router = useRouter();
  const theme = useTheme();
  const params = useLocalSearchParams<{ id: string }>();
  const id = Number(params.id);

  const { data: plan, isLoading } = useDebtPlan(id);
  const updateDebt = useUpdateDebtPlan();
  const deleteDebt = useDeleteDebtPlan();

  if (isLoading || !plan) {
    return (
      <View
        style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.background }}
      >
        <ActivityIndicator color={theme.accent} />
      </View>
    );
  }

  return (
    <DebtForm
      initialValue={plan}
      submitting={updateDebt.isPending || deleteDebt.isPending}
      showDelete
      onSubmit={async (input) => {
        await updateDebt.mutateAsync({ id, patch: input });
        router.back();
      }}
      onDelete={async () => {
        await deleteDebt.mutateAsync(id);
        router.dismissAll();
        router.replace('/debts');
      }}
    />
  );
}
