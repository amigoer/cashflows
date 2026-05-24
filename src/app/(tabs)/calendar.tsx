import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { GlassCard } from '@/components/glass-card';
import { ScreenHeader } from '@/components/screen-header';
import { ThemedText } from '@/components/themed-text';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { CalendarGrid, type DayBuckets } from '@/features/calendar/calendar-grid';
import { DayEventsList, type DayEvent } from '@/features/calendar/day-events-list';
import { MonthSwitcher } from '@/features/dashboard/month-switcher';
import { useMonthRepayments, useMonthSalaries } from '@/features/dashboard/hooks';
import { formatLongDate, isSameDay } from '@/lib/date';

function ymdKey(date: Date | number): string {
  const d = typeof date === 'number' ? new Date(date) : date;
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}

export default function CalendarScreen() {
  const { t } = useTranslation();
  const theme = useTheme();
  const [reference, setReference] = useState(() => new Date());
  const [selected, setSelected] = useState(() => new Date());

  const { data: salaries = [] } = useMonthSalaries(reference);
  const { data: repaymentRows = [] } = useMonthRepayments(reference);

  const buckets = useMemo(() => {
    const map = new Map<string, DayBuckets>();
    for (const s of salaries) {
      const key = ymdKey(s.paidAt);
      const cur = map.get(key) ?? { incomeCents: 0, repaymentCents: 0 };
      cur.incomeCents += s.amountCents;
      map.set(key, cur);
    }
    for (const r of repaymentRows) {
      const key = ymdKey(r.repayment.dueDate);
      const cur = map.get(key) ?? { incomeCents: 0, repaymentCents: 0 };
      cur.repaymentCents += r.repayment.amountCents;
      map.set(key, cur);
    }
    return map;
  }, [salaries, repaymentRows]);

  const events: DayEvent[] = useMemo(() => {
    const list: DayEvent[] = [];
    for (const s of salaries) {
      if (isSameDay(s.paidAt, selected)) list.push({ type: 'income', salary: s });
    }
    for (const r of repaymentRows) {
      if (isSameDay(r.repayment.dueDate, selected))
        list.push({ type: 'repayment', repayment: r.repayment, platform: r.debtPlan.platform });
    }
    return list;
  }, [salaries, repaymentRows, selected]);

  const handleMonthChange = (next: Date) => {
    setReference(next);
    setSelected(next);
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        <ScreenHeader
          title={t('calendar.title')}
          right={<MonthSwitcher reference={reference} onChange={handleMonthChange} />}
        />
        <ScrollView contentContainerStyle={styles.content}>
          <GlassCard padding="three" radius="lg">
            <CalendarGrid
              monthReference={reference}
              selectedDate={selected}
              onSelect={setSelected}
              buckets={buckets}
            />
            <View style={styles.legendRow}>
              <View style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: theme.income }]} />
                <ThemedText type="small" themeColor="textSecondary">
                  {t('calendar.legendIncome')}
                </ThemedText>
              </View>
              <View style={styles.legendItem}>
                <View style={[styles.legendDot, { backgroundColor: theme.expense }]} />
                <ThemedText type="small" themeColor="textSecondary">
                  {t('calendar.legendRepayment')}
                </ThemedText>
              </View>
            </View>
          </GlassCard>

          <View style={styles.dayHeader}>
            <ThemedText type="default" style={styles.dayHeaderTitle}>
              {formatLongDate(selected)}
            </ThemedText>
          </View>

          <DayEventsList events={events} />
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: {
    padding: Spacing.three,
    gap: Spacing.three,
    paddingBottom: 120,
  },
  legendRow: {
    flexDirection: 'row',
    gap: Spacing.three,
    marginTop: Spacing.two,
    paddingTop: Spacing.two,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: 'rgba(127, 127, 127, 0.18)',
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.one,
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  dayHeader: {
    paddingHorizontal: Spacing.one,
  },
  dayHeaderTitle: {
    fontSize: 17,
    fontWeight: '600',
  },
});
