import { StyleSheet, View } from 'react-native';

import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { ThemedText } from '@/components/themed-text';

export type LabeledFieldProps = {
  label: string;
  hint?: string;
  error?: string;
  children: React.ReactNode;
};

export function LabeledField({ label, hint, error, children }: LabeledFieldProps) {
  const theme = useTheme();
  return (
    <View style={styles.container}>
      <ThemedText type="smallBold" themeColor="textSecondary" style={styles.label}>
        {label}
      </ThemedText>
      {children}
      {error ? (
        <ThemedText type="small" style={{ color: theme.expense }}>
          {error}
        </ThemedText>
      ) : hint ? (
        <ThemedText type="small" themeColor="textMuted">
          {hint}
        </ThemedText>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: Spacing.one,
  },
  label: {
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
});
