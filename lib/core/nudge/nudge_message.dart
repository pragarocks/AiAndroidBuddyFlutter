/// Category of the nudge — drives which messages are picked and when.
enum NudgeCategory {
  screenTimeLight,   // 5-15 min on app
  screenTimeMedium,  // 15-30 min on app
  screenTimeHeavy,   // 30-60 min on app
  screenTimeExtreme, // 60+ min on app
  water,
  eyeBreak,
  posture,
  movement,
  breathe,
  sleep,
  general,
}

class NudgeMessage {
  final String text;
  final NudgeCategory category;
  final String? appLabel; // null = generic, set = app-specific

  const NudgeMessage(this.text, this.category, [this.appLabel]);
}

/// -----------------------------------------------------------------------
/// THE COMPLETE NUDGE LIBRARY — 85 messages
/// -----------------------------------------------------------------------
class NudgeLibrary {
  NudgeLibrary._();

  // ignore: unused_field
  static const _version = 1;

  static const all = <NudgeMessage>[

    // ── INSTAGRAM ────────────────────────────────────────────────────────
    NudgeMessage("Still on Insta? Real life's calling bro.",          NudgeCategory.screenTimeMedium, 'Instagram'),
    NudgeMessage("30 mins on Instagram… go touch some grass.",        NudgeCategory.screenTimeHeavy,  'Instagram'),
    NudgeMessage("Your eyes are not reels. Give them a break.",       NudgeCategory.screenTimeHeavy,  'Instagram'),
    NudgeMessage("An hour on Instagram. That's a skill you could've learned.",  NudgeCategory.screenTimeExtreme, 'Instagram'),
    NudgeMessage("Insta's still there. You, however, need water.",    NudgeCategory.screenTimeMedium, 'Instagram'),
    NudgeMessage("Hey, Instagram will exist tomorrow. Step away.",    NudgeCategory.screenTimeHeavy,  'Instagram'),
    NudgeMessage("You've scrolled far enough to reach the moon. Walk instead.", NudgeCategory.screenTimeExtreme, 'Instagram'),

    // ── YOUTUBE ──────────────────────────────────────────────────────────
    NudgeMessage("YouTube's buffering. You should too. Pause.",       NudgeCategory.screenTimeMedium, 'YouTube'),
    NudgeMessage("45 mins on YouTube. The creator got paid. Did you?",NudgeCategory.screenTimeHeavy,  'YouTube'),
    NudgeMessage("That was 3 videos. And 40 minutes. Step back.",     NudgeCategory.screenTimeMedium, 'YouTube'),
    NudgeMessage("YouTube spiral detected. Surface now!",             NudgeCategory.screenTimeHeavy,  'YouTube'),
    NudgeMessage("You've watched enough. Now do the thing you were avoiding.", NudgeCategory.screenTimeExtreme, 'YouTube'),
    NudgeMessage("60 mins of YouTube… your eyes are buffering.",      NudgeCategory.screenTimeExtreme, 'YouTube'),

    // ── TIKTOK ───────────────────────────────────────────────────────────
    NudgeMessage("TikTok's still there. Your back isn't happy though.",  NudgeCategory.screenTimeMedium, 'TikTok'),
    NudgeMessage("30 mins of TikTok. That's 150 videos. Go breathe.",    NudgeCategory.screenTimeHeavy,  'TikTok'),
    NudgeMessage("TikTok brain activated. Go do something with your hands.", NudgeCategory.screenTimeHeavy, 'TikTok'),
    NudgeMessage("You and TikTok need some space. 5 min break. Now.",    NudgeCategory.screenTimeExtreme, 'TikTok'),

    // ── TWITTER / X ──────────────────────────────────────────────────────
    NudgeMessage("The discourse can wait. Your neck can't.",           NudgeCategory.screenTimeMedium, 'Twitter'),
    NudgeMessage("Twitter will still be angry in 10 minutes. Take a break.", NudgeCategory.screenTimeMedium, 'Twitter'),
    NudgeMessage("30 mins of X. You've seen enough opinions for today.",NudgeCategory.screenTimeHeavy, 'Twitter'),
    NudgeMessage("Chronically online mode: ON. Let's fix that.",       NudgeCategory.screenTimeHeavy,  'Twitter'),

    // ── REDDIT ───────────────────────────────────────────────────────────
    NudgeMessage("Reddit hole detected. Pull up!",                     NudgeCategory.screenTimeMedium, 'Reddit'),
    NudgeMessage("You've been on Reddit for 30 mins. Go be the main character.", NudgeCategory.screenTimeHeavy, 'Reddit'),
    NudgeMessage("The comments aren't worth your neck pain. Step away.",NudgeCategory.screenTimeHeavy, 'Reddit'),

    // ── FACEBOOK ─────────────────────────────────────────────────────────
    NudgeMessage("30 mins of Facebook. Even Mark thinks you need a break.", NudgeCategory.screenTimeHeavy, 'Facebook'),
    NudgeMessage("Facebook still exists and so do you. Go drink water.", NudgeCategory.screenTimeMedium, 'Facebook'),

    // ── SNAPCHAT ─────────────────────────────────────────────────────────
    NudgeMessage("Your streaks will survive a 5-minute break. Promise.", NudgeCategory.screenTimeMedium, 'Snapchat'),
    NudgeMessage("Snap break. You snap back to life now.",               NudgeCategory.screenTimeMedium, 'Snapchat'),

    // ── LINKEDIN ─────────────────────────────────────────────────────────
    NudgeMessage("Even hustle culture says take a break. Heard of it?", NudgeCategory.screenTimeMedium, 'LinkedIn'),
    NudgeMessage("30 mins of LinkedIn. That's enough 'passion' for one day.", NudgeCategory.screenTimeHeavy, 'LinkedIn'),

    // ── GENERIC SCREEN TIME LIGHT (5-15 mins) ────────────────────────────
    NudgeMessage("Hey! Enjoying the scroll? Just checking in.",        NudgeCategory.screenTimeLight),
    NudgeMessage("Quick check — how's the posture looking back there?",NudgeCategory.screenTimeLight),
    NudgeMessage("Eyes still blinking? Good. Just making sure.",       NudgeCategory.screenTimeLight),
    NudgeMessage("You've been on your phone a bit. All good?",         NudgeCategory.screenTimeLight),
    NudgeMessage("Quick reminder: you have a body. Say hi to it.",     NudgeCategory.screenTimeLight),

    // ── GENERIC SCREEN TIME MEDIUM (15-30 mins) ──────────────────────────
    NudgeMessage("15 minutes gone. Anything actually useful happening?",  NudgeCategory.screenTimeMedium),
    NudgeMessage("Put the phone down for 2 mins. You won't miss anything.", NudgeCategory.screenTimeMedium),
    NudgeMessage("Screen time is creeping up. Take a tiny break.",       NudgeCategory.screenTimeMedium),
    NudgeMessage("Heads up: you've been scrolling for a while.",         NudgeCategory.screenTimeMedium),
    NudgeMessage("Phone check: 20 mins. Reality check: now.",            NudgeCategory.screenTimeMedium),

    // ── GENERIC SCREEN TIME HEAVY (30-60 mins) ───────────────────────────
    NudgeMessage("30 whole minutes. Your phone will be fine without you.", NudgeCategory.screenTimeHeavy),
    NudgeMessage("Half an hour. That's 30 minutes of your one wild life.", NudgeCategory.screenTimeHeavy),
    NudgeMessage("Your screen time report is going to be uncomfortable.",  NudgeCategory.screenTimeHeavy),
    NudgeMessage("I'm not judging. But also… 30 minutes, bro.",           NudgeCategory.screenTimeHeavy),
    NudgeMessage("Phone time: 30 mins. Worth it? Be honest.",             NudgeCategory.screenTimeHeavy),

    // ── GENERIC SCREEN TIME EXTREME (60+ mins) ───────────────────────────
    NudgeMessage("An HOUR. I say this with love: put it down.",           NudgeCategory.screenTimeExtreme),
    NudgeMessage("60 minutes of screen time. I'm staging an intervention.", NudgeCategory.screenTimeExtreme),
    NudgeMessage("Your future self is begging you to stop scrolling.",    NudgeCategory.screenTimeExtreme),
    NudgeMessage("The algorithm won. You lost. Take your life back.",     NudgeCategory.screenTimeExtreme),
    NudgeMessage("Seriously though. One hour. Go walk to the kitchen.",   NudgeCategory.screenTimeExtreme),

    // ── WATER ─────────────────────────────────────────────────────────────
    NudgeMessage("Drink water. No, not later. Right now. I'll wait.",     NudgeCategory.water),
    NudgeMessage("Hydration check: when did you last drink water?",       NudgeCategory.water),
    NudgeMessage("Water o'clock! Your kidneys say hi.",                   NudgeCategory.water),
    NudgeMessage("Hey, drink some water. Brains run on H2O, you know.",   NudgeCategory.water),
    NudgeMessage("Sip something. Tea, water, anything. Go.",              NudgeCategory.water),
    NudgeMessage("Your body is ~60% water. Top it up!",                  NudgeCategory.water),
    NudgeMessage("Fun fact: you're probably slightly dehydrated right now. Water!", NudgeCategory.water),
    NudgeMessage("Water break! The phone will be here when you get back.",NudgeCategory.water),

    // ── EYE BREAK (20-20-20 rule) ─────────────────────────────────────────
    NudgeMessage("20-20-20! Look 20 feet away for 20 seconds. Go!",       NudgeCategory.eyeBreak),
    NudgeMessage("Your eyes called. They want a 20-second vacation.",     NudgeCategory.eyeBreak),
    NudgeMessage("Blink. Seriously, blink a few times. Screen dry-eye is real.", NudgeCategory.eyeBreak),
    NudgeMessage("Eye break time. Stare at something far away. Nature counts.", NudgeCategory.eyeBreak),
    NudgeMessage("Look up from your screen for 20 seconds. Your eyes will thank you.", NudgeCategory.eyeBreak),
    NudgeMessage("Screen rest! Look at the farthest thing you can see.",  NudgeCategory.eyeBreak),

    // ── POSTURE ───────────────────────────────────────────────────────────
    NudgeMessage("Neck check! Is your chin forward? Fix that posture.",   NudgeCategory.posture),
    NudgeMessage("Sit up straight. Your spine is not a question mark.",   NudgeCategory.posture),
    NudgeMessage("Text neck incoming. Pull that chin back. Sit tall.",    NudgeCategory.posture),
    NudgeMessage("Shoulders back! You're not a shrimp, don't hunch like one.", NudgeCategory.posture),
    NudgeMessage("Posture check: back straight, screen at eye level.",    NudgeCategory.posture),
    NudgeMessage("Uncurl yourself. Spine straight. Deep breath. Better?", NudgeCategory.posture),

    // ── MOVEMENT / STRETCH ────────────────────────────────────────────────
    NudgeMessage("Stand up. Stretch your arms. Sit back down. You're welcome.", NudgeCategory.movement),
    NudgeMessage("Roll your neck gently. Hear that? That's stress leaving.", NudgeCategory.movement),
    NudgeMessage("Shake out your hands. Wrists need breaks too!",         NudgeCategory.movement),
    NudgeMessage("Take 20 steps. Lap of the room. You know you want to.", NudgeCategory.movement),
    NudgeMessage("Calf raises at your desk. Yes, right now. 10 reps.",   NudgeCategory.movement),
    NudgeMessage("Stand up for 2 minutes. That's all. Your back will love it.", NudgeCategory.movement),

    // ── BREATHE ───────────────────────────────────────────────────────────
    NudgeMessage("Take a deep breath in… hold… let it out. Nicer, right?", NudgeCategory.breathe),
    NudgeMessage("Box breathing: in 4, hold 4, out 4, hold 4. Try it.",  NudgeCategory.breathe),
    NudgeMessage("Breathe in for 4 counts. Out for 6. Reset your nervous system.", NudgeCategory.breathe),
    NudgeMessage("Slow down. Breathe. The internet isn't going anywhere.", NudgeCategory.breathe),
    NudgeMessage("Three deep breaths. In through the nose, out through the mouth.", NudgeCategory.breathe),

    // ── SLEEP ─────────────────────────────────────────────────────────────
    NudgeMessage("It's late. The content will survive without you. Sleep.", NudgeCategory.sleep),
    NudgeMessage("Screens at night mess with your sleep. Goodnight!",     NudgeCategory.sleep),
    NudgeMessage("Future you needs 8 hours. Put the phone down.",         NudgeCategory.sleep),
    NudgeMessage("Night mode hint: the best filter is sleep.",            NudgeCategory.sleep),

    // ── GENERAL WELLNESS ─────────────────────────────────────────────────
    NudgeMessage("You good? Like, actually good? Take a second.",         NudgeCategory.general),
    NudgeMessage("Quick wellness check: water, posture, breathing. Tick all three?", NudgeCategory.general),
    NudgeMessage("Hey. Step outside for 5 minutes if you can. Vitamin D!", NudgeCategory.general),
    NudgeMessage("A little fresh air never hurt anyone. Just saying.",    NudgeCategory.general),
    NudgeMessage("You've got this. But also — take a break.",             NudgeCategory.general),
  ];

  /// Get all messages for a given category.
  static List<NudgeMessage> forCategory(NudgeCategory cat) =>
      all.where((m) => m.category == cat).toList();

  /// Get messages for a category, optionally filtered to a specific app label.
  static List<NudgeMessage> forCategoryAndApp(NudgeCategory cat, String? appLabel) {
    final appSpecific = all
        .where((m) => m.category == cat && m.appLabel != null &&
            appLabel != null &&
            appLabel.toLowerCase().contains(m.appLabel!.toLowerCase()))
        .toList();
    if (appSpecific.isNotEmpty) return appSpecific;
    return all.where((m) => m.category == cat && m.appLabel == null).toList();
  }
}
