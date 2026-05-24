import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Alert, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, View } from 'react-native';

import { CurrencyInput } from '@/components/form/currency-input';
import { DateField } from '@/components/form/date-field';
import { LabeledField } from '@/components/form/labeled-field';
import { NoteInput } from '@/components/form/note-input';
import { SegmentControl } from '@/components/form/segment-control';
import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { SALARY_PERIODS, type NewSalary, type Salary, type SalaryPeriod } from '@/db/schema';

export type SalaryFormValues = {
  amountCents: number | null;
  paidAt: Date;
  period: SalaryPeriod;
  note: string;
};

export type SalaryFormProps = {
  initialValue?: Salary;
  submitting?: boolean;
  onSubmit: (input: NewSalary) => Promise<void> | void;
  onDelete?: () => Promise<void> | void;
};

function toValues(salary?: Salary): SalaryFormValues {
  return {
    amountCents: salary?.amountCents ?? null,
    paidAt: salary ? new Date(salary.paidAt) : new Date(),
    period: (salary?.period as SalaryPeriod | undefined) ?? 'monthly',
    note: salary?.note ?? '',
  };
}

export function SalaryForm({ initialValue, submitting, onSubmit, onDelete }: SalaryFormProps) {
  const { t } = useTranslation();
  const theme = useTheme();
  const [values, setValues] = useState<SalaryFormValues>(() => toValues(initialValue));
  const [error, setError] = useState<string | null>(null);

  const periodOptions = SALARY_PERIODS.map((p) => ({
    value: p,
    label: t(`salary.periods.${p}`),
  }));

  const handleSubmit = async () => {
    if (values.amountCents == null || values.amountCents <= 0) {
      setError(t('amount.invalid'));
      return;
    }
    setError(null);
    await onSubmit({
      amountCents: values.amountCents,
      paidAt: values.paidAt.getTime(),
      period: values.period,
      note: values.note.trim() ? values.note.trim() : null,
    });
  };

  const handleDelete = () => {
    if (!onDelete) return;
    Alert.alert(t('salary.deleteConfirm'), undefined, [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('common.delete'),
        style: 'destructive',
        onPress: () => void onDelete(),
      },
    ]);
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={{ flex: 1 }}
    >
      <ScrollView
        style={{ flex: 1, backgroundColor: theme.background }}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
      >
        <LabeledField label={t('salary.amount')} error={error ?? undefined}>
          <CurrencyInput
            valueCents={values.amountCents}
            onChange={(cents) => setValues((v) => ({ ...v, amountCents: cents }))}
            autoFocus={!initialValue}
          />
        </LabeledField>

        <LabeledField label={t('salary.paidAt')}>
          <DateField
            value={values.paidAt}
            onChange={(d) => setValues((v) => ({ ...v, paidAt: d }))}
          />
        </LabeledField>

        <LabeledField label={t('salary.period')}>
          <SegmentControl
            value={values.period}
            options={periodOptions}
            onChange={(p) => setValues((v) => ({ ...v, period: p }))}
          />
        </LabeledField>

        <LabeledField label={`${t('common.note')}（${t('common.optional')}）`}>
          <NoteInput
            value={values.note}
            onChange={(text) => setValues((v) => ({ ...v, note: text }))}
            placeholder=""
          />
        </LabeledField>

        <Pressable
          onPress={handleSubmit}
          disabled={submitting}
          style={({ pressed }) => [
            styles.primaryButton,
            { backgroundColor: theme.accent },
            (pressed || submitting) && { opacity: 0.75 },
          ]}
        >
          <ThemedText type="default" style={styles.primaryButtonText}>
            {t('common.save')}
          </ThemedText>
        </Pressable>

        {onDelete && (
          <Pressable
            onPress={handleDelete}
            style={({ pressed }) => [
              styles.deleteButton,
              { borderColor: theme.expense },
              pressed && { opacity: 0.75 },
            ]}
          >
            <ThemedText type="default" style={{ color: theme.expense }}>
              {t('common.delete')}
            </ThemedText>
          </Pressable>
        )}

        <View style={{ height: Spacing.five }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  content: {
    padding: Spacing.three,
    gap: Spacing.three,
  },
  primaryButton: {
    marginTop: Spacing.two,
    paddingVertical: Spacing.three,
    borderRadius: Radius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 17,
    fontWeight: '600',
  },
  deleteButton: {
    paddingVertical: Spacing.three,
    borderRadius: Radius.lg,
    borderWidth: StyleSheet.hairlineWidth,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
