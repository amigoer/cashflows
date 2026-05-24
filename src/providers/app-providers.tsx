import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { DarkTheme, DefaultTheme, ThemeProvider } from 'expo-router';
import { useState } from 'react';
import { ActivityIndicator, StyleSheet, useColorScheme, View } from 'react-native';
import { I18nextProvider } from 'react-i18next';

import { db } from '@/db/client';
import migrations from '@/db/drizzle/migrations';
import { Colors } from '@/constants/theme';
import { i18n } from '@/i18n';
import { useMigrations } from 'drizzle-orm/expo-sqlite/migrator';

function MigrationGate({ children }: { children: React.ReactNode }) {
  const scheme = useColorScheme();
  const colors = Colors[scheme === 'dark' ? 'dark' : 'light'];
  const { success, error } = useMigrations(db, migrations);

  if (error) {
    return (
      <View style={[styles.gate, { backgroundColor: colors.background }]}>
        <ActivityIndicator color={colors.expense} />
      </View>
    );
  }

  if (!success) {
    return (
      <View style={[styles.gate, { backgroundColor: colors.background }]}>
        <ActivityIndicator color={colors.accent} />
      </View>
    );
  }

  return <>{children}</>;
}

export function AppProviders({ children }: { children: React.ReactNode }) {
  const scheme = useColorScheme();
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30 * 1000,
            retry: 1,
            refetchOnWindowFocus: false,
          },
        },
      }),
  );

  return (
    <I18nextProvider i18n={i18n}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider value={scheme === 'dark' ? DarkTheme : DefaultTheme}>
          <MigrationGate>{children}</MigrationGate>
        </ThemeProvider>
      </QueryClientProvider>
    </I18nextProvider>
  );
}

const styles = StyleSheet.create({
  gate: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
