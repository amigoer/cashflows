import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';

import { CurrencyInput } from '@/components/form/currency-input';
import { DateField } from '@/components/form/date-field';
import { LabeledField } from '@/components/form/labeled-field';
import { NoteInput } from '@/components/form/note-input';
import { TextInputField } from '@/components/form/text-input-field';
import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import type { DebtPlan, NewDebtPlan } from '@/db/schema';

export type DebtFormValues = {
  platform: string;
  principalCents: number | null;
  totalPeriods: string;
  monthlyPaymentCents: number | null;
  firstDueDate: Date;
  aprText: string;
  note: string;
};

export type DebtFormProps = {
  initialValue?: DebtPlan;
  submitting?: boolean;
  showDelete?: boolean;
  onSubmit: (input: NewDebtPlan) => Promise<void> | void;
  onDelete?: () => Promise<void> | void;
};

function toValues(plan?: DebtPlan): DebtFormValues {
  return {
    platform: plan?.platform ?? '',
    principalCents: plan?.principalCents ?? null,
    totalPeriods: plan ? String(plan.totalPeriods) : '',
    monthlyPaymentCents: plan?.monthlyPaymentCents ?? null,
    firstDueDate: plan ? new Date(plan.firstDueDate) : new Date(),
    aprText: plan?.aprBps ? (plan.aprBps / 100).toFixed(2) : '',
    note: plan?.note ?? '',
  };
}

export function DebtForm({
  initialValue,
  submitting,
  showDelete,
  onSubmit,
  onDelete,
}: DebtFormProps) {
  const { t } = useTranslation();
  const theme = useTheme();
  const [values, setValues] = useState<DebtFormValues>(() => toValues(initialValue));
  const [errors, setErrors] = useState<Partial<Record<keyof DebtFormValues, string>>>({});

  const handleSubmit = async () => {
    const next: typeof errors = {};
    if (values.platform.trim().length === 0) next.platform = t('common.required');
    if (values.principalCents == null || values.principalCents <= 0)
      next.principalCents = t('amount.invalid');
    const periods = Number(values.totalPeriods);
    if (!Number.isInteger(periods) || periods <= 0) next.totalPeriods = t('common.required');
    if (values.monthlyPaymentCents == null || values.monthlyPaymentCents <= 0)
      next.monthlyPaymentCents = t('amount.invalid');
    setErrors(next);
    if (Object.keys(next).length > 0) return;

    const aprBps = (() => {
      const trimmed = values.aprText.trim();
      if (trimmed === '') return 0;
      const num = Number(trimmed);
      if (!Number.isFinite(num)) return 0;
      return Math.round(num * 100);
    })();

    await onSubmit({
      platform: values.platform.trim(),
      principalCents: values.principalCents!,
      totalPeriods: periods,
      monthlyPaymentCents: values.monthlyPaymentCents!,
      firstDueDate: values.firstDueDate.getTime(),
      aprBps,
      note: values.note.trim() ? values.note.trim() : null,
    });
  };

  const handleDelete = () => {
    if (!onDelete) return;
    Alert.alert(t('debts.deleteConfirm'), undefined, [
      { text: t('common.cancel'), style: 'cancel' },
      { text: t('common.delete'), style: 'destructive', onPress: () => void onDelete() },
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
        <LabeledField label={t('debts.platform')} error={errors.platform}>
          <TextInputField
            value={values.platform}
            onChangeText={(text) => setValues((v) => ({ ...v, platform: text }))}
            placeholder={t('debts.platformPlaceholder')}
            autoFocus={!initialValue}
          />
        </LabeledField>

        <LabeledField label={t('debts.principal')} error={errors.principalCents}>
          <CurrencyInput
            valueCents={values.principalCents}
            onChange={(cents) => setValues((v) => ({ ...v, principalCents: cents }))}
          />
        </LabeledField>

        <View style={styles.twoCol}>
          <View style={styles.colItem}>
            <LabeledField label={t('debts.totalPeriods')} error={errors.totalPeriods}>
              <TextInputField
                value={values.totalPeriods}
                onChangeText={(text) =>
                  setValues((v) => ({ ...v, totalPeriods: text.replace(/[^0-9]/g, '') }))
                }
                keyboardType="number-pad"
                placeholder="12"
              />
            </LabeledField>
          </View>
          <View style={styles.colItem}>
            <LabeledField label={t('debts.monthlyPayment')} error={errors.monthlyPaymentCents}>
              <CurrencyInput
                valueCents={values.monthlyPaymentCents}
                onChange={(cents) => setValues((v) => ({ ...v, monthlyPaymentCents: cents }))}
              />
            </LabeledField>
          </View>
        </View>

        <LabeledField label={t('debts.firstDueDate')}>
          <DateField
            value={values.firstDueDate}
            onChange={(d) => setValues((v) => ({ ...v, firstDueDate: d }))}
          />
        </LabeledField>

        <LabeledField label={t('debts.apr')} hint={t('debts.aprPlaceholder')}>
          <TextInputField
            value={values.aprText}
            onChangeText={(text) => setValues((v) => ({ ...v, aprText: text }))}
            keyboardType="decimal-pad"
            placeholder="0"
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

        {showDelete && onDelete && (
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
  twoCol: {
    flexDirection: 'row',
    gap: Spacing.three,
  },
  colItem: {
    flex: 1,
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
