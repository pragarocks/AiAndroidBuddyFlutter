import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/personality/pet_profile.dart';
import '../../core/personality/pet_profile_repository.dart';
import '../../core/reminders/reminder.dart';
import '../../core/reminders/reminder_manager.dart';
import '../../core/tts/tts_engine.dart';

// ── Pet catalogue ──────────────────────────────────────────────────────────
const _kPets = [
  ('boba',        'Boba',       '🟣', 'blob'),
  ('axobotl',     'Axobotl',    '🐸', 'axolotl'),
  ('bitboy',      'Bitboy',     '🤖', 'robot'),
  ('nova_byte',   'Nova Byte',  '⭐', 'star'),
  ('valkyrie',    'Valkyrie',   '⚔️', 'warrior'),
  ('snuglet',     'Snuglet',    '🐱', 'cat'),
  ('review-owl',  'Review Owl', '🦉', 'owl'),
];

// ── Colors ─────────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF0D1117);
const _kSurface  = Color(0xFF161B22);
const _kBorder   = Color(0xFF30363D);
const _kNeon     = Color(0xFF39FF14);
const _kAccent   = Color(0xFF7C3AED);
const _kRed      = Color(0xFFFF5252);
const _kText     = Color(0xFFE6EDF3);
const _kSubtext  = Color(0xFF8B949E);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  bool _overlayGranted = false;
  bool _petRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final g = await FlutterOverlayWindow.isPermissionGranted();
    if (mounted) setState(() => _overlayGranted = g);
  }

  // ── Overlay control ────────────────────────────────────────────────────
  Future<void> _launchOverlay() async {
    if (!_overlayGranted) {
      await FlutterOverlayWindow.requestPermission();
      // Poll until granted (user returns from Settings)
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final g = await FlutterOverlayWindow.isPermissionGranted();
        if (g) { setState(() { _overlayGranted = true; }); break; }
      }
      if (!_overlayGranted) return;
    }
    await FlutterOverlayWindow.showOverlay(
      height: -1,  // MATCH_PARENT
      width: -1,   // MATCH_PARENT
      alignment: OverlayAlignment.center,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      enableDrag: false,
      overlayTitle: 'PocketPet',
      overlayContent: 'Your pet is alive!',
      flag: OverlayFlag.defaultFlag,
    );
    if (mounted) setState(() => _petRunning = true);
  }

  Future<void> _stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    if (mounted) setState(() => _petRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(petProfileProvider);
    final reminders    = ref.watch(reminderManagerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        foregroundColor: _kText,
        elevation: 0,
        title: Row(children: [
          Text('🐾 ', style: TextStyle(fontSize: 22)),
          Text('PocketPet', style: TextStyle(
            color: _kText, fontWeight: FontWeight.bold, fontSize: 20,
          )),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _kSubtext),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Pet card ───────────────────────────────────────────────────
          profileAsync.when(
            loading: () => const LinearProgressIndicator(color: _kAccent),
            error: (_, __) => const SizedBox.shrink(),
            data: (profile) => _GlassCard(
              child: Column(children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _kAccent.withOpacity(0.2),
                    child: Text(_petEmoji(profile.petId),
                        style: const TextStyle(fontSize: 26)),
                  ),
                  title: Text(profile.name,
                      style: const TextStyle(color: _kText, fontWeight: FontWeight.bold)),
                  subtitle: Text('${profile.species} · ${profile.speechStyle}',
                      style: const TextStyle(color: _kSubtext, fontSize: 12)),
                ),
                const Divider(color: _kBorder, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _petRunning
                      ? _ActionButton(
                          label: 'Stop PocketPet',
                          icon: Icons.stop_circle_outlined,
                          color: _kRed,
                          onTap: _stopOverlay,
                        )
                      : _ActionButton(
                          label: _overlayGranted ? 'Launch PocketPet' : 'Grant Permission First',
                          icon: Icons.rocket_launch_outlined,
                          color: _overlayGranted ? _kNeon : _kSubtext,
                          textColor: _overlayGranted ? _kBg : _kText,
                          onTap: _launchOverlay,
                        ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Permission banner ──────────────────────────────────────────
          if (!_overlayGranted)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                border: Border.all(color: _kRed.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: _kRed, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '"Draw over other apps" not granted. Tap Launch to enable.',
                    style: TextStyle(color: _kRed, fontSize: 12),
                  ),
                ),
              ]),
            ),

          // ── Reminders ─────────────────────────────────────────────────
          _SectionLabel('Reminders'),
          ...reminders.map((r) => _ReminderTile(reminder: r)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _kAccent,
              side: const BorderSide(color: _kAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showAddReminderDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add reminder'),
          ),
          const SizedBox(height: 16),

          // ── TTS test ──────────────────────────────────────────────────
          _SectionLabel('Test Your Pet'),
          _GlassCard(
            child: ListTile(
              leading: const Icon(Icons.record_voice_over_outlined, color: _kAccent),
              title: const Text('Speak a nudge', style: TextStyle(color: _kText)),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow, color: _kNeon),
                onPressed: () {
                  ref.read(petProfileProvider).whenData((p) {
                    ref.read(ttsEngineProvider).speak(
                      'Hey ${p.name}! Remember to drink some water!',
                    );
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SettingsSheet(onPetChanged: () => ref.invalidate(petProfileProvider)),
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

  static String _petEmoji(String id) => switch (id) {
    'boba'       => '🟣',
    'axobotl'    => '🐸',
    'bitboy'     => '🤖',
    'nova_byte'  => '⭐',
    'valkyrie'   => '⚔️',
    'snuglet'    => '🐱',
    'review-owl' => '🦉',
    _            => '🐾',
  };
}

// ── Reusable glass card ───────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: _kSurface,
      border: Border.all(color: _kBorder),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

// ── Section label ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text, style: const TextStyle(
      color: _kAccent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
    )),
  );
}

// ── Action button ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label, required this.icon,
    required this.color, required this.onTap,
    this.textColor = const Color(0xFF0D1117),
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ),
  );
}

// ── Reminder tile ─────────────────────────────────────────────────────────
class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderTile({required this.reminder});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _GlassCard(
    child: ListTile(
      leading: Text(_icon(reminder.type), style: const TextStyle(fontSize: 26)),
      title: Text(reminder.label, style: const TextStyle(color: _kText)),
      subtitle: Text(
        '${reminder.hour.toString().padLeft(2,'0')}:${reminder.minute.toString().padLeft(2,'0')}',
        style: const TextStyle(color: _kSubtext, fontSize: 12),
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Switch(
          value: reminder.enabled,
          activeColor: _kNeon,
          onChanged: (_) => ref.read(reminderManagerProvider.notifier).toggle(reminder.id),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: _kSubtext, size: 20),
          onPressed: () => ref.read(reminderManagerProvider.notifier).remove(reminder.id),
        ),
      ]),
    ),
  );
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

// ── Settings sheet ────────────────────────────────────────────────────────
class _SettingsSheet extends ConsumerWidget {
  final VoidCallback onPetChanged;
  const _SettingsSheet({required this.onPetChanged});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(petProfileProvider).valueOrNull?.petId ?? 'boba';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Your Pet', style: TextStyle(
            color: _kText, fontSize: 18, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 16),
          SizedBox(
            height: 340,
            child: ListView(children: _kPets.map((p) {
              final (id, name, emoji, species) = p;
              final selected = current == id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selected ? _kAccent.withOpacity(0.15) : _kSurface,
                  border: Border.all(color: selected ? _kAccent : _kBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 30)),
                  title: Text(name, style: const TextStyle(color: _kText, fontWeight: FontWeight.w600)),
                  subtitle: Text(species, style: const TextStyle(color: _kSubtext, fontSize: 12)),
                  trailing: selected ? const Icon(Icons.check_circle, color: _kAccent) : null,
                  onTap: selected ? null : () async {
                    final repo = ref.read(petProfileRepositoryProvider);
                    final cur  = await repo.load();
                    await repo.save(cur.copyWith(petId: id, species: species));
                    ref.invalidate(petProfileProvider);
                    onPetChanged();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              );
            }).toList()),
          ),
        ],
      ),
    );
  }
}

// ── Add reminder dialog ───────────────────────────────────────────────────
class _AddReminderDialog extends StatefulWidget {
  final void Function(Reminder) onAdd;
  const _AddReminderDialog({required this.onAdd});
  @override State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  ReminderType _type = ReminderType.water;
  int _hour = 10, _minute = 0;
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _kSurface,
    title: const Text('Add Reminder', style: TextStyle(color: _kText)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: _ctrl,
        style: const TextStyle(color: _kText),
        decoration: const InputDecoration(
          labelText: 'Label', labelStyle: TextStyle(color: _kSubtext),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButton<ReminderType>(
        isExpanded: true, value: _type,
        dropdownColor: _kSurface,
        style: const TextStyle(color: _kText),
        onChanged: (v) => setState(() => _type = v!),
        items: ReminderType.values.map((t) =>
          DropdownMenuItem(value: t, child: Text(t.name))).toList(),
      ),
      ListTile(
        title: const Text('Time', style: TextStyle(color: _kSubtext)),
        subtitle: Text(
          '${_hour.toString().padLeft(2,'0')}:${_minute.toString().padLeft(2,'0')}',
          style: const TextStyle(color: _kText),
        ),
        trailing: const Icon(Icons.access_time, color: _kSubtext),
        onTap: () async {
          final p = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: _hour, minute: _minute),
          );
          if (p != null) setState(() { _hour = p.hour; _minute = p.minute; });
        },
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: _kSubtext))),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _kAccent),
        onPressed: () {
          widget.onAdd(Reminder(
            id: 'r_${DateTime.now().millisecondsSinceEpoch}',
            label: _ctrl.text.isNotEmpty ? _ctrl.text : _type.name,
            type: _type, hour: _hour, minute: _minute,
            weekdays: List.filled(7, true),
          ));
          Navigator.pop(context);
        },
        child: const Text('Add'),
      ),
    ],
  );
}
