import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pet/core/reminders/reminder.dart';

void main() {
  group('Reminder', () {
    const base = Reminder(
      id: 'test_water',
      label: 'Drink water',
      type: ReminderType.water,
      hour: 10,
      minute: 0,
      weekdays: [true, true, true, true, true, false, false],
    );

    test('speakText returns type default when no customText', () {
      expect(base.speakText, contains('Drink a glass of water'));
    });

    test('speakText returns customText when set', () {
      const custom = Reminder(
        id: 'c1',
        label: 'Custom',
        type: ReminderType.custom,
        hour: 9,
        minute: 0,
        weekdays: [true, true, true, true, true, true, true],
        customText: 'Take your vitamins!',
      );
      expect(custom.speakText, 'Take your vitamins!');
    });

    test('copyWith toggles enabled', () {
      final disabled = base.copyWith(enabled: false);
      expect(disabled.enabled, isFalse);
      expect(disabled.id, base.id);
    });

    test('toJson / fromJson round-trip', () {
      final json = base.toJson();
      final restored = Reminder.fromJson(json);
      expect(restored.id, base.id);
      expect(restored.type, base.type);
      expect(restored.hour, base.hour);
      expect(restored.minute, base.minute);
      expect(restored.enabled, base.enabled);
    });

    test('every ReminderType has a non-empty default speak text', () {
      for (final type in ReminderType.values) {
        final r = Reminder(
          id: type.name,
          label: type.name,
          type: type,
          hour: 9,
          minute: 0,
          weekdays: List.filled(7, true),
        );
        expect(r.speakText.isNotEmpty, isTrue,
            reason: 'ReminderType.${type.name} has empty speak text');
      }
    });

    test('time getter returns correct TimeOfDay', () {
      expect(base.time.hour, 10);
      expect(base.time.minute, 0);
    });
  });
}
