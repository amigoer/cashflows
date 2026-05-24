import { format, isSameDay, isToday, startOfMonth, endOfMonth, addMonths } from 'date-fns';
import { zhCN } from 'date-fns/locale';

export function toEpochMs(date: Date): number {
  return date.getTime();
}

export function fromEpochMs(ms: number): Date {
  return new Date(ms);
}

export function formatDate(value: Date | number, pattern = 'yyyy-MM-dd'): string {
  const date = typeof value === 'number' ? new Date(value) : value;
  return format(date, pattern, { locale: zhCN });
}

export function formatLongDate(value: Date | number): string {
  return formatDate(value, 'yyyy 年 M 月 d 日');
}

export function formatMonthDay(value: Date | number): string {
  return formatDate(value, 'M 月 d 日');
}

export function formatYearMonth(value: Date | number): string {
  return formatDate(value, 'yyyy 年 M 月');
}

export function monthRange(reference: Date): { start: Date; end: Date } {
  return { start: startOfMonth(reference), end: endOfMonth(reference) };
}

export { addMonths, isSameDay, isToday, startOfMonth, endOfMonth };
