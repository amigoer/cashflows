import { StyleSheet, TextInput, type TextInputProps } from 'react-native';

import { Fonts, Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';

export type NoteInputProps = Omit<TextInputProps, 'value' | 'onChange' | 'onChangeText' | 'multiline'> & {
  value: string;
  onChange: (next: string) => void;
};

export function NoteInput({ value, onChange, placeholder, style, ...rest }: NoteInputProps) {
  const theme = useTheme();
  return (
    <TextInput
      value={value}
      onChangeText={onChange}
      placeholder={placeholder}
      placeholderTextColor={theme.textMuted}
      multiline
      style={[
        styles.input,
        {
          color: theme.text,
          backgroundColor: theme.backgroundElement,
          borderColor: theme.cardBorder,
        },
        style,
      ]}
      {...rest}
    />
  );
}

const styles = StyleSheet.create({
  input: {
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.two,
    minHeight: 72,
    fontFamily: Fonts.sans,
    fontSize: 16,
    textAlignVertical: 'top',
  },
});
