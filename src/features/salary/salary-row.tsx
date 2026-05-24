import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, View } from 'react-native';

import { AmountText } from '@/components/amount-text';
import { GlassCard } from '@/components/glass-card';
import { ThemedText } from '@/components/themed-text';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import type { Salary } from '@/db/schema';
import { formatLongDate } from '@/lib/date';

export type SalaryRowProps = {
  salary: Salary;
  onPress: () => void;
};

export function SalaryRow({ salary, onPress }: SalaryRowProps) {
  const { t } = useTranslation();
  const theme = useTheme();

  return (
    <Pressable onPress={onPress} style={({ pressed }) => pressed && { opacity: 0.7 }}>
      <GlassCard padding="three" radius="lg">
        <View style={styles.row}>
          <View style={styles.left}>
            <ThemedText type="default">{formatLongDate(salary.paidAt)}</ThemedText>
            <ThemedText type="small" style={{ color: theme.textSecondary }}>
              {t(`salary.periods.${salary.period}`)}
              {salary.note ? `  ·  ${salary.note}` : ''}
            </ThemedText>
          </View>
          <AmountText cents={salary.amountCents} tone="income" size="lg" signed={false} />
        </View>
      </GlassCard>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: Spacing.three,
  },
  left: {
    flex: 1,
    gap: 2,
  },
});
