import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_pet/core/pet/pet_state.dart';
import 'package:pocket_pet/core/pet/pet_state_machine.dart';

void main() {
  group('PetStateMachine', () {
    late PetStateMachine machine;

    setUp(() => machine = PetStateMachine());
    tearDown(() => machine.dispose());

    test('initial state is idle', () {
      expect(machine.state, PetState.idle);
    });

    test('NotificationArrived → excited', () {
      machine.send(const NotificationArrived());
      expect(machine.state, PetState.excited);
    });

    test('NudgeTriggered → running', () {
      machine.send(const NudgeTriggered());
      expect(machine.state, PetState.running);
    });

    test('NudgeDelivered → success', () {
      machine.send(const NudgeDelivered());
      expect(machine.state, PetState.success);
    });

    test('ReminderSpoken → success', () {
      machine.send(const ReminderSpoken());
      expect(machine.state, PetState.success);
    });

    test('NightModeOn → sleeping', () {
      machine.send(const NightModeOn());
      expect(machine.state, PetState.sleeping);
    });

    test('NightModeOff → idle', () {
      machine.send(const NightModeOn());
      machine.send(const NightModeOff());
      expect(machine.state, PetState.idle);
    });

    test('NotificationArrived while sleeping stays sleeping', () {
      machine.send(const NightModeOn());
      machine.send(const NotificationArrived());
      expect(machine.state, PetState.sleeping);
    });

    test('UserTapped while sleeping → idle', () {
      machine.send(const NightModeOn());
      machine.send(const UserTapped());
      expect(machine.state, PetState.idle);
    });

    test('UserTapped while idle → excited', () {
      machine.send(const UserTapped());
      expect(machine.state, PetState.excited);
    });

    test('ServiceError → error', () {
      machine.send(const ServiceError());
      expect(machine.state, PetState.error);
    });

    test('ResetToIdle → idle from any state', () {
      machine.send(const NudgeTriggered());
      expect(machine.state, PetState.running);
      machine.send(const ResetToIdle());
      expect(machine.state, PetState.idle);
    });

    test('ScreenTimeExceeded → running', () {
      machine.send(const ScreenTimeExceeded());
      expect(machine.state, PetState.running);
    });

    test('ScreenTimeNormal → idle', () {
      machine.send(const ScreenTimeExceeded());
      machine.send(const ScreenTimeNormal());
      expect(machine.state, PetState.idle);
    });
  });
}
