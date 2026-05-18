import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../tts/tts_engine.dart';
import '../pet/pet_state.dart';
import '../pet/pet_state_machine.dart';
import 'reminder.dart';

class ReminderManager extends StateNotifier<List<Reminder>> {
  final TtsEngine _tts;
  final PetStateMachine _stateMachine;
  final _notifications = FlutterLocalNotificationsPlugin();

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
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request exact-alarm permission (Android 12+)
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

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

    final androidDetails = AndroidNotificationDetails(
      'reminders_${reminder.type.name}',
      'PocketPet Reminders',
      channelDescription: 'Wellness reminders from your pet',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
    );

    // Schedule repeating daily at the reminder's time
    _notifications.zonedSchedule(
      id,
      'PocketPet 🐾',
      reminder.label,
      _nextInstanceOfTime(reminder.hour, reminder.minute),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final reminder = state.firstWhere(
      (r) => r.id.hashCode.abs() % 100000 == response.id,
      orElse: () => state.first,
    );
    _stateMachine.send(const ReminderSpoken());
    _tts.speak(reminder.speakText);
  }

  /// Called from WorkManager every minute to speak due reminders as backup.
  Future<void> speakDueReminders() async {
    final now = DateTime.now();
    for (final reminder in state) {
      if (!reminder.enabled) continue;
      final weekdayIndex = now.weekday - 1;
      if (!reminder.weekdays[weekdayIndex]) continue;
      if (reminder.hour == now.hour && reminder.minute == now.minute) {
        _stateMachine.send(const ReminderSpoken());
        await _tts.speak(reminder.speakText);
        break;
      }
    }
  }

  Future<void> add(Reminder reminder) async {
    state = [...state, reminder];
    _schedule(reminder);
    await _saveToPrefs();
  }

  Future<void> toggle(String id) async {
    state = state
        .map((r) => r.id == id ? r.copyWith(enabled: !r.enabled) : r)
        .toList();
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

  static List<Reminder> _defaultReminders() => [
        const Reminder(
          id: 'water_am',
          label: 'Morning water 💧',
          type: ReminderType.water,
          hour: 10,
          minute: 0,
          weekdays: [true, true, true, true, true, true, true],
        ),
        const Reminder(
          id: 'water_pm',
          label: 'Afternoon water 💧',
          type: ReminderType.water,
          hour: 14,
          minute: 0,
          weekdays: [true, true, true, true, true, true, true],
        ),
        const Reminder(
          id: 'eye_break',
          label: 'Eye break 👁️',
          type: ReminderType.eyeBreak,
          hour: 15,
          minute: 30,
          weekdays: [true, true, true, true, true, false, false],
        ),
        const Reminder(
          id: 'stretch',
          label: 'Stretch break 🧘',
          type: ReminderType.movement,
          hour: 12,
          minute: 0,
          weekdays: [true, true, true, true, true, true, true],
        ),
        const Reminder(
          id: 'sleep',
          label: 'Wind down 🌙',
          type: ReminderType.sleep,
          hour: 22,
          minute: 30,
          weekdays: [true, true, true, true, true, true, true],
        ),
      ];
}

final reminderManagerProvider =
    StateNotifierProvider<ReminderManager, List<Reminder>>(
  (ref) => ReminderManager(
    tts: ref.read(ttsEngineProvider),
    stateMachine: ref.read(petStateMachineProvider.notifier),
  ),
);
