/// All states the pet sprite can be in.
/// Maps directly to rows in the spritesheet.
enum PetState {
  idle,       // row 0 — default calm
  excited,    // row 1 — new notification / user tapped
  thinking,   // row 2 — processing (future AI)
  working,    // row 3 — background task
  sleeping,   // row 4 — night / DND / inactivity
  success,    // row 5 — nudge delivered, reminder spoken
  error,      // row 6 — permission missing / service down
  waiting,    // row 7 — listening for voice (future)
  running,    // row 8 — screen time exceeded threshold
}

/// Events that drive PetStateMachine transitions.
sealed class PetEvent {
  const PetEvent();
}

class NotificationArrived extends PetEvent { const NotificationArrived(); }
class NudgeTriggered      extends PetEvent { const NudgeTriggered(); }
class NudgeDelivered      extends PetEvent { const NudgeDelivered(); }
class ReminderSpoken      extends PetEvent { const ReminderSpoken(); }
class ScreenTimeExceeded  extends PetEvent { const ScreenTimeExceeded(); }
class ScreenTimeNormal    extends PetEvent { const ScreenTimeNormal(); }
class UserTapped          extends PetEvent { const UserTapped(); }
class NightModeOn         extends PetEvent { const NightModeOn(); }
class NightModeOff        extends PetEvent { const NightModeOff(); }
class ServiceError        extends PetEvent { const ServiceError(); }
class ResetToIdle         extends PetEvent { const ResetToIdle(); }
