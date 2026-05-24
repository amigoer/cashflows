import { useRouter } from 'expo-router';

import { useCreateSalary } from '@/features/salary/hooks';
import { SalaryForm } from '@/features/salary/salary-form';

export default function NewSalaryScreen() {
  const router = useRouter();
  const createSalary = useCreateSalary();

  return (
    <SalaryForm
      submitting={createSalary.isPending}
      onSubmit={async (input) => {
        await createSalary.mutateAsync(input);
        router.back();
      }}
    />
  );
}
