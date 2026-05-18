import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_item.dart';

/// Listens to the Android NotificationListenerService via EventChannel.
class NotificationRepository extends StateNotifier<List<NotificationItem>> {
  static const _channel = EventChannel('pocketpet/notifications');
  static const _bufferSize = 50;

  NotificationRepository() : super([]) {
    _channel.receiveBroadcastStream().listen(_onEvent);
  }

  void _onEvent(dynamic raw) {
    final map = raw as Map<dynamic, dynamic>;
    final item = NotificationItem.fromMap(map);

    if (item.removed) {
      state = state.where((n) => n.id != item.id).toList();
    } else {
      final updated = [item, ...state.where((n) => n.id != item.id)];
      state = updated.take(_bufferSize).toList();
    }
  }

  List<NotificationItem> recent([int count = 10]) =>
      state.take(count).toList();
}

final notificationRepositoryProvider =
    StateNotifierProvider<NotificationRepository, List<NotificationItem>>(
  (_) => NotificationRepository(),
);
