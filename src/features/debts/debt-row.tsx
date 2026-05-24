import { useTranslation } from 'react-i18next';
import { Pressable, StyleSheet, View } from 'react-native';

import { AmountText } from '@/components/amount-text';
import { GlassCard } from '@/components/glass-card';
import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import type { DebtPlanSummary } from '@/db/queries';
import type { DebtPlan } from '@/db/schema';

export type DebtRowProps = {
  plan: DebtPlan;
  summary?: DebtPlanSummary;
  onPress: () => void;
};

export function DebtRow({ plan, summary, onPress }: DebtRowProps) {
  const { t } = useTranslation();
  const theme = useTheme();

  const paidPeriods = summary?.paidPeriods ?? 0;
  const totalPeriods = summary?.totalPeriods ?? plan.totalPeriods;
  const remainingCents = summary?.remainingCents ?? 0;
  const progress = totalPeriods === 0 ? 0 : paidPeriods / totalPeriods;

  return (
    <Pressable onPress={onPress} style={({ pressed }) => pressed && { opacity: 0.7 }}>
      <GlassCard padding="three" radius="lg">
        <View style={styles.headerRow}>
          <ThemedText type="default" style={styles.platform}>
            {plan.platform}
          </ThemedText>
          <AmountText cents={remainingCents} tone="neutral" size="md" />
        </View>

        <View style={styles.progressBar}>
          <View
            style={[
              styles.progressFill,
              {
                backgroundColor: theme.accent,
                width: `${Math.min(100, Math.max(0, progress * 100))}%`,
              },
            ]}
          />
        </View>

        <View style={styles.metaRow}>
          <ThemedText type="small" style={{ color: theme.textSecondary }}>
            {t('dashboard.paid')} {paidPeriods}/{totalPeriods} {t('dashboard.periods')}
          </ThemedText>
          <ThemedText type="small" style={{ color: theme.textMuted }}>
            {t('dashboard.remaining')}
          </ThemedText>
        </View>
      </GlassCard>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    marginBottom: Spacing.two,
  },
  platform: {
    fontSize: 17,
    fontWeight: '600',
  },
  progressBar: {
    height: 6,
    borderRadius: Radius.pill,
    backgroundColor: 'rgba(127, 127, 127, 0.15)',
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: Radius.pill,
  },
  metaRow: {
    marginTop: Spacing.two,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
});
