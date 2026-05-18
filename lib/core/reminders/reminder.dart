import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;

export 'package:flutter/material.dart' show TimeOfDay;

enum ReminderType { water, eyeBreak, posture, movement, breathe, custom, sleep }

class Reminder extends Equatable {
  final String id;
  final String label;
  final ReminderType type;
  final int hour;
  final int minute;
  final List<bool> weekdays; // Mon=0 … Sun=6
  final bool enabled;
  final String? customText;

  const Reminder({
    required this.id,
    required this.label,
    required this.type,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.enabled = true,
    this.customText,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  String get speakText => customText ?? _defaultText(type);

  static String _defaultText(ReminderType t) => switch (t) {
        ReminderType.water =>
          'Reminder! Drink a glass of water right now.',
        ReminderType.eyeBreak =>
          'Eye break! Look away from your screen for 20 seconds.',
        ReminderType.posture =>
          'Posture check! Sit up straight and roll your shoulders back.',
        ReminderType.movement =>
          'Movement time! Stand up and stretch for a minute.',
        ReminderType.breathe =>
          'Take a deep breath in… hold… and slowly let it out.',
        ReminderType.sleep =>
          "It's getting late. Time to wind down and put the phone down.",
        ReminderType.custom => 'Hey! Your reminder is going off.',
      };

  Reminder copyWith({bool? enabled}) => Reminder(
        id: id,
        label: label,
        type: type,
        hour: hour,
        minute: minute,
        weekdays: weekdays,
        enabled: enabled ?? this.enabled,
        customText: customText,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'hour': hour,
        'minute': minute,
        'weekdays': weekdays,
        'enabled': enabled,
        'customText': customText,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        label: j['label'] as String,
        type: ReminderType.values.byName(j['type'] as String),
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        weekdays: List<bool>.from(j['weekdays'] as List),
        enabled: j['enabled'] as bool? ?? true,
        customText: j['customText'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, type, hour, minute, weekdays, enabled, customText];
}
