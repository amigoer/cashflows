import * as Application from 'expo-application';
import { SymbolView } from 'expo-symbols';
import { useTranslation } from 'react-i18next';
import { Alert, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { GlassCard } from '@/components/glass-card';
import { ScreenHeader } from '@/components/screen-header';
import { ThemedText } from '@/components/themed-text';
import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { useExportCsv, useExportJson, useImportJson } from '@/features/settings/hooks';

type ActionRowProps = {
  iconIos: string;
  iconAndroid: string;
  label: string;
  description?: string;
  disabled?: boolean;
  destructive?: boolean;
  onPress: () => void;
  showDivider?: boolean;
};

function ActionRow({
  iconIos,
  iconAndroid,
  label,
  description,
  disabled,
  destructive,
  onPress,
  showDivider,
}: ActionRowProps) {
  const theme = useTheme();
  const color = destructive ? theme.expense : theme.text;
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.actionRow,
        showDivider && {
          borderBottomWidth: StyleSheet.hairlineWidth,
          borderBottomColor: theme.divider,
        },
        (pressed || disabled) && { opacity: 0.5 },
      ]}
    >
      <View style={[styles.iconBubble, { backgroundColor: theme.accentMuted }]}>
        <SymbolView
          name={{ ios: iconIos as never, android: iconAndroid as never }}
          tintColor={theme.accent}
          size={18}
        />
      </View>
      <View style={{ flex: 1 }}>
        <ThemedText type="default" style={{ color }}>
          {label}
        </ThemedText>
        {description ? (
          <ThemedText type="small" themeColor="textMuted">
            {description}
          </ThemedText>
        ) : null}
      </View>
      <SymbolView
        name={{ ios: 'chevron.right', android: 'chevron_right' }}
        tintColor={theme.textMuted}
        size={14}
      />
    </Pressable>
  );
}

export default function SettingsScreen() {
  const { t } = useTranslation();
  const theme = useTheme();
  const exportJsonM = useExportJson();
  const exportCsvM = useExportCsv();
  const importJsonM = useImportJson();

  const handleExport = (kind: 'json' | 'csv') => {
    const mutation = kind === 'json' ? exportJsonM : exportCsvM;
    mutation.mutate(undefined, {
      onError: () => Alert.alert(t('settings.exportFail')),
    });
  };

  const handleImport = () => {
    Alert.alert('导入会覆盖所有现有数据', '继续吗？', [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('common.confirm'),
        style: 'destructive',
        onPress: () =>
          importJsonM.mutate(undefined, {
            onSuccess: (res) => {
              if (res.ok) {
                Alert.alert(
                  t('settings.importSuccess'),
                  `工资 ${res.salaryCount} · 债务 ${res.debtCount} · 还款 ${res.repaymentCount}`,
                );
              } else if (res.reason === 'invalid') {
                Alert.alert(t('settings.importFail'), 'JSON 文件格式不正确');
              }
            },
            onError: () => Alert.alert(t('settings.importFail')),
          }),
      },
    ]);
  };

  const version = Application.nativeApplicationVersion ?? '0.1.0';

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        <ScreenHeader title={t('settings.title')} />
        <ScrollView contentContainerStyle={styles.content}>
          <SectionLabel>{t('settings.data')}</SectionLabel>
          <GlassCard padding="two" radius="lg">
            <ActionRow
              iconIos="square.and.arrow.up"
              iconAndroid="ios_share"
              label={t('settings.exportJson')}
              description="备份所有数据（推荐）"
              onPress={() => handleExport('json')}
              disabled={exportJsonM.isPending}
              showDivider
            />
            <ActionRow
              iconIos="tablecells"
              iconAndroid="table_chart"
              label={t('settings.exportCsv')}
              description="导出为表格便于查看"
              onPress={() => handleExport('csv')}
              disabled={exportCsvM.isPending}
              showDivider
            />
            <ActionRow
              iconIos="square.and.arrow.down"
              iconAndroid="download"
              label={t('settings.importJson')}
              description="从备份文件恢复"
              destructive
              onPress={handleImport}
              disabled={importJsonM.isPending}
            />
          </GlassCard>

          <ThemedText type="small" themeColor="textMuted" style={styles.hint}>
            {t('settings.storageNote')}
          </ThemedText>

          <SectionLabel>{t('settings.about')}</SectionLabel>
          <GlassCard padding="three" radius="lg">
            <View style={styles.infoRow}>
              <ThemedText type="default">{t('app.name')}</ThemedText>
              <ThemedText type="small" themeColor="textSecondary">
                v{version}
              </ThemedText>
            </View>
          </GlassCard>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <ThemedText type="smallBold" themeColor="textSecondary" style={styles.sectionLabel}>
      {children as string}
    </ThemedText>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: {
    padding: Spacing.three,
    gap: Spacing.two,
    paddingBottom: 120,
  },
  sectionLabel: {
    textTransform: 'uppercase',
    letterSpacing: 0.6,
    paddingHorizontal: Spacing.one,
    marginTop: Spacing.three,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.two,
    paddingVertical: Spacing.two,
    gap: Spacing.two,
  },
  iconBubble: {
    width: 36,
    height: 36,
    borderRadius: Radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  hint: {
    paddingHorizontal: Spacing.one,
    marginTop: Spacing.one,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
});
