import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet_profile.dart';

class PetProfileRepository {
  static const _prefix = 'pet_profile_';

  Future<PetProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = ['petId','name','species','peakStat','dumpStat','speechStyle'];
    final missing = keys.any((k) => !prefs.containsKey('$_prefix$k'));
    if (missing) return PetProfile.defaults();

    return PetProfile.fromJson({
      for (final k in keys) k: prefs.getString('$_prefix$k')!,
    });
  }

  Future<void> save(PetProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    profile.toJson().forEach((k, v) => prefs.setString('$_prefix$k', v));
  }

  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}

final petProfileRepositoryProvider = Provider((_) => PetProfileRepository());

final petProfileProvider = FutureProvider<PetProfile>((ref) {
  return ref.read(petProfileRepositoryProvider).load();
});
