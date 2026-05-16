import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pet/core/reminders/reminder.dart';

void main() {
  group('Reminder', () {
    const baseReminder = Reminder(
      id: 'test_water',
      label: 'Drink water',
      type: ReminderType.water,
      time: TimeOfDay(hour: 10, minute: 0),
      weekdays: [true, true, true, true, true, false, false],
    );

    test('speakText returns type default when no customText', () {
      expect(baseReminder.speakText,
          contains('Drink a glass of water'));
    });

    test('speakText returns customText when set', () {
      const custom = Reminder(
        id: 'c1',
        label: 'Custom',
        type: ReminderType.custom,
        time: TimeOfDay(hour: 9, minute: 0),
        weekdays: [true, true, true, true, true, true, true],
        customText: 'Take your vitamins!',
      );
      expect(custom.speakText, 'Take your vitamins!');
    });

    test('copyWith toggles enabled', () {
      final disabled = baseReminder.copyWith(enabled: false);
      expect(disabled.enabled, isFalse);
      expect(disabled.id, baseReminder.id);
    });

    test('toJson / fromJson round-trip', () {
      final json = baseReminder.toJson();
      final restored = Reminder.fromJson(json);
      expect(restored.id, baseReminder.id);
      expect(restored.type, baseReminder.type);
      expect(restored.time.hour, baseReminder.time.hour);
      expect(restored.enabled, baseReminder.enabled);
    });

    test('every ReminderType has a non-empty default speak text', () {
      for (final type in ReminderType.values) {
        final r = Reminder(
          id: type.name,
          label: type.name,
          type: type,
          time: const TimeOfDay(hour: 9, minute: 0),
          weekdays: List.filled(7, true),
        );
        expect(r.speakText.isNotEmpty, isTrue,
            reason: 'ReminderType.${type.name} has empty speak text');
      }
    });

    test('TimeOfDay toString pads correctly', () {
      expect(const TimeOfDay(hour: 9, minute: 5).toString(), '09:05');
      expect(const TimeOfDay(hour: 14, minute: 0).toString(), '14:00');
    });
  });
}
