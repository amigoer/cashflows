import { SymbolView } from 'expo-symbols';
import { Pressable, StyleSheet, View } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { addMonths, formatYearMonth } from '@/lib/date';

export type MonthSwitcherProps = {
  reference: Date;
  onChange: (next: Date) => void;
};

export function MonthSwitcher({ reference, onChange }: MonthSwitcherProps) {
  const theme = useTheme();

  return (
    <View style={styles.row}>
      <Pressable
        onPress={() => onChange(addMonths(reference, -1))}
        style={({ pressed }) => [
          styles.iconButton,
          { backgroundColor: theme.backgroundElement },
          pressed && { opacity: 0.7 },
        ]}
        accessibilityLabel="上个月"
      >
        <SymbolView
          name={{ ios: 'chevron.left', android: 'chevron_left' }}
          tintColor={theme.text}
          size={18}
        />
      </Pressable>
      <ThemedText type="default" style={[styles.label, { color: theme.text }]}>
        {formatYearMonth(reference)}
      </ThemedText>
      <Pressable
        onPress={() => onChange(addMonths(reference, 1))}
        style={({ pressed }) => [
          styles.iconButton,
          { backgroundColor: theme.backgroundElement },
          pressed && { opacity: 0.7 },
        ]}
        accessibilityLabel="下个月"
      >
        <SymbolView
          name={{ ios: 'chevron.right', android: 'chevron_right' }}
          tintColor={theme.text}
          size={18}
        />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.two,
  },
  iconButton: {
    width: 32,
    height: 32,
    borderRadius: Radius.pill,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    fontSize: 18,
    fontWeight: '600',
    minWidth: 110,
    textAlign: 'center',
  },
});
