import { GlassView, isLiquidGlassAvailable } from 'expo-glass-effect';
import { Platform, StyleSheet, View, type ViewProps } from 'react-native';

import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type GlassCardProps = ViewProps & {
  padding?: keyof typeof Spacing;
  radius?: keyof typeof Radius;
  tintColor?: string;
  /** Disable the glass surface and use a flat themed card instead. */
  flat?: boolean;
};

const supportsLiquidGlass = Platform.OS === 'ios' && isLiquidGlassAvailable();

export function GlassCard({
  padding = 'three',
  radius = 'lg',
  tintColor,
  flat = false,
  style,
  children,
  ...rest
}: GlassCardProps) {
  const theme = useTheme();
  const containerStyle = [
    styles.base,
    {
      padding: Spacing[padding],
      borderRadius: Radius[radius],
    },
    style,
  ];

  if (supportsLiquidGlass && !flat) {
    return (
      <GlassView
        glassEffectStyle="regular"
        tintColor={tintColor}
        style={containerStyle}
        {...rest}
      >
        {children}
      </GlassView>
    );
  }

  return (
    <View
      style={[
        containerStyle,
        {
          backgroundColor: theme.cardSurface,
          borderWidth: StyleSheet.hairlineWidth,
          borderColor: theme.cardBorder,
        },
      ]}
      {...rest}
    >
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    overflow: 'hidden',
  },
});
