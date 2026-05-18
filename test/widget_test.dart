import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pet/core/pet/pet_state.dart';
import 'package:pocket_pet/core/pet/pet_state_machine.dart';
import 'package:pocket_pet/core/nudge/nudge_message.dart';
import 'package:pocket_pet/core/reminders/reminder.dart';

/// Smoke tests — verify the most important invariants in one place.
void main() {
  group('Smoke tests', () {
    test('PetStateMachine starts idle', () {
      final m = PetStateMachine();
      expect(m.state, PetState.idle);
      m.dispose();
    });

    test('Nudge library is non-empty', () {
      expect(NudgeLibrary.all, isNotEmpty);
    });

    test('All nudge categories have messages', () {
      for (final c in NudgeCategory.values) {
        expect(NudgeLibrary.forCategory(c), isNotEmpty,
            reason: 'No messages for $c');
      }
    });

    test('Default reminder speak texts are non-empty', () {
      for (final t in ReminderType.values) {
        final r = Reminder(
          id: t.name,
          label: t.name,
          type: t,
          hour: 9,
          minute: 0,
          weekdays: List.filled(7, true),
        );
        expect(r.speakText.isNotEmpty, isTrue);
      }
    });
  });
}
