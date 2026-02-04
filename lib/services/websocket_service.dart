import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:schoolable/services/logging_service.dart';

/// Message types for WebSocket communication
enum WsMessageType {
  chatMessage,
  typing,
  presence,
  notification,
  error,
}

/// Represents a real-time message from WebSocket
class WsMessage {
  final WsMessageType type;
  final String? channelId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WsMessage({
    required this.type,
    this.channelId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WsMessage.fromJson(Map<String, dynamic> json, WsMessageType type) {
    return WsMessage(
      type: type,
      channelId: json['channelId']?.toString(),
      data: json,
    );
  }
}

/// Callback types
typedef MessageCallback = void Function(WsMessage message);
typedef ConnectionCallback = void Function(bool connected);

/// WebSocket service for real-time messaging
///
/// Usage:
/// ```dart
/// final ws = WebSocketService();
/// await ws.connect(token);
/// ws.subscribeToChannel(channelId, onMessage: (msg) => debugPrint('$msg'));
/// ws.sendMessage(channelId, 'Hello!');
/// ```
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _token;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Subscriptions
  final Map<String, Set<MessageCallback>> _channelSubscriptions = {};
  final Set<MessageCallback> _presenceSubscriptions = {};
  final Set<MessageCallback> _notificationSubscriptions = {};
  final Set<ConnectionCallback> _connectionListeners = {};

  void _log(String message) {
    AppLogger.log(message);
  }

  String get _baseWsUrl {
    final httpUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8081';
    // Convert http(s) to ws(s)
    return httpUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect(String token) async {
    if (_isConnected || _isConnecting) return;

    _token = token;
    _isConnecting = true;

    try {
      final wsUrl = '$_baseWsUrl/ws-native';
      _log('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        // Note: For native WebSocket, we'll send auth in first message
      );

      // Wait for connection
      await _channel!.ready;

      // Send authentication message first
      _sendRaw({
        'type': 'AUTH',
        'token': token,
      });

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _log('WebSocket connected');
      _notifyConnectionListeners(true);

      // Start listening
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Start heartbeat to keep connection alive
      _startHeartbeat();
    } catch (e) {
      _log('WebSocket connection failed: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();

    _isConnected = false;
    _channel = null;
    _token = null;

    _log('WebSocket disconnected');
    _notifyConnectionListeners(false);
  }

  /// Subscribe to a channel's messages
  void subscribeToChannel(String channelId,
      {required MessageCallback onMessage}) {
    _channelSubscriptions.putIfAbsent(channelId, () => {});
    _channelSubscriptions[channelId]!.add(onMessage);

    // Tell server we're interested in this channel
    if (_isConnected) {
      _sendRaw({
        'type': 'SUBSCRIBE',
        'channelId': channelId,
      });
    }

    _log('Subscribed to channel: $channelId');
  }

  /// Unsubscribe from a channel
  void unsubscribeFromChannel(String channelId, {MessageCallback? callback}) {
    if (callback != null) {
      _channelSubscriptions[channelId]?.remove(callback);
      if (_channelSubscriptions[channelId]?.isEmpty ?? true) {
        _channelSubscriptions.remove(channelId);
      }
    } else {
      _channelSubscriptions.remove(channelId);
    }

    if (!_channelSubscriptions.containsKey(channelId) && _isConnected) {
      _sendRaw({
        'type': 'UNSUBSCRIBE',
        'channelId': channelId,
      });
    }
  }

  /// Subscribe to presence updates
  void subscribeToPresence({required MessageCallback onUpdate}) {
    _presenceSubscriptions.add(onUpdate);
  }

  /// Unsubscribe from presence
  void unsubscribeFromPresence(MessageCallback callback) {
    _presenceSubscriptions.remove(callback);
  }

  /// Subscribe to private notifications
  void subscribeToNotifications({required MessageCallback onNotification}) {
    _notificationSubscriptions.add(onNotification);
  }

  /// Unsubscribe from private notifications
  void unsubscribeFromNotifications(MessageCallback callback) {
    _notificationSubscriptions.remove(callback);
  }

  /// Add connection state listener
  void addConnectionListener(ConnectionCallback callback) {
    _connectionListeners.add(callback);
  }

  /// Remove connection state listener
  void removeConnectionListener(ConnectionCallback callback) {
    _connectionListeners.remove(callback);
  }

  /// Send a chat message
  void sendMessage(String channelId, String content) {
    if (!_isConnected) {
      _log('Cannot send message: not connected');
      return;
    }

    _sendRaw({
      'type': 'CHAT_MESSAGE',
      'channelId': channelId,
      'content': content,
    });
  }

  /// Send typing indicator
  void sendTyping(String channelId, bool isTyping) {
    if (!_isConnected) return;

    _sendRaw({
      'type': 'TYPING',
      'channelId': channelId,
      'isTyping': isTyping,
    });
  }

  /// Update presence status
  void updatePresence(String status) {
    if (!_isConnected) return;

    _sendRaw({
      'type': 'PRESENCE',
      'status': status, // 'online', 'away', 'offline'
    });
  }

  // ==================== PRIVATE METHODS ====================

  void _sendRaw(Map<String, dynamic> data) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage.toString());
      final type = data['type']?.toString() ?? '';

      switch (type) {
        case 'CHAT_MESSAGE':
          _handleChatMessage(data);
          break;
        case 'TYPING':
          _handleTypingIndicator(data);
          break;
        case 'PRESENCE':
          _handlePresenceUpdate(data);
          break;
        case 'NOTIFICATION':
          _handleNotification(data);
          break;
        case 'AUTH_SUCCESS':
          _log('WebSocket authentication successful');
          break;
        case 'AUTH_FAILED':
          _log('WebSocket authentication failed');
          disconnect();
          break;
        case 'PONG':
          // Heartbeat response
          break;
        default:
          _log('Unknown message type: $type');
      }
    } catch (e) {
      _log('Error parsing WebSocket message: $e');
    }
  }

  void _handleChatMessage(Map<String, dynamic> data) {
    final channelId = data['channelId']?.toString();
    if (channelId == null) return;

    final message = WsMessage.fromJson(data, WsMessageType.chatMessage);

    // Notify channel subscribers
    _channelSubscriptions[channelId]?.forEach((callback) {
      callback(message);
    });
  }

  void _handleTypingIndicator(Map<String, dynamic> data) {
    final channelId = data['channelId']?.toString();
    if (channelId == null) return;

    final message = WsMessage.fromJson(data, WsMessageType.typing);

    _channelSubscriptions[channelId]?.forEach((callback) {
      callback(message);
    });
  }

  void _handlePresenceUpdate(Map<String, dynamic> data) {
    final message = WsMessage.fromJson(data, WsMessageType.presence);

    for (var callback in _presenceSubscriptions) {
      callback(message);
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    final message = WsMessage.fromJson(data, WsMessageType.notification);

    for (var callback in _notificationSubscriptions) {
      callback(message);
    }
  }

  void _handleError(dynamic error) {
    _log('WebSocket error: $error');
    _isConnected = false;
    _notifyConnectionListeners(false);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    _log('WebSocket connection closed');
    _isConnected = false;
    _notifyConnectionListeners(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_token == null || _reconnectAttempts >= _maxReconnectAttempts) {
      _log('Max reconnect attempts reached or no token');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;

    _log(
        'Scheduling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_token != null) {
        connect(_token!);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _sendRaw({'type': 'PING'});
      }
    });
  }

  void _notifyConnectionListeners(bool connected) {
    for (var listener in _connectionListeners) {
      listener(connected);
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _channelSubscriptions.clear();
    _presenceSubscriptions.clear();
    _notificationSubscriptions.clear();
    _connectionListeners.clear();
  }
}
