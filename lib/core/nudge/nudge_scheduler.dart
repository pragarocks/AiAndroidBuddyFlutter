import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screentime/screen_time_service.dart';
import '../tts/tts_engine.dart';
import '../pet/pet_state.dart';
import '../pet/pet_state_machine.dart';
import 'nudge_message.dart';

/// Minimum gap between any two nudges (prevent spamming).
const _kMinNudgeGapMinutes = 8;

class NudgeScheduler {
  final ScreenTimeService _screenTime;
  final TtsEngine _tts;
  final PetStateMachine _stateMachine;
  final _rng = Random();

  DateTime? _lastNudge;
  DateTime? _lastWater;
  DateTime? _lastEyeBreak;
  DateTime? _lastPosture;
  DateTime? _lastMovement;
  DateTime? _lastBreathe;

  NudgeScheduler({
    required ScreenTimeService screenTime,
    required TtsEngine tts,
    required PetStateMachine stateMachine,
  })  : _screenTime = screenTime,
        _tts = tts,
        _stateMachine = stateMachine;

  /// Called by WorkManager every ~5 minutes.
  Future<void> tick() async {
    final now = DateTime.now();

    // --- Wellness nudges (time-based, not app-specific) ---
    if (_shouldNudge(_lastWater, 45, now)) {
      await _deliver(NudgeCategory.water, now);
      _lastWater = now;
      return;
    }
    if (_shouldNudge(_lastEyeBreak, 20, now)) {
      await _deliver(NudgeCategory.eyeBreak, now);
      _lastEyeBreak = now;
      return;
    }
    if (_shouldNudge(_lastPosture, 30, now)) {
      await _deliver(NudgeCategory.posture, now);
      _lastPosture = now;
      return;
    }
    if (_shouldNudge(_lastMovement, 60, now)) {
      await _deliver(NudgeCategory.movement, now);
      _lastMovement = now;
      return;
    }
    if (_shouldNudge(_lastBreathe, 90, now)) {
      await _deliver(NudgeCategory.breathe, now);
      _lastBreathe = now;
      return;
    }

    // Night mode — late night (11pm–6am) sleep nudge
    final hour = now.hour;
    if (hour >= 23 || hour < 6) {
      if (_shouldNudge(_lastNudge, 30, now)) {
        await _deliver(NudgeCategory.sleep, now);
        return;
      }
    }

    // --- Screen time nudges ---
    if (!(await _screenTime.hasPermission())) return;

    final stats = await _screenTime.getUsageStats(hours: 1);
    if (stats.isEmpty) return;

    // Find the top-used app in the last 60 minutes
    final top = stats.first;
    final mins = top.usageMinutes;
    final appLabel = top.appLabel;

    final cat = _categoryForMinutes(mins);
    if (cat != null && _shouldNudge(_lastNudge, _kMinNudgeGapMinutes, now)) {
      await _deliver(cat, now, appLabel: appLabel);
    }
  }

  NudgeCategory? _categoryForMinutes(int mins) {
    if (mins >= 60) return NudgeCategory.screenTimeExtreme;
    if (mins >= 30) return NudgeCategory.screenTimeHeavy;
    if (mins >= 15) return NudgeCategory.screenTimeMedium;
    if (mins >= 5)  return NudgeCategory.screenTimeLight;
    return null;
  }

  bool _shouldNudge(DateTime? last, int gapMinutes, DateTime now) {
    if (last == null) return true;
    return now.difference(last).inMinutes >= gapMinutes;
  }

  Future<void> _deliver(NudgeCategory cat, DateTime now, {String? appLabel}) async {
    final messages = NudgeLibrary.forCategoryAndApp(cat, appLabel);
    if (messages.isEmpty) return;

    final msg = messages[_rng.nextInt(messages.length)];
    _lastNudge = now;

    _stateMachine.send(const NudgeTriggered());
    await _tts.speak(msg.text);
    _stateMachine.send(const NudgeDelivered());

    // Persist last nudge time so WorkManager restarts don't re-fire immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_nudge', now.toIso8601String());
  }

  Future<void> restoreLastNudgeTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('last_nudge');
    if (raw != null) _lastNudge = DateTime.tryParse(raw);
  }
}

final nudgeSchedulerProvider = Provider((ref) => NudgeScheduler(
  screenTime: ref.read(screenTimeServiceProvider),
  tts: ref.read(ttsEngineProvider),
  stateMachine: ref.read(petStateMachineProvider.notifier),
));
