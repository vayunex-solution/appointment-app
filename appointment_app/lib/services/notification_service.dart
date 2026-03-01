import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background notifications are automatically shown by the system
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification system
  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      // Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notification permission denied');
        return;
      }

      // Initialize local notifications for foreground
      const androidInit = AndroidInitializationSettings('launcher_icon');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create high-priority notification channel
      const androidChannel = AndroidNotificationChannel(
        'queue_alerts',
        'Queue Alerts',
        description: 'Notifications for queue status and turn alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpen(initialMessage);
      }

      _initialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService init error: $e');
    }
  }

  /// Get FCM token and register with backend
  static Future<void> registerDeviceToken() async {
    if (kIsWeb) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await ApiService.post(ApiConfig.registerDevice, {
          'fcm_token': token,
          'device_info': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        });
        debugPrint('FCM token registered: ${token.substring(0, 20)}...');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await ApiService.post(ApiConfig.registerDevice, {
          'fcm_token': newToken,
          'device_info': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        });
        debugPrint('FCM token refreshed');
      });
    } catch (e) {
      debugPrint('FCM token registration error: $e');
    }
  }

  /// Handle foreground message — show local notification
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'queue_alerts',
          'Queue Alerts',
          channelDescription: 'Notifications for queue status and turn alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          icon: 'launcher_icon',
        ),
      ),
    );
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // Navigation will be handled by the app based on notification data
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Handle notification open from background
  static void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.data}');
    // Navigation can be handled here based on message.data['type']
  }
}
