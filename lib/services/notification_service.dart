import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/chat/chat_view.dart';
import 'package:schoolable/ui/views/chat/message_detail_view.dart';
import 'package:schoolable/ui/views/home/announcement_detail_view.dart';
import 'package:schoolable/ui/views/home/home_view.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';
import 'package:schoolable/ui/views/tasks/task_detail_view.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
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
  final BackendApiService _apiService = locator<BackendApiService>();
  final NavigationService _nav = locator<NavigationService>();

  bool _isInitialized = false;
  bool _isTokenRegistered = false;
  int _tokenRegistrationAttempts = 0;
  Timer? _tokenRetryTimer;
  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize({bool forceRegister = false}) async {
    if (_isInitialized) {
      if (forceRegister) {
        await registerDeviceTokenIfPossible(force: true);
      }
      return;
    }

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
        await registerDeviceTokenIfPossible(force: forceRegister);
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
        'WorkSight Notifications',
        description: 'Notifications from WorkSight app',
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
      _isTokenRegistered = false;
      await registerDeviceTokenIfPossible(force: true);
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

    await _fetchFcmToken();

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

  Future<void> _fetchFcmToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');
    } catch (e) {
      final message = e.toString();
      if (Platform.isIOS && message.contains('apns-token-not-set')) {
        debugPrint(
            '⚠️ APNs token not set yet; will register when available via onTokenRefresh.');
      } else {
        debugPrint('❌ Failed to fetch FCM token: $e');
      }
    }
  }

  Future<void> registerDeviceTokenIfPossible({bool force = false}) async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    if (_fcmToken == null) {
      await _fetchFcmToken();
    }

    if (_fcmToken == null) {
      _scheduleTokenRegistrationRetry();
      return;
    }

    if (_isTokenRegistered && !force) {
      return;
    }

    final hasSession = await _apiService.hasSession();
    if (!hasSession) {
      _scheduleTokenRegistrationRetry();
      return;
    }

    try {
      await _registerTokenWithBackend(_fcmToken!);
      _isTokenRegistered = true;
      _tokenRegistrationAttempts = 0;
      _tokenRetryTimer?.cancel();
    } catch (e) {
      debugPrint('❌ Device token registration failed: $e');
      _scheduleTokenRegistrationRetry();
    }
  }

  void _scheduleTokenRegistrationRetry() {
    if (_tokenRegistrationAttempts >= 5) {
      return;
    }
    _tokenRetryTimer?.cancel();
    _tokenRegistrationAttempts += 1;
    final delaySeconds = 5 * _tokenRegistrationAttempts;
    _tokenRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      registerDeviceTokenIfPossible(force: true);
    });
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    String platform = Platform.isIOS ? 'ios' : 'android';
    await _apiService.registerDeviceToken(token: token, platform: platform);
    debugPrint('✅ Device token registered');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📥 Foreground message: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'WorkSight',
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
  Future<void> _navigateFromPayload(Map<String, dynamic> data) async {
    final action = data['action']?.toString();
    final taskId =
        data['taskId']?.toString() ?? data['task_id']?.toString();
    final announcementId = data['announcementId']?.toString() ??
        data['announcement_id']?.toString();
    final channelId =
        data['channelId']?.toString() ?? data['channel_id']?.toString();

    if ((action == 'open_task' || action == 'rate_task') && taskId != null) {
      await _openTask(taskId);
      return;
    }
    if (action == 'open_announcement' && announcementId != null) {
      await _openAnnouncement(announcementId);
      return;
    }
    if (action == 'open_chat' && channelId != null) {
      await _openChannel(channelId);
      return;
    }
    if (taskId != null) {
      await _openTask(taskId);
      return;
    }
    if (announcementId != null) {
      await _openAnnouncement(announcementId);
      return;
    }
    if (channelId != null) {
      await _openChannel(channelId);
      return;
    }

    _nav.navigateToView(const HomeView(initialTab: 0));
    debugPrint('🔀 Routing to Home tab (default)');
  }

  Future<void> _openTask(String taskId) async {
    final id = int.tryParse(taskId);
    if (id == null) {
      _nav.navigateToView(const HomeView(initialTab: 1));
      return;
    }

    try {
      final taskData = await _apiService.getTask(id);
      if (taskData != null) {
        final task = Task.fromMap(taskData);
        await _nav.navigateToView(TaskDetailView(task: task));
        return;
      }
    } catch (e) {
      debugPrint('❌ Failed to open task $taskId: $e');
    }

    _nav.navigateToView(const HomeView(initialTab: 1));
  }

  Future<void> _openAnnouncement(String announcementId) async {
    try {
      final announcements = await _apiService.getAnnouncements();
      final match = announcements.firstWhere(
        (item) => item['id']?.toString() == announcementId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        final announcement = _announcementFromMap(match);
        await _nav.navigateToView(
          AnnouncementDetailView(
            announcement: announcement,
            onMarkAsRead: () => _apiService.markAnnouncementAsRead(
              announcement.id,
            ),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('❌ Failed to open announcement $announcementId: $e');
    }

    _nav.navigateToView(const HomeView(initialTab: 0));
  }

  Future<void> _openChannel(String channelId) async {
    try {
      final channels = await _apiService.getMyChannels();
      final match = channels.firstWhere(
        (item) => item['id']?.toString() == channelId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        final type = match['type']?.toString();
        final isChannel = type != 'dm';
        String? otherUserId;
        String? avatar;
        String name = match['name']?.toString() ?? 'Chat';

        if (!isChannel) {
          final otherUser = _apiService.getOtherUserFromChannel(match);
          if (otherUser != null) {
            otherUserId = otherUser['id']?.toString();
            name = otherUser['full_name']?.toString() ?? 'Direct Message';
            avatar = otherUser['avatar_url']?.toString();
            if (avatar == null || avatar.isEmpty) {
              final seed = otherUser['employee_id'] ??
                  otherUser['email'] ??
                  name;
              avatar = _apiService.getAvatarUrl(
                otherUser['gender']?.toString(),
                seed.toString(),
              );
            }
          }
        }

        await _nav.navigateToView(
          MessageDetailView(
            channelId: channelId,
            name: name,
            avatar: avatar,
            isChannel: isChannel,
            otherUserId: otherUserId,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('❌ Failed to open channel $channelId: $e');
    }

    _nav.navigateToView(const ChatView());
  }

  Announcement _announcementFromMap(Map<String, dynamic> item) {
    final createdAtStr = item['created_at'];
    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now()
        : DateTime.now();
    final isPinned = item['pinned'] == true;

    return Announcement(
      id: item['id']?.toString() ?? '',
      title: item['title'] ?? 'Announcement',
      message: item['content'] ?? '',
      time: _timeAgo(createdAt),
      type: isPinned ? 'alert' : 'info',
      isRead: item['is_read'] ?? false,
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
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
      'WorkSight Notifications',
      channelDescription: 'Notifications from WorkSight app',
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
        _isTokenRegistered = false;
        _tokenRetryTimer?.cancel();
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
