import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, View } from 'react-native';

import { AmountText } from '@/components/amount-text';
import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import type { Repayment } from '@/db/schema';
import { formatLongDate, isToday } from '@/lib/date';

export type RepaymentRowProps = {
  repayment: Repayment;
  onToggle: () => void;
};

export function RepaymentRow({ repayment, onToggle }: RepaymentRowProps) {
  const { t } = useTranslation();
  const theme = useTheme();

  const paid = repayment.status === 'paid';
  const overdue = !paid && repayment.dueDate < Date.now() && !isToday(repayment.dueDate);

  const statusColor = paid ? theme.income : overdue ? theme.expense : theme.textSecondary;

  return (
    <View
      style={[
        styles.row,
        {
          backgroundColor: theme.backgroundElement,
          borderColor: theme.cardBorder,
        },
      ]}
    >
      <View style={styles.left}>
        <ThemedText type="default">
          第 {repayment.periodIndex} 期 · {formatLongDate(repayment.dueDate)}
        </ThemedText>
        <ThemedText type="small" style={{ color: statusColor }}>
          {paid ? `已还于 ${formatLongDate(repayment.paidAt ?? repayment.dueDate)}` : overdue ? '已逾期' : '待还款'}
        </ThemedText>
      </View>

      <View style={styles.right}>
        <AmountText cents={repayment.amountCents} tone="neutral" size="md" />
        <Pressable
          onPress={onToggle}
          style={({ pressed }) => [
            styles.toggle,
            {
              backgroundColor: paid ? theme.incomeMuted : theme.accentMuted,
            },
            pressed && { opacity: 0.7 },
          ]}
        >
          <ThemedText type="small" style={{ color: paid ? theme.income : theme.accent }}>
            {paid ? t('debts.unmarkPaid') : t('debts.markPaid')}
          </ThemedText>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.two,
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
  },
  left: {
    flex: 1,
    gap: 2,
  },
  right: {
    alignItems: 'flex-end',
    gap: Spacing.one,
  },
  toggle: {
    paddingHorizontal: Spacing.two,
    paddingVertical: 4,
    borderRadius: Radius.pill,
  },
});
