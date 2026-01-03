import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schoolable/services/backend_api_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📥 Background message: ${message.messageId}');
}

/// Service for handling push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final BackendApiService _apiService = BackendApiService();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _setupLocalNotifications();
      await _setupFCM();
      _isInitialized = true;
    }
  }

  /// Set up local notifications
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'schoolable_channel',
        'Schoolable Notifications',
        description: 'Notifications from Schoolable app',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Set up Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('📱 FCM Token: $_fcmToken');

    // Register token with backend
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _registerTokenWithBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      String platform = Platform.isIOS ? 'ios' : 'android';
      await _apiService.registerDeviceToken(token: token, platform: platform);
      debugPrint('✅ Device token registered');
    } catch (e) {
      debugPrint('❌ Failed to register device token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📥 Foreground message: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Schoolable',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('📥 Notification opened: ${message.data}');

    // Handle navigation based on message data
    String? action = message.data['action'];
    String? taskId = message.data['taskId'];
    String? announcementId = message.data['announcementId'];

    // TODO: Use navigation service to navigate to appropriate screen
    // This would typically use a navigation service or app router
    if (action == 'open_task' && taskId != null) {
      // Navigate to task detail
      debugPrint('Navigate to task: $taskId');
    } else if (action == 'open_announcement' && announcementId != null) {
      // Navigate to announcement
      debugPrint('Navigate to announcement: $announcementId');
    } else if (action == 'open_chat') {
      // Navigate to chat
      debugPrint('Navigate to chat');
    } else if (action == 'open_peer_rating') {
      // Navigate to peer rating
      debugPrint('Navigate to peer rating');
    } else if (action == 'rate_task' && taskId != null) {
      // Navigate to rate task
      debugPrint('Navigate to rate task: $taskId');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📥 Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        // Handle navigation based on payload
        String? action = data['action'];
        if (action != null) {
          // TODO: Navigate based on action
        }
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'schoolable_channel',
      'Schoolable Notifications',
      channelDescription: 'Notifications from Schoolable app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Unregister device token (call on logout)
  Future<void> unregisterDevice() async {
    if (_fcmToken != null) {
      try {
        await _apiService.unregisterDeviceToken(token: _fcmToken!);
        debugPrint('✅ Device token unregistered');
      } catch (e) {
        debugPrint('❌ Failed to unregister device token: $e');
      }
    }
  }

  /// Show a custom notification (for testing)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: data != null ? jsonEncode(data) : null,
    );
  }
}
