import 'package:get_storage/get_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  GetStorage? _storage;
  static const String _readNotificationsKey = 'read_notifications';
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await GetStorage.init();
      _storage = GetStorage();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing GetStorage: $e');
    }
  }

  // Mark a notification as read
  void markAsRead(String orderId) {
    if (_storage == null || !_isInitialized) return;

    final readNotifications =
        _storage!.read<List<dynamic>>(_readNotificationsKey) ?? <String>[];
    if (!readNotifications.contains(orderId)) {
      readNotifications.add(orderId);
      _storage!.write(_readNotificationsKey, readNotifications);
    }
  }

  // Check if a notification is read
  bool isRead(String orderId) {
    if (_storage == null || !_isInitialized) return false;

    final readNotifications =
        _storage!.read<List<dynamic>>(_readNotificationsKey) ?? <String>[];
    return readNotifications.contains(orderId);
  }

  // Get count of unread notifications
  int getUnreadCount(List<String> orderIds) {
    if (_storage == null || !_isInitialized) return orderIds.length;

    return orderIds.where((orderId) => !isRead(orderId)).length;
  }

  // Mark all notifications as read
  void markAllAsRead() {
    if (_storage == null || !_isInitialized) return;

    _storage!.write(_readNotificationsKey, <String>[]);
  }

  // Clear all read notifications (reset)
  void clearReadNotifications() {
    if (_storage == null || !_isInitialized) return;

    _storage!.remove(_readNotificationsKey);
  }
}
