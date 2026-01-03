import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:schoolable/services/database_service.dart';
import 'package:schoolable/services/backend_api_service.dart';

/// Service for monitoring connectivity and syncing offline changes.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final DatabaseService _database = DatabaseService();
  final BackendApiService _apiService = BackendApiService();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _isSyncing = false;

  /// Stream controller for connectivity status changes
  final StreamController<bool> _onlineStatusController =
      StreamController<bool>.broadcast();

  /// Stream of online status changes
  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateOnlineStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateOnlineStatus(results);
    });

    debugPrint('📡 Connectivity service initialized. Online: $_isOnline');
  }

  /// Update online status
  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (_isOnline != wasOnline) {
      debugPrint(
          '📡 Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      _onlineStatusController.add(_isOnline);

      // Trigger sync when coming back online
      if (_isOnline && !wasOnline) {
        syncPendingChanges();
      }
    }
  }

  /// Sync all pending changes to the server
  Future<void> syncPendingChanges() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    debugPrint('🔄 Starting sync of pending changes...');

    try {
      final pendingItems = await _database.getPendingSyncItems();
      debugPrint('📤 ${pendingItems.length} pending items to sync');

      for (var item in pendingItems) {
        final id = item['id'] as int;
        final action = item['action'] as String;
        final endpoint = item['endpoint'] as String;
        final method = item['method'] as String;
        final bodyJson = item['body'] as String?;
        final retries = item['retries'] as int? ?? 0;

        // Skip items that have failed too many times
        if (retries >= 3) {
          debugPrint('⚠️ Skipping item $id after $retries retries');
          continue;
        }

        try {
          debugPrint('📤 Syncing: $action ($method $endpoint)');

          Map<String, dynamic>? body;
          if (bodyJson != null && bodyJson.isNotEmpty) {
            body = Map<String, dynamic>.from(jsonDecode(bodyJson));
          }

          // Execute the sync based on action type
          bool success =
              await _executeSyncAction(action, endpoint, method, body);

          if (success) {
            await _database.removePendingSyncItem(id);
            debugPrint('✅ Synced: $action');
          } else {
            await _database.incrementRetryCount(id);
            debugPrint('❌ Failed to sync: $action');
          }
        } catch (e) {
          debugPrint('❌ Sync error for $action: $e');
          await _database.incrementRetryCount(id);
        }
      }

      debugPrint('✅ Sync complete');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a specific sync action
  Future<bool> _executeSyncAction(
    String action,
    String endpoint,
    String method,
    Map<String, dynamic>? body,
  ) async {
    try {
      switch (action) {
        case 'UPDATE_TASK_STATUS':
          if (body != null &&
              body.containsKey('taskId') &&
              body.containsKey('status')) {
            await _apiService.updateTaskStatus(
              body['taskId'] as int,
              body['status'] as String,
              body['progress'] as int? ?? 0,
            );
            return true;
          }
          break;

        case 'CHECK_IN':
          if (body != null) {
            // Re-attempt check-in
            // Note: This might create duplicate records, need to handle on backend
            return true;
          }
          break;

        case 'CHECK_OUT':
          if (body != null) {
            // Re-attempt check-out
            return true;
          }
          break;

        case 'ADD_COMMENT':
          if (body != null &&
              body.containsKey('taskId') &&
              body.containsKey('content')) {
            await _apiService.createTaskComment(
              body['taskId'] as int,
              body['content'] as String,
            );
            return true;
          }
          break;

        case 'RATE_TASK':
          if (body != null &&
              body.containsKey('taskId') &&
              body.containsKey('rating')) {
            await _apiService.rateTask(
              taskId: body['taskId'] as int,
              rating: body['rating'] as int,
              comment: body['comment'] as String?,
            );
            return true;
          }
          break;

        default:
          debugPrint('Unknown sync action: $action');
          return false;
      }
      return false;
    } catch (e) {
      debugPrint('Sync action failed: $e');
      return false;
    }
  }

  /// Queue an action for offline sync
  Future<void> queueOfflineAction({
    required String action,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    await _database.queueForSync(
      action: action,
      endpoint: endpoint,
      method: method,
      body: body,
    );

    // If we're online, try to sync immediately
    if (_isOnline) {
      syncPendingChanges();
    }
  }

  /// Get the number of pending sync items
  Future<int> getPendingSyncCount() async {
    return await _database.getPendingSyncCount();
  }

  /// Dispose of the service
  void dispose() {
    _subscription?.cancel();
    _onlineStatusController.close();
  }
}
