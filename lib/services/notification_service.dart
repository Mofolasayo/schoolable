import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/home/home_view.dart';
import 'package:stacked_services/stacked_services.dart';

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
  final NavigationService _nav = locator<NavigationService>();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (Firebase.apps.isEmpty) {
      debugPrint('⚠️ Firebase not initialized; skipping notification setup.');
      return;
    }

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
      try {
        await _setupFCM();
      } catch (e) {
        debugPrint('❌ FCM setup failed: $e');
      }
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
    // Ensure auto-init is on
    await _messaging.setAutoInitEnabled(true);

    // Listen for token refresh early so we catch the first token when APNs is ready
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _registerTokenWithBackend(newToken);
    });

    // On iOS, APNs token might not be ready immediately; try to fetch it for logging
    if (Platform.isIOS) {
      try {
        final apns = await _messaging.getAPNSToken();
        debugPrint('📱 APNs token: $apns');
      } catch (e) {
        debugPrint('⚠️ Could not fetch APNs token yet: $e');
      }
    }

    // Get FCM token (may throw if APNs token not ready on iOS)
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      final message = e.toString();
      if (Platform.isIOS && message.contains('apns-token-not-set')) {
        debugPrint(
            '⚠️ APNs token not set yet; will register when available via onTokenRefresh.');
      } else {
        rethrow;
      }
    }

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

    _navigateFromPayload(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📥 Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        _navigateFromPayload(data);
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  /// Centralized navigation handler for notification payloads
  void _navigateFromPayload(Map<String, dynamic> data) {
    final action = data['action']?.toString();
    final taskId =
        data['taskId']?.toString() ?? data['task_id']?.toString();
    final announcementId = data['announcementId']?.toString() ??
        data['announcement_id']?.toString();
    final channelId =
        data['channelId']?.toString() ?? data['channel_id']?.toString();

    // Lightweight routing to relevant tabs; extend with deep links when routes exist
    if (action == 'open_task' && taskId != null) {
      _nav.navigateToView(const HomeView(initialTab: 1));
      debugPrint('🔀 Routing to Tasks tab for task $taskId');
    } else if (action == 'open_announcement' && announcementId != null) {
      _nav.navigateToView(const HomeView(initialTab: 0));
      debugPrint('🔀 Routing to Home tab for announcement $announcementId');
    } else if (action == 'open_chat' && channelId != null) {
      _nav.navigateToView(const HomeView(initialTab: 3));
      debugPrint('🔀 Routing to Chat tab for channel $channelId');
    } else if (action == 'open_peer_rating') {
      _nav.navigateToView(const HomeView(initialTab: 0));
      debugPrint('🔀 Routing to Home tab for peer rating');
    } else if (action == 'rate_task' && taskId != null) {
      _nav.navigateToView(const HomeView(initialTab: 1));
      debugPrint('🔀 Routing to Tasks tab to rate task $taskId');
    } else {
      _nav.navigateToView(const HomeView(initialTab: 0));
      debugPrint('🔀 Routing to Home tab (default)');
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
