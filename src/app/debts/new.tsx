import { useRouter } from 'expo-router';

import { useCreateDebtPlan } from '@/features/debts/hooks';
import { DebtForm } from '@/features/debts/debt-form';

export default function NewDebtScreen() {
  const router = useRouter();
  const createDebt = useCreateDebtPlan();

  return (
    <DebtForm
      submitting={createDebt.isPending}
      onSubmit={async (input) => {
        await createDebt.mutateAsync(input);
        router.back();
      }}
    />
  );
}
