import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { EmptyState } from '@/components/empty-state';
import { ScreenHeader } from '@/components/screen-header';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { useDebtPlansSummary } from '@/features/debts/hooks';
import { MonthSwitcher } from '@/features/dashboard/month-switcher';
import { PlatformDebtsSection } from '@/features/dashboard/platform-debts-section';
import { SummaryCards } from '@/features/dashboard/summary-cards';
import { useMonthSummary } from '@/features/dashboard/hooks';

export default function DashboardScreen() {
  const { t } = useTranslation();
  const theme = useTheme();
  const [reference, setReference] = useState(() => new Date());

  const { data: summary, isLoading: summaryLoading } = useMonthSummary(reference);
  const { data: summaries = [] } = useDebtPlansSummary();

  const hasAnyData = (summary?.salaryCount ?? 0) > 0 || (summary?.repaymentCount ?? 0) > 0 || summaries.length > 0;

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        <ScreenHeader
          title={t('dashboard.title')}
          right={<MonthSwitcher reference={reference} onChange={setReference} />}
        />
        <ScrollView
          contentContainerStyle={styles.content}
          showsVerticalScrollIndicator={false}
        >
          {!hasAnyData && !summaryLoading ? (
            <EmptyState
              title={t('dashboard.noData')}
              description={t('dashboard.addFirst')}
            />
          ) : (
            <>
              <SummaryCards summary={summary} />
              <PlatformDebtsSection summaries={summaries} />
            </>
          )}
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: {
    padding: Spacing.three,
    gap: Spacing.four,
    paddingBottom: 120,
  },
});
