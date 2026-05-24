import { useTranslation } from 'react-i18next';
import { StyleSheet, View } from 'react-native';

import { AmountText } from '@/components/amount-text';
import { GlassCard } from '@/components/glass-card';
import { ThemedText } from '@/components/themed-text';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import type { MonthSummary } from '@/db/queries';

export type SummaryCardsProps = {
  summary: MonthSummary | undefined;
};

export function SummaryCards({ summary }: SummaryCardsProps) {
  const { t } = useTranslation();
  const theme = useTheme();

  const income = summary?.incomeCents ?? 0;
  const repayment = summary?.repaymentCents ?? 0;
  const net = summary?.netCents ?? 0;

  return (
    <View style={styles.container}>
      <GlassCard padding="four" radius="xl">
        <ThemedText type="small" themeColor="textSecondary">
          {t('dashboard.net')}
        </ThemedText>
        <AmountText
          cents={net}
          tone={net >= 0 ? 'income' : 'expense'}
          size="xl"
          signed
        />
        <ThemedText type="small" themeColor="textMuted" style={{ marginTop: Spacing.one }}>
          {summary?.salaryCount ?? 0} 笔工资  ·  {summary?.repaymentCount ?? 0} 笔还款
        </ThemedText>
      </GlassCard>

      <View style={styles.row}>
        <View style={styles.colItem}>
          <GlassCard padding="three" radius="lg">
            <ThemedText type="small" themeColor="textSecondary">
              {t('dashboard.income')}
            </ThemedText>
            <AmountText cents={income} tone="income" size="lg" />
          </GlassCard>
        </View>
        <View style={styles.colItem}>
          <GlassCard padding="three" radius="lg">
            <ThemedText type="small" themeColor="textSecondary">
              {t('dashboard.repayment')}
            </ThemedText>
            <AmountText cents={-repayment} tone="expense" size="lg" />
          </GlassCard>
        </View>
      </View>

      <View
        style={[
          styles.heroBar,
          { backgroundColor: theme.divider },
        ]}
        accessibilityElementsHidden
      >
        {income + repayment > 0 ? (
          <>
            <View
              style={[
                styles.barSegment,
                {
                  backgroundColor: theme.income,
                  flex: income,
                },
              ]}
            />
            <View
              style={[
                styles.barSegment,
                {
                  backgroundColor: theme.expense,
                  flex: repayment,
                },
              ]}
            />
          </>
        ) : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: Spacing.two,
  },
  row: {
    flexDirection: 'row',
    gap: Spacing.two,
  },
  colItem: {
    flex: 1,
  },
  heroBar: {
    height: 6,
    borderRadius: 3,
    overflow: 'hidden',
    flexDirection: 'row',
  },
  barSegment: {
    height: '100%',
  },
});
