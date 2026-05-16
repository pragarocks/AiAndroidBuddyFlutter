import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'core/nudge/nudge_scheduler.dart';
import 'core/reminders/reminder_manager.dart';
import 'core/screentime/screen_time_service.dart';
import 'core/tts/tts_engine.dart';
import 'core/pet/pet_state_machine.dart';
import 'overlay/pet_overlay_widget.dart';

// ──────────────────────────────────────────────────────────────
// WorkManager task names
// ──────────────────────────────────────────────────────────────
const _kNudgeTask = 'pocketpet.nudge_tick';
const _kReminderTask = 'pocketpet.reminder_check';

/// WorkManager callback — runs in a separate isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final container = ProviderContainer();
    try {
      switch (taskName) {
        case _kNudgeTask:
          final scheduler = container.read(nudgeSchedulerProvider);
          await scheduler.restoreLastNudgeTime();
          await scheduler.tick();
        case _kReminderTask:
          final manager = container.read(reminderManagerProvider.notifier);
          await manager.speakDueReminders();
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      container.dispose();
    }
  });
}

/// Overlay entry point — runs in a separate Flutter engine instance.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PetOverlayWidget(),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────
// Normal app entry point
// ──────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register WorkManager background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Nudge scheduler — runs every 5 minutes
  await Workmanager().registerPeriodicTask(
    _kNudgeTask,
    _kNudgeTask,
    frequency: const Duration(minutes: 5),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  // Reminder checker — runs every minute to match scheduled times
  await Workmanager().registerPeriodicTask(
    _kReminderTask,
    _kReminderTask,
    frequency: const Duration(minutes: 1),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  runApp(const ProviderScope(child: PocketPetApp()));
}
