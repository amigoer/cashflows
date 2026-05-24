import { SymbolView } from 'expo-symbols';
import { Pressable, StyleSheet, View } from 'react-native';

import { useTheme } from '@/hooks/use-theme';

export type FabProps = {
  onPress: () => void;
  accessibilityLabel?: string;
};

export function Fab({ onPress, accessibilityLabel }: FabProps) {
  const theme = useTheme();
  return (
    <View style={styles.wrapper} pointerEvents="box-none">
      <Pressable
        onPress={onPress}
        accessibilityRole="button"
        accessibilityLabel={accessibilityLabel}
        style={({ pressed }) => [
          styles.button,
          { backgroundColor: theme.accent },
          pressed && { transform: [{ scale: 0.96 }], opacity: 0.85 },
        ]}
      >
        <SymbolView name={{ ios: 'plus', android: 'add' }} tintColor="#fff" size={26} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    position: 'absolute',
    right: 20,
    bottom: 24,
  },
  button: {
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.2,
    shadowRadius: 14,
    elevation: 6,
  },
});
