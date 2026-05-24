import { useRouter } from 'expo-router';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { FlatList, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { EmptyState } from '@/components/empty-state';
import { Fab } from '@/components/fab';
import { ScreenHeader } from '@/components/screen-header';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { useDebtPlans, useDebtPlansSummary } from '@/features/debts/hooks';
import { DebtRow } from '@/features/debts/debt-row';

export default function DebtsScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const theme = useTheme();
  const { data: plans = [], isLoading } = useDebtPlans();
  const { data: summaries = [] } = useDebtPlansSummary();

  const summaryById = useMemo(() => {
    const map = new Map<number, (typeof summaries)[number]>();
    for (const s of summaries) map.set(s.planId, s);
    return map;
  }, [summaries]);

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        <ScreenHeader title={t('debts.title')} />
        {plans.length === 0 && !isLoading ? (
          <EmptyState
            title={t('debts.empty.title')}
            description={t('debts.empty.desc')}
          />
        ) : (
          <FlatList
            data={plans}
            keyExtractor={(p) => String(p.id)}
            contentContainerStyle={styles.list}
            renderItem={({ item }) => (
              <DebtRow
                plan={item}
                summary={summaryById.get(item.id)}
                onPress={() => router.push(`/debts/${item.id}`)}
              />
            )}
            ItemSeparatorComponent={() => <View style={{ height: Spacing.two }} />}
          />
        )}
        <Fab onPress={() => router.push('/debts/new')} accessibilityLabel={t('debts.add')} />
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  list: {
    paddingHorizontal: Spacing.three,
    paddingBottom: 120,
  },
});
