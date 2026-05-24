import { StyleSheet, Text, type TextProps } from 'react-native';

import { Fonts } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { formatMoney, type FormatMoneyOptions } from '@/lib/money';

type Tone = 'neutral' | 'income' | 'expense' | 'auto';
type Size = 'sm' | 'md' | 'lg' | 'xl';

export type AmountTextProps = Omit<TextProps, 'children'> &
  FormatMoneyOptions & {
    cents: number;
    tone?: Tone;
    size?: Size;
  };

const SIZE_STYLES: Record<Size, { fontSize: number; lineHeight: number; fontWeight: '500' | '600' | '700' }> = {
  sm: { fontSize: 14, lineHeight: 20, fontWeight: '500' },
  md: { fontSize: 17, lineHeight: 22, fontWeight: '600' },
  lg: { fontSize: 24, lineHeight: 30, fontWeight: '700' },
  xl: { fontSize: 34, lineHeight: 40, fontWeight: '700' },
};

export function AmountText({
  cents,
  tone = 'auto',
  size = 'md',
  signed,
  showSymbol,
  compact,
  style,
  ...rest
}: AmountTextProps) {
  const theme = useTheme();

  const resolvedTone: Tone =
    tone === 'auto' ? (cents > 0 ? 'income' : cents < 0 ? 'expense' : 'neutral') : tone;

  const color =
    resolvedTone === 'income'
      ? theme.income
      : resolvedTone === 'expense'
        ? theme.expense
        : theme.text;

  return (
    <Text
      style={[styles.base, SIZE_STYLES[size], { color }, style]}
      {...rest}
    >
      {formatMoney(cents, { signed, showSymbol, compact })}
    </Text>
  );
}

const styles = StyleSheet.create({
  base: {
    fontFamily: Fonts.rounded,
    fontVariant: ['tabular-nums'],
  },
});
