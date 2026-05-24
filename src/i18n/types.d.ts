import 'react-i18next';

import type { Translation } from './zh-CN';

declare module 'react-i18next' {
  interface CustomTypeOptions {
    defaultNS: 'translation';
    resources: {
      translation: Translation;
    };
  }
}
