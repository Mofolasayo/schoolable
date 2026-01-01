import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/services/websocket_service.dart';

class ChatChannel {
  final String id;
  final String name;
  final bool hasUnread;
  final int unreadCount;

  ChatChannel({
    required this.id,
    required this.name,
    this.hasUnread = false,
    this.unreadCount = 0,
  });

  /// Convert to cacheable map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'hasUnread': hasUnread,
        'unreadCount': unreadCount,
        'type': 'channel',
      };

  /// Create from cached map
  factory ChatChannel.fromMap(Map<String, dynamic> map) {
    return ChatChannel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      hasUnread: map['hasUnread'] ?? false,
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}

class ChatUser {
  final String id; // Channel ID for the DM
  final String otherUserId; // The other user's ID
  final String name;
  final String avatar;
  final bool isOnline;
  final String lastMessage;
  final String time;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.otherUserId,
    required this.name,
    required this.avatar,
    required this.isOnline,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });

  /// Convert to cacheable map
  Map<String, dynamic> toMap() => {
        'id': id,
        'otherUserId': otherUserId,
        'name': name,
        'avatar': avatar,
        'lastMessage': lastMessage,
        'time': time,
        'unreadCount': unreadCount,
        'type': 'dm',
      };

  /// Create from cached map (isOnline will be updated on fetch)
  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      id: map['id']?.toString() ?? '',
      otherUserId: map['otherUserId']?.toString() ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'] ?? '',
      isOnline: false, // Will be updated when fetching fresh data
      lastMessage: map['lastMessage'] ?? '',
      time: map['time'] ?? '',
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}

class ChatViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  final _cacheService = locator<CacheService>();
  final _wsService = locator<WebSocketService>();

  List<ChatChannel> _channels = [];
  List<ChatChannel> get channels => _channels;

  List<ChatUser> _directMessages = [];
  List<ChatUser> get directMessages => _directMessages;

  Set<String> _onlineUserIds = {};
  Set<String> get onlineUserIds => _onlineUserIds;

  bool _isWsConnected = false;
  bool get isWsConnected => _isWsConnected;

  Timer? _heartbeatTimer;
  Timer? _onlineStatusTimer;
  Timer? _pollingTimer;

  void initialize() async {
    setBusy(true);

    // 1. Load cached data immediately (instant UI)
    await _loadCachedData();

    // 2. Connect to WebSocket for real-time updates
    await _initializeWebSocket();

    // 3. Send initial heartbeat
    await _backendService.sendHeartbeat();

    // 4. Fetch fresh data in background
    await Future.wait([
      fetchChannels(),
      _fetchOnlineUsers(),
    ]);

    // 5. Start periodic heartbeat (every 30 seconds)
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _backendService.sendHeartbeat(),
    );

    // 6. Refresh online status every 30 seconds
    _onlineStatusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchOnlineUsers(),
    );

    // 7. Fallback polling in case WebSocket isn't working
    if (!_isWsConnected) {
      _startPolling();
    }

    setBusy(false);
  }

  /// Initialize WebSocket connection
  Future<void> _initializeWebSocket() async {
    try {
      final token = await _backendService.getCurrentToken();
      if (token == null) {
        print('⚠️ No token available for WebSocket');
        return;
      }

      // Add connection listener
      _wsService.addConnectionListener(_onConnectionChange);

      // Add presence listener
      _wsService.subscribeToPresence(onUpdate: _onPresenceUpdate);

      // Connect
      await _wsService.connect(token);
    } catch (e) {
      print('⚠️ WebSocket initialization failed: $e');
      _startPolling();
    }
  }

  void _onConnectionChange(bool connected) {
    _isWsConnected = connected;
    notifyListeners();

    if (connected) {
      print('✅ WebSocket connected - stopping polling');
      _pollingTimer?.cancel();
    } else {
      print('⚠️ WebSocket disconnected - starting polling');
      _startPolling();
    }
  }

  void _onPresenceUpdate(WsMessage message) {
    final userId = message.data['userId']?.toString();
    final status = message.data['status']?.toString();

    if (userId != null) {
      if (status == 'online') {
        _onlineUserIds.add(userId);
      } else {
        _onlineUserIds.remove(userId);
      }
      notifyListeners();
    }
  }

  /// Subscribe to a channel's real-time messages
  void subscribeToChannel(String channelId,
      {required void Function(WsMessage) onMessage}) {
    _wsService.subscribeToChannel(channelId, onMessage: onMessage);
  }

  /// Unsubscribe from a channel
  void unsubscribeFromChannel(String channelId) {
    _wsService.unsubscribeFromChannel(channelId);
  }

  /// Send a real-time message via WebSocket
  void sendWsMessage(String channelId, String content) {
    _wsService.sendMessage(channelId, content);
  }

  /// Send typing indicator
  void sendTyping(String channelId, bool isTyping) {
    _wsService.sendTyping(channelId, isTyping);
  }

  /// Start polling as fallback
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchChannels(),
    );
  }

  /// Load cached channels and DMs for instant display
  Future<void> _loadCachedData() async {
    // Load cached channels
    final cachedChannels = await _cacheService.getCachedChannels();
    if (cachedChannels != null) {
      _channels = cachedChannels
          .cast<Map<String, dynamic>>()
          .where((c) => c['type'] == 'channel')
          .map((c) => ChatChannel.fromMap(c))
          .toList();
    }

    // Load cached DMs
    final cachedDMs = await _cacheService.getCachedDirectMessages();
    if (cachedDMs != null) {
      _directMessages = cachedDMs
          .cast<Map<String, dynamic>>()
          .map((c) => ChatUser.fromMap(c))
          .toList();
    }

    notifyListeners();
  }

  Future<void> _fetchOnlineUsers() async {
    final onlineIds = await _backendService.getOnlineUserIds();
    _onlineUserIds = onlineIds.toSet();
    notifyListeners();
  }

  bool isUserOnline(String? userId) {
    if (userId == null) return false;
    return _onlineUserIds.contains(userId);
  }

  Future<void> fetchChannels() async {
    final rawChannels = await _backendService.getMyChannels();

    _channels = [];
    _directMessages = [];

    for (var c in rawChannels) {
      final id = c['id']?.toString() ?? '';
      final type = c['type'];
      final name = c['name'];
      final lastMsg = c['last_message'] ?? 'Start chatting...';
      final lastMsgAt = c['last_message_at'];
      final otherUser = _backendService.getOtherUserFromChannel(c);

      // Get unread count
      int unreadCount = 0;
      try {
        unreadCount = await _backendService.getUnreadCount(id);
      } catch (_) {}

      // Format time
      String timeStr = '';
      if (lastMsgAt != null) {
        try {
          final dt = DateTime.parse(lastMsgAt);
          final now = DateTime.now();
          final diff = now.difference(dt);

          if (diff.inMinutes < 1) {
            timeStr = 'now';
          } else if (diff.inMinutes < 60) {
            timeStr = '${diff.inMinutes}m';
          } else if (diff.inHours < 24) {
            timeStr = '${diff.inHours}h';
          } else if (diff.inDays < 7) {
            timeStr = '${diff.inDays}d';
          } else {
            timeStr = '${dt.day}/${dt.month}';
          }
        } catch (_) {}
      }

      if (type == 'dm' && otherUser != null) {
        String displayName = otherUser['full_name'] ?? 'Unknown';
        String avatar = otherUser['avatar_url'] ?? '';
        String otherUserId = otherUser['id']?.toString() ?? '';

        // Generate avatar if not provided
        if (avatar.isEmpty) {
          final seed =
              otherUser['employee_id'] ?? otherUser['email'] ?? displayName;
          avatar = _backendService.getAvatarUrl(otherUser['gender'], seed);
        }

        _directMessages.add(ChatUser(
          id: id,
          otherUserId: otherUserId,
          name: displayName,
          avatar: avatar,
          isOnline: isUserOnline(otherUserId),
          lastMessage: lastMsg,
          time: timeStr,
          unreadCount: unreadCount,
        ));
      } else if (type != 'dm') {
        _channels.add(ChatChannel(
          id: id,
          name: name ?? 'Unknown',
          hasUnread: unreadCount > 0,
          unreadCount: unreadCount,
        ));
      }
    }

    // Cache the channels and DMs for future use
    await _cacheService.cacheChannels(_channels.map((c) => c.toMap()).toList());
    await _cacheService
        .cacheDirectMessages(_directMessages.map((d) => d.toMap()).toList());

    notifyListeners();
  }

  Future<void> createNewChannel(String name, bool isPrivate,
      {List<String>? initialMembers}) async {
    setBusy(true);
    await _backendService.createChannel(name, isPrivate ? 'private' : 'public',
        memberIds: initialMembers);
    await fetchChannels();
    setBusy(false);
  }

  Future<String?> startDirectMessage(String userId) async {
    setBusy(true);
    try {
      final result = await _backendService.getOrCreateDM(userId);
      await fetchChannels();
      return result['id']?.toString();
    } catch (e) {
      print('Error starting DM: $e');
      return null;
    } finally {
      setBusy(false);
    }
  }

  /// Get staff list for starting new chats (excludes self and admins)
  Future<List<Map<String, dynamic>>> getStaffList() async {
    return await _backendService.getStaffForChat();
  }

  String getAvatarUrl(String? gender, String seed) {
    return _backendService.getAvatarUrl(gender, seed);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _onlineStatusTimer?.cancel();
    _pollingTimer?.cancel();
    _wsService.removeConnectionListener(_onConnectionChange);
    super.dispose();
  }
}
