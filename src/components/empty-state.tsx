import { StyleSheet, View } from 'react-native';

import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { ThemedText } from '@/components/themed-text';

export type EmptyStateProps = {
  title: string;
  description?: string;
  icon?: React.ReactNode;
  action?: React.ReactNode;
};

export function EmptyState({ title, description, icon, action }: EmptyStateProps) {
  const theme = useTheme();

  return (
    <View style={styles.container}>
      {icon && <View style={styles.icon}>{icon}</View>}
      <ThemedText type="subtitle" style={styles.title}>
        {title}
      </ThemedText>
      {description && (
        <ThemedText type="small" style={[styles.description, { color: theme.textSecondary }]}>
          {description}
        </ThemedText>
      )}
      {action && <View style={styles.action}>{action}</View>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.four,
    gap: Spacing.two,
  },
  icon: {
    marginBottom: Spacing.two,
  },
  title: {
    textAlign: 'center',
    fontSize: 20,
    lineHeight: 28,
  },
  description: {
    textAlign: 'center',
    maxWidth: 280,
  },
  action: {
    marginTop: Spacing.three,
  },
});
