import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tts/tts_engine.dart';
import '../pet/pet_state.dart';
import '../pet/pet_state_machine.dart';
import 'reminder.dart';

class ReminderManager extends StateNotifier<List<Reminder>> {
  final TtsEngine _tts;
  final PetStateMachine _stateMachine;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _prefKey = 'reminders_v1';

  ReminderManager({
    required TtsEngine tts,
    required PetStateMachine stateMachine,
  })  : _tts = tts,
        _stateMachine = stateMachine,
        super([]) {
    _init();
  }

  Future<void> _init() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _loadFromPrefs();
    _scheduleAll();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) {
      state = _defaultReminders();
      return;
    }
    final list = (jsonDecode(raw) as List)
        .map((j) => Reminder.fromJson(j as Map<String, dynamic>))
        .toList();
    state = list;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, jsonEncode(state.map((r) => r.toJson()).toList()));
  }

  void _scheduleAll() {
    for (final reminder in state) {
      if (reminder.enabled) _schedule(reminder);
    }
  }

  void _schedule(Reminder reminder) {
    final id = reminder.id.hashCode.abs() % 100000;
    final now = DateTime.now();
    var scheduled = DateTime(
        now.year, now.month, now.day, reminder.time.hour, reminder.time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'reminders_${reminder.type.name}',
      'PocketPet Reminders',
      channelDescription: 'Wellness reminders from your pet',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false, // pet speaks it via TTS instead
    );

    _notifications.zonedSchedule(
      id,
      'PocketPet 🐾',
      reminder.label,
      _toTZDateTime(scheduled),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // When the user taps the notification, pet speaks the reminder
    final reminder = state.firstWhere(
      (r) => r.id.hashCode.abs() % 100000 == response.id,
      orElse: () => state.first,
    );
    _stateMachine.send(const ReminderSpoken());
    _tts.speak(reminder.speakText);
  }

  /// Called from WorkManager to also speak reminders in the background.
  Future<void> speakDueReminders() async {
    final now = DateTime.now();
    for (final reminder in state) {
      if (!reminder.enabled) continue;
      final weekdayIndex = now.weekday - 1; // Dart: Mon=1 → 0-based index
      if (!reminder.weekdays[weekdayIndex]) continue;
      if (reminder.time.hour == now.hour && reminder.time.minute == now.minute) {
        _stateMachine.send(const ReminderSpoken());
        await _tts.speak(reminder.speakText);
        break; // speak one at a time
      }
    }
  }

  Future<void> add(Reminder reminder) async {
    state = [...state, reminder];
    _schedule(reminder);
    await _saveToPrefs();
  }

  Future<void> toggle(String id) async {
    state = state.map((r) => r.id == id ? r.copyWith(enabled: !r.enabled) : r).toList();
    final reminder = state.firstWhere((r) => r.id == id);
    if (reminder.enabled) {
      _schedule(reminder);
    } else {
      await _notifications.cancel(id.hashCode.abs() % 100000);
    }
    await _saveToPrefs();
  }

  Future<void> remove(String id) async {
    await _notifications.cancel(id.hashCode.abs() % 100000);
    state = state.where((r) => r.id != id).toList();
    await _saveToPrefs();
  }

  // Helpers
  static _TZDateTime _toTZDateTime(DateTime dt) => _TZDateTime.from(dt);

  static List<Reminder> _defaultReminders() => [
    Reminder(
      id: 'water_default',
      label: 'Drink water 💧',
      type: ReminderType.water,
      time: const TimeOfDay(hour: 10, minute: 0),
      weekdays: List.filled(7, true),
    ),
    Reminder(
      id: 'water_pm',
      label: 'Afternoon water 💧',
      type: ReminderType.water,
      time: const TimeOfDay(hour: 14, minute: 0),
      weekdays: List.filled(7, true),
    ),
    Reminder(
      id: 'eye_break',
      label: 'Eye break 👁️',
      type: ReminderType.eyeBreak,
      time: const TimeOfDay(hour: 15, minute: 30),
      weekdays: [true, true, true, true, true, false, false], // weekdays
    ),
    Reminder(
      id: 'stretch',
      label: 'Stretch break 🧘',
      type: ReminderType.movement,
      time: const TimeOfDay(hour: 12, minute: 0),
      weekdays: List.filled(7, true),
    ),
    Reminder(
      id: 'sleep',
      label: 'Wind down 🌙',
      type: ReminderType.sleep,
      time: const TimeOfDay(hour: 22, minute: 30),
      weekdays: List.filled(7, true),
    ),
  ];
}

// Minimal TZDateTime shim (timezone package would be full replacement)
class _TZDateTime {
  final DateTime _dt;
  const _TZDateTime._(this._dt);
  static _TZDateTime from(DateTime dt) => _TZDateTime._(dt);
}

final reminderManagerProvider =
    StateNotifierProvider<ReminderManager, List<Reminder>>(
  (ref) => ReminderManager(
    tts: ref.read(ttsEngineProvider),
    stateMachine: ref.read(petStateMachineProvider.notifier),
  ),
);
