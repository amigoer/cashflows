import '@/global.css';

import { Platform } from 'react-native';

export const Colors = {
  light: {
    text: '#0B1220',
    textSecondary: '#5B6478',
    textMuted: '#8C95A6',
    background: '#F5F7FB',
    backgroundElement: '#FFFFFF',
    backgroundSelected: '#E8ECF4',
    cardSurface: 'rgba(255, 255, 255, 0.68)',
    cardBorder: 'rgba(15, 23, 42, 0.06)',
    divider: 'rgba(15, 23, 42, 0.08)',
    accent: '#3B82F6',
    accentMuted: 'rgba(59, 130, 246, 0.12)',
    income: '#10B981',
    incomeMuted: 'rgba(16, 185, 129, 0.12)',
    expense: '#F43F5E',
    expenseMuted: 'rgba(244, 63, 94, 0.12)',
    warning: '#F59E0B',
  },
  dark: {
    text: '#F8FAFC',
    textSecondary: '#B8C0CF',
    textMuted: '#7B8497',
    background: '#0B1220',
    backgroundElement: '#131B2C',
    backgroundSelected: '#1D2638',
    cardSurface: 'rgba(255, 255, 255, 0.06)',
    cardBorder: 'rgba(255, 255, 255, 0.08)',
    divider: 'rgba(255, 255, 255, 0.08)',
    accent: '#60A5FA',
    accentMuted: 'rgba(96, 165, 250, 0.18)',
    income: '#34D399',
    incomeMuted: 'rgba(52, 211, 153, 0.18)',
    expense: '#FB7185',
    expenseMuted: 'rgba(251, 113, 133, 0.18)',
    warning: '#FBBF24',
  },
} as const;

export type ThemeColor = keyof typeof Colors.light & keyof typeof Colors.dark;

export const Fonts = Platform.select({
  ios: {
    sans: 'system-ui',
    serif: 'ui-serif',
    rounded: 'ui-rounded',
    mono: 'ui-monospace',
  },
  default: {
    sans: 'normal',
    serif: 'serif',
    rounded: 'normal',
    mono: 'monospace',
  },
  web: {
    sans: 'var(--font-display)',
    serif: 'var(--font-serif)',
    rounded: 'var(--font-rounded)',
    mono: 'var(--font-mono)',
  },
});

export const Spacing = {
  half: 2,
  one: 4,
  two: 8,
  three: 16,
  four: 24,
  five: 32,
  six: 64,
} as const;

export const Radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  pill: 999,
} as const;

export const BottomTabInset = Platform.select({ ios: 50, android: 80 }) ?? 0;
export const MaxContentWidth = 800;
