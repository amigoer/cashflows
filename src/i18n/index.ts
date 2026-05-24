import { getLocales } from 'expo-localization';
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import { zhCN } from './zh-CN';

const locales = getLocales();
const deviceLanguage = locales[0]?.languageCode ?? 'zh';

void i18n.use(initReactI18next).init({
  resources: {
    'zh-CN': { translation: zhCN },
    zh: { translation: zhCN },
  },
  lng: deviceLanguage.startsWith('zh') ? 'zh-CN' : 'zh-CN',
  fallbackLng: 'zh-CN',
  interpolation: { escapeValue: false },
  compatibilityJSON: 'v4',
  returnNull: false,
});

export { i18n };
