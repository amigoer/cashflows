import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { useTranslation } from 'react-i18next';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, View } from 'react-native';

import { AmountText } from '@/components/amount-text';
import { GlassCard } from '@/components/glass-card';
import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import {
  useDebtPlan,
  useDebtPlansSummary,
  useMarkRepayment,
  useRepaymentsForPlan,
} from '@/features/debts/hooks';
import { RepaymentRow } from '@/features/debts/repayment-row';
import { formatLongDate } from '@/lib/date';

export default function DebtDetailScreen() {
  const { t } = useTranslation();
  const theme = useTheme();
  const router = useRouter();
  const params = useLocalSearchParams<{ id: string }>();
  const id = Number(params.id);

  const { data: plan } = useDebtPlan(id);
  const { data: summaries = [] } = useDebtPlansSummary();
  const { data: repayments = [] } = useRepaymentsForPlan(id);
  const markRepayment = useMarkRepayment();

  const summary = summaries.find((s) => s.planId === id);

  if (!plan) {
    return (
      <View
        style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.background }}
      >
        <ActivityIndicator color={theme.accent} />
      </View>
    );
  }

  const totalPeriods = summary?.totalPeriods ?? plan.totalPeriods;
  const paidPeriods = summary?.paidPeriods ?? 0;
  const remainingCents = summary?.remainingCents ?? 0;
  const progress = totalPeriods === 0 ? 0 : paidPeriods / totalPeriods;
  const nextDue = repayments.find((r) => r.status !== 'paid');

  return (
    <View style={{ flex: 1, backgroundColor: theme.background }}>
      <Stack.Screen
        options={{
          title: plan.platform,
          headerRight: () => (
            <Pressable
              onPress={() => router.push(`/debts/${id}/edit` as never)}
              style={({ pressed }) => pressed && { opacity: 0.6 }}
            >
              <SymbolView
                name={{ ios: 'square.and.pencil', android: 'edit' }}
                tintColor={theme.accent}
                size={22}
              />
            </Pressable>
          ),
        }}
      />
      <FlatList
        data={repayments}
        keyExtractor={(r) => String(r.id)}
        ItemSeparatorComponent={() => <View style={{ height: Spacing.one }} />}
        contentContainerStyle={styles.content}
        ListHeaderComponent={
          <View style={{ gap: Spacing.three, marginBottom: Spacing.three }}>
            <GlassCard padding="four" radius="lg">
              <ThemedText type="small" themeColor="textSecondary">
                {t('debts.progress')}
              </ThemedText>
              <View style={styles.progressRow}>
                <ThemedText style={styles.progressNumbers}>
                  {paidPeriods}
                  <ThemedText type="small" themeColor="textMuted">
                    {' / '}
                    {totalPeriods} {t('dashboard.periods')}
                  </ThemedText>
                </ThemedText>
                <AmountText cents={remainingCents} tone="expense" size="lg" />
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
              <ThemedText type="small" themeColor="textMuted" style={{ marginTop: Spacing.one }}>
                {t('dashboard.remaining')} {t('dashboard.of')} ¥{(remainingCents / 100).toFixed(2)}
              </ThemedText>
            </GlassCard>

            {nextDue && (
              <GlassCard padding="three" radius="lg">
                <ThemedText type="small" themeColor="textSecondary">
                  {t('debts.nextDue')}
                </ThemedText>
                <View style={styles.nextRow}>
                  <ThemedText type="default">
                    第 {nextDue.periodIndex} 期 · {formatLongDate(nextDue.dueDate)}
                  </ThemedText>
                  <AmountText cents={nextDue.amountCents} tone="neutral" size="md" />
                </View>
              </GlassCard>
            )}

            <ThemedText type="smallBold" themeColor="textSecondary" style={styles.sectionLabel}>
              {t('debts.repaymentList')}
            </ThemedText>
          </View>
        }
        renderItem={({ item }) => (
          <RepaymentRow
            repayment={item}
            onToggle={() => markRepayment.mutate({ id: item.id, paid: item.status !== 'paid' })}
          />
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  content: {
    padding: Spacing.three,
    paddingBottom: 120,
  },
  progressRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    marginTop: Spacing.one,
    marginBottom: Spacing.two,
  },
  progressNumbers: {
    fontSize: 34,
    fontWeight: '700',
  },
  progressBar: {
    height: 8,
    borderRadius: Radius.pill,
    backgroundColor: 'rgba(127, 127, 127, 0.18)',
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: Radius.pill,
  },
  nextRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: Spacing.one,
  },
  sectionLabel: {
    textTransform: 'uppercase',
    letterSpacing: 0.6,
    marginTop: Spacing.two,
  },
});
