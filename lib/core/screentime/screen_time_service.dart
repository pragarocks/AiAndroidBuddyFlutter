import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppUsage {
  final String packageName;
  final String appLabel;
  final int usageMinutes;
  const AppUsage({
    required this.packageName,
    required this.appLabel,
    required this.usageMinutes,
  });
}

/// Fetches screen time data from Android UsageStatsManager via MethodChannel.
class ScreenTimeService {
  static const _channel = MethodChannel('pocketpet/screentime');
  static const _permChannel = MethodChannel('pocketpet/permissions');

  Future<bool> hasPermission() async {
    return await _permChannel.invokeMethod<bool>('hasUsagePermission') ?? false;
  }

  Future<void> requestPermission() =>
      _permChannel.invokeMethod('openUsageSettings');

  /// Returns usage for the last [hours] hours, sorted most-used first.
  Future<List<AppUsage>> getUsageStats({int hours = 1}) async {
    final raw = await _channel.invokeMethod<List>('getUsageStats', {'hours': hours});
    if (raw == null) return [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return AppUsage(
        packageName: m['package'] as String,
        appLabel: m['appLabel'] as String,
        usageMinutes: m['usageMinutes'] as int,
      );
    }).toList();
  }

  /// Returns minutes the user has spent in [packageName] within the last [withinMinutes].
  Future<int> getAppUsageMinutes(String packageName, {int withinMinutes = 60}) async {
    return await _channel.invokeMethod<int>(
      'getAppUsageMinutes',
      {'package': packageName, 'minutes': withinMinutes},
    ) ?? 0;
  }

  /// Convenience: returns total social media time in the last [hours] hours.
  Future<int> socialMediaMinutes({int hours = 1}) async {
    final stats = await getUsageStats(hours: hours);
    return stats
        .where((a) => _isSocialApp(a.packageName))
        .fold<int>(0, (sum, a) => sum + a.usageMinutes);
  }

  static bool _isSocialApp(String pkg) {
    const social = {
      'com.instagram.android',
      'com.zhiliaoapp.musically', // TikTok
      'com.twitter.android',
      'com.X.android',
      'com.reddit.frontpage',
      'com.facebook.katana',
      'com.snapchat.android',
      'com.linkedin.android',
      'com.youtube.android',
      'com.google.android.youtube',
      'com.tumblr',
      'com.pinterest',
    };
    return social.contains(pkg);
  }
}

final screenTimeServiceProvider = Provider((_) => ScreenTimeService());
