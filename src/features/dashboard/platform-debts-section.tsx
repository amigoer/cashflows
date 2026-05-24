import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, View } from 'react-native';

import { AmountText } from '@/components/amount-text';
import { GlassCard } from '@/components/glass-card';
import { ThemedText } from '@/components/themed-text';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import type { DebtPlanSummary } from '@/db/queries';

export type PlatformDebtsSectionProps = {
  summaries: DebtPlanSummary[];
};

export function PlatformDebtsSection({ summaries }: PlatformDebtsSectionProps) {
  const { t } = useTranslation();
  const router = useRouter();
  const theme = useTheme();

  if (summaries.length === 0) return null;

  const totalRemaining = summaries.reduce((s, x) => s + x.remainingCents, 0);

  return (
    <View style={styles.container}>
      <View style={styles.headerRow}>
        <ThemedText type="smallBold" themeColor="textSecondary" style={styles.header}>
          {t('dashboard.platformDebts')}
        </ThemedText>
        <AmountText cents={totalRemaining} tone="expense" size="md" />
      </View>

      <GlassCard padding="two" radius="lg">
        {summaries.map((s, idx) => (
          <Pressable
            key={s.planId}
            onPress={() => router.push(`/debts/${s.planId}`)}
            style={({ pressed }) => [
              styles.platformRow,
              idx !== summaries.length - 1 && {
                borderBottomWidth: StyleSheet.hairlineWidth,
                borderBottomColor: theme.divider,
              },
              pressed && { opacity: 0.7 },
            ]}
          >
            <View style={{ flex: 1 }}>
              <ThemedText type="default">{s.platform}</ThemedText>
              <ThemedText type="small" themeColor="textMuted">
                {s.paidPeriods}/{s.totalPeriods} 期已还
              </ThemedText>
            </View>
            <AmountText cents={s.remainingCents} tone="neutral" size="md" />
          </Pressable>
        ))}
      </GlassCard>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: Spacing.two,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.one,
  },
  header: {
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  platformRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.two,
    paddingVertical: Spacing.two,
    gap: Spacing.two,
  },
});
