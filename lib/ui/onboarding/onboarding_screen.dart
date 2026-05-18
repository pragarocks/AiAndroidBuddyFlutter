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

  bool _overlayGranted = false;
  bool _notifGranted = false;
  bool _usageGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final overlay = await _permChannel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    final notif = await _permChannel.invokeMethod<bool>('hasNotificationListenerPermission') ?? false;
    final usage = await _permChannel.invokeMethod<bool>('hasUsagePermission') ?? false;
    if (mounted) {
      setState(() {
        _overlayGranted = overlay;
        _notifGranted = notif;
        _usageGranted = usage;
      });
    }
  }

  Future<void> _requestOverlay() async {
    await _permChannel.invokeMethod('openOverlaySettings');
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> _requestNotif() async {
    await _permChannel.invokeMethod('openNotificationListenerSettings');
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> _requestUsage() async {
    await _permChannel.invokeMethod('openUsageSettings');
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  Future<void> _finish() async {
    const profile = PetProfile(
      petId: 'axobotl',
      name: 'Axobotl',
      species: 'axolotl',
      peakStat: PetStat.care,
      dumpStat: PetStat.snark,
      speechStyle: 'short and playful',
    );
    await ref.read(petProfileRepositoryProvider).save(profile);
    await ref.read(petProfileRepositoryProvider).setOnboarded();
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.pets, size: 40, color: cs.primary),
                  const SizedBox(width: 12),
                  Text("Welcome to PocketPet", style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Please grant these permissions on your first launch so your PocketPet can run smoothly on your screen.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _PermRow(
                icon: '🪟', title: 'Draw over other apps',
                desc: 'Required to show the floating pet above other applications',
                granted: _overlayGranted, onTap: _requestOverlay,
              ),
              _PermRow(
                icon: '🔔', title: 'Notification access',
                desc: 'Allows the pet to react playfully when you receive notifications',
                granted: _notifGranted, onTap: _requestNotif,
              ),
              _PermRow(
                icon: '📱', title: 'Usage stats',
                desc: 'Allows your pet to nudge you if you spend too much time on social apps',
                granted: _usageGranted, onTap: _requestUsage,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finish,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _overlayGranted && _usageGranted 
                      ? "Start PocketPet 🐾" 
                      : "Proceed to Dashboard →",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: ListTile(
          leading: Text(icon, style: const TextStyle(fontSize: 32)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(desc),
          trailing: granted
              ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
              : FilledButton.tonal(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Grant'),
                ),
        ),
      ),
    );
  }
}
