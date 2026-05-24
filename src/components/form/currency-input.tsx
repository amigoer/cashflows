import { useMemo } from 'react';
import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';

import { Fonts, Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { ThemedText } from '@/components/themed-text';
import { centsToYuan } from '@/lib/money';

export type CurrencyInputProps = Omit<TextInputProps, 'value' | 'onChange' | 'onChangeText'> & {
  valueCents: number | null;
  onChange: (cents: number | null) => void;
};

export function CurrencyInput({ valueCents, onChange, style, ...rest }: CurrencyInputProps) {
  const theme = useTheme();

  const display = useMemo(() => {
    if (valueCents == null) return '';
    return centsToYuan(valueCents).toFixed(2);
  }, [valueCents]);

  return (
    <View
      style={[
        styles.row,
        {
          backgroundColor: theme.backgroundElement,
          borderColor: theme.cardBorder,
        },
      ]}
    >
      <ThemedText type="default" themeColor="textSecondary" style={styles.prefix}>
        ¥
      </ThemedText>
      <TextInput
        value={display}
        onChangeText={(text) => {
          const trimmed = text.replace(/[^0-9.]/g, '');
          if (trimmed.length === 0) {
            onChange(null);
            return;
          }
          const num = Number(trimmed);
          if (!Number.isFinite(num)) {
            onChange(null);
            return;
          }
          onChange(Math.round(num * 100));
        }}
        keyboardType="decimal-pad"
        placeholder="0.00"
        placeholderTextColor={theme.textMuted}
        style={[styles.input, { color: theme.text }, style]}
        {...rest}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: Spacing.three,
    minHeight: 48,
    gap: Spacing.one,
  },
  prefix: {
    fontFamily: Fonts.rounded,
    fontSize: 18,
  },
  input: {
    flex: 1,
    fontFamily: Fonts.rounded,
    fontVariant: ['tabular-nums'],
    fontSize: 22,
    paddingVertical: 0,
  },
});
