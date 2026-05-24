import DateTimePicker from '@react-native-community/datetimepicker';
import { useState } from 'react';
import { Modal, Platform, Pressable, StyleSheet, View } from 'react-native';

import { Radius, Spacing } from '@/constants/theme';
import { useTheme } from '@/hooks/use-theme';
import { ThemedText } from '@/components/themed-text';
import { formatLongDate } from '@/lib/date';

export type DateFieldProps = {
  value: Date;
  onChange: (value: Date) => void;
  minimumDate?: Date;
  maximumDate?: Date;
};

export function DateField({ value, onChange, minimumDate, maximumDate }: DateFieldProps) {
  const theme = useTheme();
  const [open, setOpen] = useState(false);

  const handleChange = (_event: unknown, selected?: Date) => {
    if (Platform.OS !== 'ios') {
      setOpen(false);
    }
    if (selected) {
      onChange(selected);
    }
  };

  return (
    <>
      <Pressable
        onPress={() => setOpen(true)}
        style={[
          styles.field,
          { backgroundColor: theme.backgroundElement, borderColor: theme.cardBorder },
        ]}
      >
        <ThemedText type="default">{formatLongDate(value)}</ThemedText>
      </Pressable>

      {open && Platform.OS === 'ios' && (
        <Modal animationType="slide" transparent presentationStyle="overFullScreen">
          <View style={styles.modalBackdrop}>
            <View style={[styles.modalSheet, { backgroundColor: theme.background }]}>
              <View style={styles.modalHeader}>
                <Pressable onPress={() => setOpen(false)} style={styles.modalAction}>
                  <ThemedText type="default" style={{ color: theme.accent }}>
                    完成
                  </ThemedText>
                </Pressable>
              </View>
              <DateTimePicker
                value={value}
                mode="date"
                display="spinner"
                locale="zh-CN"
                onChange={handleChange}
                minimumDate={minimumDate}
                maximumDate={maximumDate}
                themeVariant={theme.background === '#0B1220' ? 'dark' : 'light'}
              />
            </View>
          </View>
        </Modal>
      )}

      {open && Platform.OS !== 'ios' && (
        <DateTimePicker
          value={value}
          mode="date"
          onChange={handleChange}
          minimumDate={minimumDate}
          maximumDate={maximumDate}
        />
      )}
    </>
  );
}

const styles = StyleSheet.create({
  field: {
    borderRadius: Radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: Spacing.three,
    minHeight: 48,
    justifyContent: 'center',
  },
  modalBackdrop: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
  },
  modalSheet: {
    borderTopLeftRadius: Radius.xl,
    borderTopRightRadius: Radius.xl,
    paddingBottom: 24,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: Spacing.three,
  },
  modalAction: {
    paddingHorizontal: Spacing.two,
    paddingVertical: Spacing.one,
  },
});
