import { NativeTabs } from 'expo-router/unstable-native-tabs';
import { useTranslation } from 'react-i18next';
import { useColorScheme } from 'react-native';

import { Colors } from '@/constants/theme';

export default function TabLayout() {
  const { t } = useTranslation();
  const scheme = useColorScheme();
  const colors = Colors[scheme === 'dark' ? 'dark' : 'light'];

  return (
    <NativeTabs
      iconColor={colors.textSecondary}
      labelStyle={{
        color: colors.textSecondary,
        selected: { color: colors.accent },
      }}
    >
      <NativeTabs.Trigger name="index">
        <NativeTabs.Trigger.Label>{t('tabs.dashboard')}</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'chart.pie', selected: 'chart.pie.fill' }}
          md={{ default: 'dashboard', selected: 'dashboard' }}
          selectedColor={colors.accent}
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="salary">
        <NativeTabs.Trigger.Label>{t('tabs.salary')}</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'banknote', selected: 'banknote.fill' }}
          md={{ default: 'payments', selected: 'payments' }}
          selectedColor={colors.accent}
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="debts">
        <NativeTabs.Trigger.Label>{t('tabs.debts')}</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'creditcard', selected: 'creditcard.fill' }}
          md={{ default: 'credit_card', selected: 'credit_card' }}
          selectedColor={colors.accent}
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="calendar">
        <NativeTabs.Trigger.Label>{t('tabs.calendar')}</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'calendar', selected: 'calendar' }}
          md={{ default: 'event', selected: 'event' }}
          selectedColor={colors.accent}
        />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="settings">
        <NativeTabs.Trigger.Label>{t('tabs.settings')}</NativeTabs.Trigger.Label>
        <NativeTabs.Trigger.Icon
          sf={{ default: 'gearshape', selected: 'gearshape.fill' }}
          md={{ default: 'settings', selected: 'settings' }}
          selectedColor={colors.accent}
        />
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}
