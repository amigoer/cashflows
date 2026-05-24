import { eachDayOfInterval, endOfWeek, isSameDay, isSameMonth, startOfWeek } from 'date-fns';
import { Pressable, StyleSheet, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { endOfMonth, startOfMonth } from '@/lib/date';

export type DayBuckets = {
  incomeCents: number;
  repaymentCents: number;
};

export type CalendarGridProps = {
  monthReference: Date;
  selectedDate: Date;
  onSelect: (date: Date) => void;
  buckets: Map<string, DayBuckets>;
};

const WEEKDAY_LABELS = ['一', '二', '三', '四', '五', '六', '日'];

function ymdKey(date: Date): string {
  return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
}

export function CalendarGrid({ monthReference, selectedDate, onSelect, buckets }: CalendarGridProps) {
  const theme = useTheme();

  const monthStart = startOfMonth(monthReference);
  const monthEnd = endOfMonth(monthReference);
  const gridStart = startOfWeek(monthStart, { weekStartsOn: 1 });
  const gridEnd = endOfWeek(monthEnd, { weekStartsOn: 1 });
  const days = eachDayOfInterval({ start: gridStart, end: gridEnd });
  const today = new Date();

  return (
    <View style={styles.container}>
      <View style={styles.weekdayRow}>
        {WEEKDAY_LABELS.map((w) => (
          <ThemedText
            key={w}
            type="small"
            style={[styles.weekdayLabel, { color: theme.textMuted }]}
          >
            {w}
          </ThemedText>
        ))}
      </View>

      <View style={styles.grid}>
        {days.map((day) => {
          const inMonth = isSameMonth(day, monthReference);
          const selected = isSameDay(day, selectedDate);
          const isCurrentDay = isSameDay(day, today);
          const bucket = buckets.get(ymdKey(day));

          return (
            <Pressable
              key={day.toISOString()}
              onPress={() => onSelect(day)}
              style={[styles.cell]}
              accessibilityRole="button"
            >
              <View
                style={[
                  styles.cellInner,
                  selected && { backgroundColor: theme.accent },
                  !selected && isCurrentDay && { borderColor: theme.accent, borderWidth: 1.5 },
                ]}
              >
                <ThemedText
                  type="small"
                  style={[
                    styles.day,
                    {
                      color: selected ? '#fff' : inMonth ? theme.text : theme.textMuted,
                      fontWeight: isCurrentDay ? '700' : '500',
                    },
                  ]}
                >
                  {day.getDate()}
                </ThemedText>
                <View style={styles.dotRow}>
                  {bucket && bucket.incomeCents > 0 && (
                    <View style={[styles.dot, { backgroundColor: selected ? '#fff' : theme.income }]} />
                  )}
                  {bucket && bucket.repaymentCents > 0 && (
                    <View style={[styles.dot, { backgroundColor: selected ? '#fff' : theme.expense }]} />
                  )}
                </View>
              </View>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: Spacing.one,
  },
  weekdayRow: {
    flexDirection: 'row',
  },
  weekdayLabel: {
    flex: 1,
    textAlign: 'center',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  cell: {
    width: `${100 / 7}%`,
    aspectRatio: 1,
    padding: 2,
  },
  cellInner: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: Radius.md,
    gap: 2,
    borderWidth: 1.5,
    borderColor: 'transparent',
  },
  day: {
    fontVariant: ['tabular-nums'],
    fontSize: 15,
  },
  dotRow: {
    flexDirection: 'row',
    gap: 3,
    height: 4,
  },
  dot: {
    width: 4,
    height: 4,
    borderRadius: 2,
  },
});
