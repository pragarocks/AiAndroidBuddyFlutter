import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pet_state.dart';

/// StateNotifier that owns pet state transitions.
/// All state changes go through [send] — never set state directly.
class PetStateMachine extends StateNotifier<PetState> {
  PetStateMachine() : super(PetState.idle);

  Timer? _autoResetTimer;

  void send(PetEvent event) {
    _autoResetTimer?.cancel();

    final next = _transition(state, event);
    if (next != state) state = next;

    // Auto-reset transient states back to idle after a delay
    if (_isTransient(state)) {
      _autoResetTimer = Timer(
        _autoResetDuration(state),
        () { if (mounted) state = PetState.idle; },
      );
    }
  }

  PetState _transition(PetState current, PetEvent event) {
    return switch (event) {
      NightModeOn()        => PetState.sleeping,
      NightModeOff()       => PetState.idle,
      ResetToIdle()        => PetState.idle,
      ServiceError()       => PetState.error,
      NotificationArrived()=> current == PetState.sleeping ? current : PetState.excited,
      NudgeTriggered()     => PetState.running,
      NudgeDelivered()     => PetState.success,
      ReminderSpoken()     => PetState.success,
      ScreenTimeExceeded() => PetState.running,
      ScreenTimeNormal()   => PetState.idle,
      UserTapped()         => current == PetState.sleeping
                                  ? PetState.idle
                                  : PetState.excited,
    };
  }

  bool _isTransient(PetState s) => switch (s) {
    PetState.excited => true,
    PetState.success => true,
    PetState.error   => true,
    _                => false,
  };

  Duration _autoResetDuration(PetState s) => switch (s) {
    PetState.excited => const Duration(seconds: 3),
    PetState.success => const Duration(seconds: 5),
    PetState.error   => const Duration(seconds: 4),
    _                => const Duration(seconds: 2),
  };

  @override
  void dispose() {
    _autoResetTimer?.cancel();
    super.dispose();
  }
}

/// Riverpod provider
final petStateMachineProvider =
    StateNotifierProvider<PetStateMachine, PetState>(
  (_) => PetStateMachine(),
);
