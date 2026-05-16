import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/personality/pet_profile_repository.dart';
import '../../core/reminders/reminder.dart';
import '../../core/reminders/reminder_manager.dart';
import '../../core/tts/tts_engine.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(petProfileProvider);
    final reminders = ref.watch(reminderManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketPet 🐾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Pet info card ---
          profileAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (profile) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.pets)),
                title: Text(profile.name),
                subtitle: Text('${profile.species} · ${profile.speechStyle}'),
                trailing: FilledButton.tonal(
                  onPressed: () => _launchOverlay(context, ref),
                  child: const Text('Launch'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Overlay control ---
          _SectionHeader('Overlay'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.layers_outlined),
                  title: const Text('Floating pet'),
                  subtitle: const Text('Show pet over other apps'),
                  trailing: FilledButton(
                    onPressed: () => _launchOverlay(context, ref),
                    child: const Text('Show'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.layers_clear_outlined),
                  title: const Text('Hide pet'),
                  trailing: OutlinedButton(
                    onPressed: () => FlutterOverlayWindow.closeOverlay(),
                    child: const Text('Hide'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Reminders ---
          _SectionHeader('Reminders'),
          ...reminders.map((r) => _ReminderTile(reminder: r)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddReminderDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add reminder'),
          ),
          const SizedBox(height: 16),

          // --- TTS Test ---
          _SectionHeader('Test your pet'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.record_voice_over_outlined),
              title: const Text('Speak a nudge'),
              subtitle: const Text('Hear what your pet sounds like'),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  profileAsync.whenData((profile) {
                    ref.read(ttsEngineProvider).speak(
                      'Hey ${profile.name}! Remember to drink some water. Your body will thank you.',
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchOverlay(BuildContext context, WidgetRef ref) async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }
    await FlutterOverlayWindow.showOverlay(
      height: -1, // WindowSize.matchParent
      width: -1,  // WindowSize.matchParent
      alignment: OverlayAlignment.center,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _SettingsSheet(),
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AddReminderDialog(onAdd: (r) => ref.read(reminderManagerProvider.notifier).add(r)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    )),
  );
}

class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(_icon(reminder.type), style: const TextStyle(fontSize: 28)),
        title: Text(reminder.label),
        subtitle: Text(reminder.time.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.enabled,
              onChanged: (_) => ref.read(reminderManagerProvider.notifier).toggle(reminder.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => ref.read(reminderManagerProvider.notifier).remove(reminder.id),
            ),
          ],
        ),
      ),
    );
  }

  String _icon(ReminderType t) => switch (t) {
    ReminderType.water    => '💧',
    ReminderType.eyeBreak => '👁️',
    ReminderType.posture  => '🧍',
    ReminderType.movement => '🏃',
    ReminderType.breathe  => '🌬️',
    ReminderType.sleep    => '🌙',
    ReminderType.custom   => '⏰',
  };
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  static const _permChannel = MethodChannel('pocketpet/permissions');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification access'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _permChannel.invokeMethod('openNotificationListenerSettings'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Screen time (usage stats)'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _permChannel.invokeMethod('openUsageSettings'),
          ),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Draw over other apps'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _permChannel.invokeMethod('openOverlaySettings'),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_outlined),
            title: const Text('Accessibility service'),
            subtitle: const Text('For notification actions (optional)'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () async {
              const intent = MethodChannel('pocketpet/permissions');
              await intent.invokeMethod('openAccessibilitySettings');
            },
          ),
        ],
      ),
    );
  }
}

class _AddReminderDialog extends StatefulWidget {
  final void Function(Reminder) onAdd;
  const _AddReminderDialog({required this.onAdd});

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  ReminderType _type = ReminderType.water;
  int _hour = 10;
  int _minute = 0;
  final _labelCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _labelCtrl,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const SizedBox(height: 12),
          DropdownButton<ReminderType>(
            isExpanded: true,
            value: _type,
            onChanged: (v) => setState(() => _type = v!),
            items: ReminderType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.name),
            )).toList(),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Time'),
            subtitle: Text('${_hour.toString().padLeft(2,'0')}:${_minute.toString().padLeft(2,'0')}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _hour, minute: _minute),
              );
              if (picked != null) {
                setState(() { _hour = picked.hour; _minute = picked.minute; });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            widget.onAdd(Reminder(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              label: _labelCtrl.text.isNotEmpty ? _labelCtrl.text : _type.name,
              type: _type,
              hour: _hour,
              minute: _minute,
              weekdays: List.filled(7, true),
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
