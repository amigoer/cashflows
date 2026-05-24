import { useTranslation } from 'react-i18next';
import { StyleSheet, View } from 'react-native';

import { AmountText } from '@/components/amount-text';
import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import type { Repayment, Salary } from '@/db/schema';

export type DayEvent =
  | { type: 'income'; salary: Salary }
  | { type: 'repayment'; repayment: Repayment; platform: string };

export type DayEventsListProps = {
  events: DayEvent[];
};

export function DayEventsList({ events }: DayEventsListProps) {
  const { t } = useTranslation();
  const theme = useTheme();

  if (events.length === 0) {
    return (
      <View style={styles.empty}>
        <ThemedText type="small" themeColor="textMuted">
          {t('calendar.empty')}
        </ThemedText>
      </View>
    );
  }

  return (
    <View style={styles.list}>
      {events.map((event) => {
        if (event.type === 'income') {
          return (
            <View
              key={`s${event.salary.id}`}
              style={[
                styles.row,
                { backgroundColor: theme.backgroundElement, borderColor: theme.cardBorder },
              ]}
            >
              <View style={[styles.tag, { backgroundColor: theme.incomeMuted }]}>
                <ThemedText type="small" style={{ color: theme.income }}>
                  {t('calendar.legendIncome')}
                </ThemedText>
              </View>
              <View style={styles.eventBody}>
                <ThemedText type="default">
                  {t(`salary.periods.${event.salary.period}`)}
                </ThemedText>
                {event.salary.note ? (
                  <ThemedText type="small" themeColor="textMuted">
                    {event.salary.note}
                  </ThemedText>
                ) : null}
              </View>
              <AmountText cents={event.salary.amountCents} tone="income" size="md" />
            </View>
          );
        }
        return (
          <View
            key={`r${event.repayment.id}`}
            style={[
              styles.row,
              { backgroundColor: theme.backgroundElement, borderColor: theme.cardBorder },
            ]}
          >
            <View style={[styles.tag, { backgroundColor: theme.expenseMuted }]}>
              <ThemedText type="small" style={{ color: theme.expense }}>
                {t('calendar.legendRepayment')}
              </ThemedText>
            </View>
            <View style={styles.eventBody}>
              <ThemedText type="default">{event.platform}</ThemedText>
              <ThemedText type="small" themeColor="textMuted">
                第 {event.repayment.periodIndex} 期 ·{' '}
                {event.repayment.status === 'paid' ? '已还' : '待还'}
              </ThemedText>
            </View>
            <AmountText cents={event.repayment.amountCents} tone="expense" size="md" />
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  list: {
    gap: Spacing.two,
  },
  empty: {
    paddingVertical: Spacing.four,
    alignItems: 'center',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.two,
    paddingVertical: Spacing.two,
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    gap: Spacing.two,
  },
  tag: {
    paddingHorizontal: Spacing.two,
    paddingVertical: 4,
    borderRadius: Radius.pill,
  },
  eventBody: {
    flex: 1,
    gap: 2,
  },
});
