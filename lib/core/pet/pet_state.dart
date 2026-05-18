/// All states the pet sprite can be in.
/// Maps directly to animation keys in pet.json ("states" object).
enum PetState {
  idle,       // default calm
  excited,    // new notification / user tapped
  thinking,   // thinking / deciding
  working,    // background task
  sleeping,   // night / DND / sleep mode corner
  success,    // nudge delivered, reminder spoken
  error,      // permission missing / service down
  waiting,    // listening for voice (Talking Tom mode)
  running,    // generic run (backwards compat)
  runLeft,    // flee left / idle walk left
  runRight,   // flee right / idle walk right
  jump,       // teleport hop / excited jump
  sad,        // beaten multiple times
  beating,    // being hit — brief flash before running
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
class UserBeating         extends PetEvent { const UserBeating(); }
class NightModeOn         extends PetEvent { const NightModeOn(); }
class NightModeOff        extends PetEvent { const NightModeOff(); }
class ServiceError        extends PetEvent { const ServiceError(); }
class ResetToIdle         extends PetEvent { const ResetToIdle(); }
class SleepRequested      extends PetEvent { const SleepRequested(); }
class WakeRequested       extends PetEvent { const WakeRequested(); }
class TalkingTomToggle    extends PetEvent { const TalkingTomToggle(); }
class StartWalking        extends PetEvent {
  final bool goRight;
  const StartWalking(this.goRight);
}
