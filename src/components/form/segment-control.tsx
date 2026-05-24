import { Pressable, StyleSheet, View } from 'react-native';

import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { ThemedText } from '@/components/themed-text';

export type SegmentOption<T extends string> = { value: T; label: string };

export type SegmentControlProps<T extends string> = {
  value: T;
  options: readonly SegmentOption<T>[];
  onChange: (value: T) => void;
};

export function SegmentControl<T extends string>({ value, options, onChange }: SegmentControlProps<T>) {
  const theme = useTheme();
  return (
    <View
      style={[
        styles.container,
        { backgroundColor: theme.backgroundElement, borderColor: theme.cardBorder },
      ]}
    >
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <Pressable
            key={opt.value}
            onPress={() => onChange(opt.value)}
            style={({ pressed }) => [
              styles.segment,
              active && { backgroundColor: theme.accent },
              pressed && !active && { backgroundColor: theme.backgroundSelected },
            ]}
          >
            <ThemedText
              type="smallBold"
              style={{ color: active ? '#fff' : theme.textSecondary }}
            >
              {opt.label}
            </ThemedText>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    padding: 4,
    gap: 4,
  },
  segment: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.two,
    borderRadius: Radius.sm,
  },
});
