import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useColorScheme } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

import { AppProviders } from '@/providers/app-providers';

export default function RootLayout() {
  const scheme = useColorScheme();
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <AppProviders>
        <Stack
          screenOptions={{
            headerShown: false,
            contentStyle: { backgroundColor: 'transparent' },
          }}
        >
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen
            name="salary/new"
            options={{ presentation: 'modal', title: '新增工资', headerShown: true }}
          />
          <Stack.Screen
            name="salary/[id]"
            options={{ presentation: 'modal', title: '编辑工资', headerShown: true }}
          />
          <Stack.Screen
            name="debts/new"
            options={{ presentation: 'modal', title: '新增分期', headerShown: true }}
          />
          <Stack.Screen
            name="debts/[id]/index"
            options={{ title: '债务详情', headerShown: true }}
          />
          <Stack.Screen
            name="debts/[id]/edit"
            options={{ presentation: 'modal', title: '编辑分期', headerShown: true }}
          />
        </Stack>
        <StatusBar style={scheme === 'dark' ? 'light' : 'dark'} />
      </AppProviders>
    </GestureHandlerRootView>
  );
}
