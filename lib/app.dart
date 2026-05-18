import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/personality/pet_profile_repository.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/theme/app_theme.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/loading',
    routes: [
      GoRoute(path: '/loading', builder: (_, __) => const _LoadingGate()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    ],
  );
});

class PocketPetApp extends ConsumerWidget {
  const PocketPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'PocketPet',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

/// Decides whether to show onboarding or dashboard.
class _LoadingGate extends ConsumerWidget {
  const _LoadingGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileRepo = ref.read(petProfileRepositoryProvider);

    return FutureBuilder<bool>(
      future: profileRepo.isOnboarded(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snap.data!) {
            context.go('/dashboard');
          } else {
            context.go('/onboarding');
          }
        });
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
