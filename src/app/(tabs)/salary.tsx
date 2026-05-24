import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { FlatList, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { EmptyState } from '@/components/empty-state';
import { Fab } from '@/components/fab';
import { ScreenHeader } from '@/components/screen-header';
import { Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { useSalaries } from '@/features/salary/hooks';
import { SalaryRow } from '@/features/salary/salary-row';

export default function SalaryScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const theme = useTheme();
  const { data: salaries = [], isLoading } = useSalaries();

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        <ScreenHeader title={t('salary.title')} />
        {salaries.length === 0 && !isLoading ? (
          <EmptyState
            title={t('salary.empty.title')}
            description={t('salary.empty.desc')}
          />
        ) : (
          <FlatList
            data={salaries}
            keyExtractor={(s) => String(s.id)}
            contentContainerStyle={styles.list}
            renderItem={({ item }) => (
              <SalaryRow salary={item} onPress={() => router.push(`/salary/${item.id}`)} />
            )}
            ItemSeparatorComponent={() => <View style={{ height: Spacing.two }} />}
          />
        )}
        <Fab onPress={() => router.push('/salary/new')} accessibilityLabel={t('salary.add')} />
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  list: {
    paddingHorizontal: Spacing.three,
    paddingBottom: 120,
  },
});
