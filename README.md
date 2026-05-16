# PocketPet Flutter — AI Android Buddy

> A pixel-art pet that lives on your Android screen, watches your screen time, and nudges you to take breaks — using **Android's built-in TTS engine**. No cloud. No AI models to download. Works on any Android 8+ phone.

---

## What It Does

| Feature | How |
|---|---|
| Floating pixel-art pet | System overlay (`flutter_overlay_window`), drag anywhere |
| Screen time nudges | Reads Android `UsageStatsManager`, fires 85 pre-written messages |
| Speaks nudges | Android built-in TTS (`flutter_tts`) — no model download |
| Scheduled reminders | Water 💧 · Eye break 👁️ · Stretch 🧘 · Sleep 🌙 · Custom |
| Reacts to notifications | `NotificationListenerService` → pet gets excited |
| Quick Settings tile | One-tap nudge summary from notification shade |
| Pet personalities | Boba · Axobotl · Bitboy · Nova Byte |

---

## Nudge System

**85 handcrafted messages** across 11 categories, triggered dynamically:

| Trigger | What fires |
|---|---|
| 5–14 mins on any app | Light check-in |
| 15–29 mins on any app | Medium nudge (app-specific if Instagram/YouTube/TikTok/etc.) |
| 30–59 mins on app | Strong nudge with personality |
| 60+ mins | Intervention-level message |
| Every 20 mins | Eye break (20-20-20 rule) |
| Every 45 mins | Water reminder |
| Every 30 mins | Posture check |
| Every 60 mins | Movement/stretch |
| Every 90 mins | Breathe reminder |
| After 11pm | Sleep nudge |

App-specific messages exist for: **Instagram, YouTube, TikTok, Twitter/X, Reddit, Facebook, Snapchat, LinkedIn**

---

## Requirements

| Item | Minimum |
|---|---|
| Android | 8.0 (API 26) |
| Flutter | 3.22+ (Dart 3.3+) |
| Android Studio | Hedgehog 2023.1.1+ with Flutter plugin |
| Java | 17 |
| RAM (device) | 2 GB (no heavy AI, very lightweight) |

---

## Step-by-Step: Build & Run

### 1. Install Flutter

> Skip if you already have Flutter. Check with `flutter doctor`.

- Download from [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
- Extract to `C:\flutter` and add `C:\flutter\bin` to PATH
- Run `flutter doctor` and fix any issues shown

### 2. Clone the repo

```bash
git clone https://github.com/pragarocks/AiAndroidBuddyFlutter.git
cd AiAndroidBuddyFlutter
```

### 3. Open in Android Studio

- Open Android Studio → **File → Open** → select the `AiAndroidBuddyFlutter` folder
- Android Studio detects Flutter automatically (install Flutter plugin if prompted)
- Wait for **Gradle sync** to complete (downloads dependencies, ~2-4 min first time)

### 4. Add spritesheet assets (required for pet animation)

The `spritesheet.webp` files are not in git (use assets from the Kotlin version):

```bash
# Copy spritesheets from the Kotlin repo's assets/
cp ../AiAndroidBuddy/app/src/main/assets/pets/boba/spritesheet.webp      assets/pets/boba/
cp ../AiAndroidBuddy/app/src/main/assets/pets/axobotl/spritesheet.webp   assets/pets/axobotl/
cp ../AiAndroidBuddy/app/src/main/assets/pets/bitboy/spritesheet.webp    assets/pets/bitboy/
```

> **No spritesheets?** The overlay falls back to a purple circle icon. All nudges, TTS, and reminders still work fully.

### 5. Run the app

Connect a physical Android device (USB debugging on) or start an emulator, then:

```bash
flutter run
```

Or click **Run ▶** in Android Studio. Select `liteDebug` build variant.

### 6. Grant permissions (first launch — Onboarding)

The onboarding guides you through:

1. **Choose pet** → Boba, Axobotl, Bitboy, or Nova Byte
2. **Name it**
3. **Set personality** (Care / Chaos / Wisdom / Snark / Patience)
4. **Permissions**:
   - **Draw over other apps** → tap Grant → toggle PocketPet on → back
   - **Notification access** → tap Grant → toggle PocketPet on → back
   - **Usage stats** → tap Grant → toggle PocketPet on → back *(required for nudges)*

### 7. Launch the floating pet

On the Dashboard, tap **Launch** — the pet appears as a floating widget above all apps. Drag it anywhere.

### 8. Try a nudge

Dashboard → **"Speak a nudge"** → tap play. Your pet will speak a message through your speaker.

---

## Project Structure

```
lib/
├── main.dart                   App entry + WorkManager setup + overlay entry
├── app.dart                    GoRouter + MaterialApp
├── core/
│   ├── pet/                    PetState, PetStateMachine, SpriteAnimator, PetLoader
│   ├── nudge/                  NudgeMessage (85 msgs), NudgeScheduler
│   ├── screentime/             ScreenTimeService (platform channel → UsageStatsManager)
│   ├── tts/                    TtsEngine (flutter_tts wrapper)
│   ├── reminders/              Reminder, ReminderManager (local notifications + TTS)
│   ├── notifications/          NotificationItem, NotificationRepository (EventChannel)
│   └── personality/            PetProfile, PetProfileRepository (SharedPreferences)
├── overlay/                    PetOverlayWidget, PetPainter (Canvas), SpeechBubbleWidget
├── ui/
│   ├── onboarding/             5-step onboarding flow
│   ├── dashboard/              Dashboard + reminder management + settings
│   └── theme/                  Material 3 theme
└── di/                         (Riverpod providers — co-located with their classes)

android/app/src/main/kotlin/com/pocketpet/
├── MainActivity.kt             Registers all MethodChannels + EventChannel
├── plugins/
│   ├── ScreenTimePlugin.kt     Wraps UsageStatsManager
│   └── NotificationPlugin.kt  Bridges NotificationListenerService → EventChannel
└── services/
    ├── PetNotificationService.kt   NotificationListenerService
    ├── PetAccessibilityService.kt  AccessibilityService (stub, for future actions)
    ├── QuickSummaryTileService.kt  Quick Settings tile
    └── BootReceiver.kt             Restarts WorkManager on reboot

test/
├── core/pet/pet_state_machine_test.dart   13 state transition tests
├── core/nudge/nudge_message_test.dart     11 nudge library tests
├── core/reminders/reminder_test.dart      6 reminder model tests
└── widget_test.dart                       Smoke tests
```

---

## Key Technical Decisions

| Decision | Why |
|---|---|
| **flutter_tts** (Android built-in) | No model download, works offline, instant start, zero RAM overhead |
| **Removed MNN / ONNX** | Added as future feature when on-device LLM is needed; keeps app <10MB |
| **WorkManager** for nudge scheduler | Survives app kill, battery-friendly, Android recommended approach |
| **Riverpod** for state | Testable, compile-safe, no BuildContext dependency in logic |
| **flutter_overlay_window** | Best-maintained Flutter overlay package, handles WindowManager complexity |
| **UsageStatsManager** | Official Android API for screen time — same data as Digital Wellbeing |

---

## Running Tests

```bash
flutter test
```

Expected output:
```
✓ PetStateMachine: initial state is idle
✓ PetStateMachine: NotificationArrived → excited
... (13 state machine tests)
✓ NudgeLibrary: has at least 80 messages
✓ NudgeLibrary: every category has at least one message
... (11 nudge tests)
✓ Reminder: toJson / fromJson round-trip
... (6 reminder tests)
✓ Smoke tests (4)
All tests passed.
```

---

## Adding New Nudge Messages

Edit `lib/core/nudge/nudge_message.dart` — add a new `NudgeMessage` to the `all` list:

```dart
NudgeMessage("Your message here.", NudgeCategory.water),
// or app-specific:
NudgeMessage("Put down Netflix, bro.", NudgeCategory.screenTimeHeavy, 'Netflix'),
```

Run `flutter test` to verify no duplicates and all categories are covered.

---

## Roadmap

- [ ] On-device LLM (Qwen3.5 via MNN) for personalised nudge generation
- [ ] Wake keyword detector
- [ ] Whisper ASR for voice commands
- [ ] Smart contact priority (detect important senders)
- [ ] Pet Petdex — downloadable pet packs
- [ ] Night mode auto-detection
- [ ] Home screen widget

---

## Privacy

- No notification content leaves the device
- No analytics, no accounts, no telemetry
- Screen time data stays in-process (never logged)
- Voice/TTS processed by Android system engine locally

---

## License

MIT — see [LICENSE](LICENSE) for details.
