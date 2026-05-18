import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/personality/pet_profile.dart';
import '../../core/personality/pet_profile_repository.dart';
import '../../core/reminders/reminder.dart';
import '../../core/reminders/reminder_manager.dart';
import '../../core/tts/tts_engine.dart';

// ──────────────────────────────────────────────────────────────
// Dashboard screen — ConsumerStatefulWidget so we can watch
// AppLifecycleState and re-check the overlay permission whenever
// the user returns from Android Settings.
// ──────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  bool _overlayPermGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOverlayPerm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check every time the app comes back to foreground
  // (e.g. user just granted permission in Android Settings).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshOverlayPerm();
  }

  Future<void> _refreshOverlayPerm() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (mounted) setState(() => _overlayPermGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(petProfileProvider);
    final reminders = ref.watch(reminderManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketPet 🐾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
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
                leading: CircleAvatar(
                  child: Text(
                    _petEmoji(profile.petId),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                title: Text(profile.name),
                subtitle: Text('${profile.species} · ${profile.speechStyle}'),
                trailing: FilledButton.tonal(
                  onPressed: () => _launchOverlay(),
                  child: const Text('Launch'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Overlay control ---
          _SectionHeader('Overlay'),

          // Permission warning banner
          if (!_overlayPermGranted)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('"Draw over other apps" not granted'),
                subtitle: const Text(
                    'Tap Grant → enable PocketPet → come back → tap Show'),
                trailing: FilledButton(
                  onPressed: () async {
                    await FlutterOverlayWindow.requestPermission();
                  },
                  child: const Text('Grant'),
                ),
              ),
            ),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.layers_outlined,
                    color: _overlayPermGranted ? null : Colors.grey,
                  ),
                  title: const Text('Floating pet'),
                  subtitle: const Text('Show pet over other apps'),
                  trailing: FilledButton(
                    onPressed: _launchOverlay,
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
            onPressed: () => _showAddReminderDialog(context),
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
                  ref.read(petProfileProvider).whenData((profile) {
                    ref.read(ttsEngineProvider).speak(
                      "Hey ${profile.name}! Remember to drink some water. "
                      "Your body will thank you.",
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

  // ── Overlay launch with full feedback ────────────────────────────────────

  Future<void> _launchOverlay() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enable "Display over other apps" for PocketPet, '
              'then come back and tap Show.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    try {
      await FlutterOverlayWindow.showOverlay(
        height: -1, // MATCH_PARENT
        width: -1,  // MATCH_PARENT
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Overlay error: $e')),
        );
      }
    }
  }

  // ── Bottom sheets / dialogs ───────────────────────────────────────────────

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => _SettingsSheet(
        onPetChanged: () {
          ref.invalidate(petProfileProvider);
        },
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddReminderDialog(
        onAdd: (r) => ref.read(reminderManagerProvider.notifier).add(r),
      ),
    );
  }

  static String _petEmoji(String petId) => switch (petId) {
    'boba'      => '🟣',
    'axobotl'   => '🐸',
    'bitboy'    => '🤖',
    'nova_byte' => '⭐',
    _           => '🐾',
  };
}

// ──────────────────────────────────────────────────────────────
// Section header
// ──────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────
// Reminder tile
// ──────────────────────────────────────────────────────────────
class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(_icon(reminder.type),
            style: const TextStyle(fontSize: 28)),
        title: Text(reminder.label),
        subtitle: Text(reminder.time.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.enabled,
              onChanged: (_) => ref
                  .read(reminderManagerProvider.notifier)
                  .toggle(reminder.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => ref
                  .read(reminderManagerProvider.notifier)
                  .remove(reminder.id),
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

// ──────────────────────────────────────────────────────────────
// Settings bottom sheet
// ──────────────────────────────────────────────────────────────
class _SettingsSheet extends ConsumerWidget {
  final VoidCallback onPetChanged;
  const _SettingsSheet({required this.onPetChanged});

  static const _permChannel = MethodChannel('pocketpet/permissions');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // ── Change pet ─────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('Change pet'),
            subtitle: const Text('Pick a different companion'),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onTap: () {
              // close settings first, then open pet picker
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) =>
                    _ChangePetSheet(onChanged: onPetChanged),
              );
            },
          ),
          const Divider(height: 24),

          // ── Permissions ────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification access'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () =>
                _permChannel.invokeMethod('openNotificationListenerSettings'),
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
            onTap: () =>
                _permChannel.invokeMethod('openAccessibilitySettings'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Change pet bottom sheet
// ──────────────────────────────────────────────────────────────
class _ChangePetSheet extends ConsumerWidget {
  final VoidCallback onChanged;
  const _ChangePetSheet({required this.onChanged});

  static const _pets = [
    ('boba',      'Boba',      '🟣', 'blob'),
    ('axobotl',   'Axobotl',   '🐸', 'axolotl'),
    ('bitboy',    'Bitboy',    '🤖', 'robot'),
    ('nova_byte', 'Nova Byte', '⭐', 'star'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId =
        ref.watch(petProfileProvider).valueOrNull?.petId ?? 'boba';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your pet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Tap to switch companions',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ..._pets.map((p) {
            final (id, name, emoji, species) = p;
            final selected = currentId == id;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: selected
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: Text(emoji,
                    style: const TextStyle(fontSize: 36)),
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(species),
                trailing: selected
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: selected
                    ? null
                    : () async {
                        final repo = ref.read(petProfileRepositoryProvider);
                        final current = await repo.load();
                        await repo.save(
                            current.copyWith(petId: id, species: species));
                        ref.invalidate(petProfileProvider);
                        onChanged();
                        if (context.mounted) Navigator.pop(context);
                      },
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Add reminder dialog (unchanged)
// ──────────────────────────────────────────────────────────────
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
            items: ReminderType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                .toList(),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Time'),
            subtitle: Text(
              '${_hour.toString().padLeft(2, '0')}:'
              '${_minute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _hour, minute: _minute),
              );
              if (picked != null) {
                setState(() {
                  _hour = picked.hour;
                  _minute = picked.minute;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
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
