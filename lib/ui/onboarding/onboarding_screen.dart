import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/personality/pet_profile.dart';
import '../../core/personality/pet_profile_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _permChannel = MethodChannel('pocketpet/permissions');

  final _pageController = PageController();
  int _page = 0;

  // Collected values
  String _petId = 'boba';
  String _petName = 'Boba';
  PetStat _peakStat = PetStat.care;
  bool _overlayGranted = false;
  bool _notifGranted = false;
  bool _usageGranted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onNext: _next),
                  _PetPickerPage(
                    selectedId: _petId,
                    onSelected: (id) => setState(() => _petId = id),
                    onNext: _next,
                  ),
                  _NamePage(
                    name: _petName,
                    onChanged: (v) => setState(() => _petName = v),
                    onNext: _next,
                  ),
                  _PersonalityPage(
                    peak: _peakStat,
                    onChanged: (s) => setState(() => _peakStat = s),
                    onNext: _next,
                  ),
                  _PermissionsPage(
                    overlayGranted: _overlayGranted,
                    notifGranted: _notifGranted,
                    usageGranted: _usageGranted,
                    onRequestOverlay: _requestOverlay,
                    onRequestNotif: _requestNotif,
                    onRequestUsage: _requestUsage,
                    onNext: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LinearProgressIndicator(
        value: (_page + 1) / 5,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _next() {
    setState(() => _page++);
    _pageController.nextPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _requestOverlay() async {
    await _permChannel.invokeMethod('openOverlaySettings');
    await Future.delayed(const Duration(seconds: 1));
    final granted = await _permChannel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    setState(() => _overlayGranted = granted);
  }

  Future<void> _requestNotif() async {
    await _permChannel.invokeMethod('openNotificationListenerSettings');
    await Future.delayed(const Duration(seconds: 1));
    final granted = await _permChannel.invokeMethod<bool>('hasNotificationListenerPermission') ?? false;
    setState(() => _notifGranted = granted);
  }

  Future<void> _requestUsage() async {
    await _permChannel.invokeMethod('openUsageSettings');
    await Future.delayed(const Duration(seconds: 1));
    final granted = await _permChannel.invokeMethod<bool>('hasUsagePermission') ?? false;
    setState(() => _usageGranted = granted);
  }

  Future<void> _finish() async {
    final profile = PetProfile(
      petId: _petId,
      name: _petName,
      species: _petId,
      peakStat: _peakStat,
      dumpStat: PetStat.snark,
      speechStyle: 'short and playful',
    );
    await ref.read(petProfileRepositoryProvider).save(profile);
    await ref.read(petProfileRepositoryProvider).setOnboarded();
    if (mounted) context.go('/dashboard');
  }
}

// ────────────────────────────────────────────────────────────
// Sub-pages
// ────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 96, color: cs.primary),
          const SizedBox(height: 24),
          Text('Meet PocketPet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            'A pixel-art buddy that lives on your screen, reminds you to breathe, drink water, and look up from your phone.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: onNext, child: const Text("Let's go →")),
        ],
      ),
    );
  }
}

class _PetPickerPage extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;

  const _PetPickerPage({
    required this.selectedId,
    required this.onSelected,
    required this.onNext,
  });

  static const _pets = [
    ('boba', 'Boba', '🟣'),
    ('axobotl', 'Axobotl', '🐸'),
    ('bitboy', 'Bitboy', '🤖'),
    ('nova_byte', 'Nova Byte', '⭐'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Choose your pet', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('You can change this later.'),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: _pets.map((p) {
                final (id, name, emoji) = p;
                final selected = selectedId == id;
                return GestureDetector(
                  onTap: () => onSelected(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(name, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          FilledButton(onPressed: onNext, child: const Text('Next →')),
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final String name;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _NamePage({required this.name, required this.onChanged, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Name your pet", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: name,
            decoration: InputDecoration(
              labelText: "Pet name",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: onChanged,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onNext, child: const Text('Next →')),
        ],
      ),
    );
  }
}

class _PersonalityPage extends StatelessWidget {
  final PetStat peak;
  final ValueChanged<PetStat> onChanged;
  final VoidCallback onNext;

  const _PersonalityPage({required this.peak, required this.onChanged, required this.onNext});

  static const _stats = [
    (PetStat.care, '❤️ Care', 'Warm, encouraging, checks in often'),
    (PetStat.chaos, '⚡ Chaos', 'Unhinged energy, savage honesty'),
    (PetStat.wisdom, '📚 Wisdom', 'Thoughtful, calm, insightful'),
    (PetStat.snark, '😏 Snark', 'Deadpan, sarcastic, loveable roasts'),
    (PetStat.patience, '🧘 Patience', 'Gentle, never pushy, very chill'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text("Personality", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text("What's your pet's strongest trait?"),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _stats.map((s) {
                final (stat, label, desc) = s;
                return RadioListTile<PetStat>(
                  value: stat,
                  groupValue: peak,
                  onChanged: (v) => onChanged(v!),
                  title: Text(label),
                  subtitle: Text(desc),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              }).toList(),
            ),
          ),
          FilledButton(onPressed: onNext, child: const Text('Next →')),
        ],
      ),
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  final bool overlayGranted, notifGranted, usageGranted;
  final VoidCallback onRequestOverlay, onRequestNotif, onRequestUsage, onNext;

  const _PermissionsPage({
    required this.overlayGranted, required this.notifGranted, required this.usageGranted,
    required this.onRequestOverlay, required this.onRequestNotif,
    required this.onRequestUsage, required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Permissions", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text("Grant these so your pet can do its job."),
          const SizedBox(height: 24),
          _PermRow(
            icon: '🪟', title: 'Draw over other apps',
            desc: 'Required to show the floating pet',
            granted: overlayGranted, onTap: onRequestOverlay,
          ),
          _PermRow(
            icon: '🔔', title: 'Notification access',
            desc: 'Pet reacts to your notifications',
            granted: notifGranted, onTap: onRequestNotif,
          ),
          _PermRow(
            icon: '📱', title: 'Usage stats',
            desc: 'Needed for screen time nudges (key feature!)',
            granted: usageGranted, onTap: onRequestUsage,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            child: Text(usageGranted && overlayGranted ? "Launch PocketPet 🐾" : "Skip for now →"),
          ),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final String icon, title, desc;
  final bool granted;
  final VoidCallback onTap;

  const _PermRow({
    required this.icon, required this.title, required this.desc,
    required this.granted, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(title),
        subtitle: Text(desc),
        trailing: granted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton.tonal(
                onPressed: onTap, child: const Text('Grant'),
              ),
      ),
    );
  }
}
