import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class NotificationApiService extends ChangeNotifier {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Fetch notification history
  Future<void> fetchNotifications({int limit = 50, int offset = 0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.get(
          '${ApiConfig.notifications}?limit=$limit&offset=$offset');
      if (result['success']) {
        _notifications = result['data']['notifications'] ?? [];
        _unreadCount = result['data']['unread_count'] ?? 0;
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch unread count only (for badge)
  Future<void> fetchUnreadCount() async {
    try {
      final result = await ApiService.get(ApiConfig.unreadCount);
      if (result['success']) {
        _unreadCount = result['data']['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.patch(
          '${ApiConfig.notifications}/$notificationId/read', {});
      // Update local state
      final index =
          _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllRead() async {
    try {
      await ApiService.patch(ApiConfig.readAllNotifications, {});
      for (var n in _notifications) {
        n['is_read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
  }
}
