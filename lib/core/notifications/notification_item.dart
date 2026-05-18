class NotificationItem {
  final String id;
  final String packageName;
  final String appLabel;
  final String title;
  final String text;
  final DateTime timestamp;
  final int priority;
  final String category;
  final bool removed;

  const NotificationItem({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.title,
    required this.text,
    required this.timestamp,
    this.priority = 0,
    this.category = '',
    this.removed = false,
  });

  factory NotificationItem.fromMap(Map<dynamic, dynamic> m) => NotificationItem(
    id: m['id']?.toString() ?? '',
    packageName: m['packageName']?.toString() ?? '',
    appLabel: m['appLabel']?.toString() ?? m['packageName']?.toString() ?? '',
    title: m['title']?.toString() ?? '',
    text: m['text']?.toString() ?? '',
    timestamp: DateTime.fromMillisecondsSinceEpoch(
        (m['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
    priority: (m['priority'] as int?) ?? 0,
    category: m['category']?.toString() ?? '',
    removed: m['removed'] == true,
  );
}
