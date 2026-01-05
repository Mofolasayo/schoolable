import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service that provides local caching for API responses.
/// Uses the "stale-while-revalidate" pattern:
/// 1. Return cached data immediately (if available)
/// 2. Fetch fresh data from API in background
/// 3. Update cache with fresh data
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // In-memory cache for faster access
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache keys
  static const String keyProfile = 'cache_profile';
  static const String keyAnnouncements = 'cache_announcements';
  static const String keyTasks = 'cache_tasks';
  static const String keyChannels = 'cache_channels';
  static const String keyDirectMessages = 'cache_dms';
  static const String keyAttendanceHistory = 'cache_attendance_history';
  static const String keyAttendanceToday = 'cache_attendance_today';

  // Cache expiration times (in minutes)
  static const int profileCacheDuration = 60; // 1 hour
  static const int announcementsCacheDuration = 5; // 5 minutes
  static const int tasksCacheDuration = 5; // 5 minutes
  static const int messagesCacheDuration = 2; // 2 minutes
  static const int attendanceCacheDuration = 5; // 5 minutes

  /// Check if cached data is still valid
  bool isCacheValid(String key, int maxAgeMinutes) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    final age = DateTime.now().difference(timestamp).inMinutes;
    return age < maxAgeMinutes;
  }

  /// Get data from cache (memory first, then storage)
  Future<T?> get<T>(String key) async {
    // Try memory cache first
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key] as T?;
    }

    // Try persistent storage
    try {
      final stored = await _storage.read(key: key);
      if (stored != null) {
        final data = jsonDecode(stored);
        // Store in memory for faster access
        _memoryCache[key] = data;
        // Try to restore timestamp
        final timestampStr = await _storage.read(key: '${key}_timestamp');
        if (timestampStr != null) {
          _cacheTimestamps[key] = DateTime.parse(timestampStr);
        }
        return data as T?;
      }
    } catch (e) {
      print('Cache read error for $key: $e');
    }
    return null;
  }

  /// Store data in cache (both memory and persistent storage)
  Future<void> set(String key, dynamic data) async {
    // Store in memory
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Store in persistent storage
    try {
      await _storage.write(key: key, value: jsonEncode(data));
      await _storage.write(
        key: '${key}_timestamp',
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Cache write error for $key: $e');
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    try {
      await _storage.delete(key: key);
      await _storage.delete(key: '${key}_timestamp');
    } catch (e) {
      print('Cache delete error for $key: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    try {
      // Only delete cache keys, not auth tokens
      for (final key in [
        keyProfile,
        keyAnnouncements,
        keyTasks,
        keyChannels,
        keyDirectMessages,
        keyAttendanceHistory,
        keyAttendanceToday,
      ]) {
        await _storage.delete(key: key);
        await _storage.delete(key: '${key}_timestamp');
      }
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  // ============ Convenience Methods ============

  /// Get cached profile
  Future<Map<String, dynamic>?> getCachedProfile() async {
    return await get<Map<String, dynamic>>(keyProfile);
  }

  /// Cache profile
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    await set(keyProfile, profile);
  }

  /// Get cached announcements
  Future<List<dynamic>?> getCachedAnnouncements() async {
    return await get<List<dynamic>>(keyAnnouncements);
  }

  /// Cache announcements
  Future<void> cacheAnnouncements(List<dynamic> announcements) async {
    await set(keyAnnouncements, announcements);
  }

  /// Get cached tasks
  Future<List<dynamic>?> getCachedTasks() async {
    return await get<List<dynamic>>(keyTasks);
  }

  /// Cache tasks
  Future<void> cacheTasks(List<dynamic> tasks) async {
    await set(keyTasks, tasks);
  }

  /// Get cached channels
  Future<List<dynamic>?> getCachedChannels() async {
    return await get<List<dynamic>>(keyChannels);
  }

  /// Cache channels
  Future<void> cacheChannels(List<dynamic> channels) async {
    await set(keyChannels, channels);
  }

  /// Get cached direct messages
  Future<List<dynamic>?> getCachedDirectMessages() async {
    return await get<List<dynamic>>(keyDirectMessages);
  }

  /// Cache direct messages
  Future<void> cacheDirectMessages(List<dynamic> dms) async {
    await set(keyDirectMessages, dms);
  }

  /// Get cached attendance history
  Future<List<dynamic>?> getCachedAttendanceHistory() async {
    return await get<List<dynamic>>(keyAttendanceHistory);
  }

  /// Cache attendance history
  Future<void> cacheAttendanceHistory(List<dynamic> history) async {
    await set(keyAttendanceHistory, history);
  }

  /// Get cached today's attendance
  Future<Map<String, dynamic>?> getCachedTodayAttendance() async {
    return await get<Map<String, dynamic>>(keyAttendanceToday);
  }

  /// Cache today's attendance
  Future<void> cacheTodayAttendance(Map<String, dynamic>? attendance) async {
    if (attendance != null) {
      await set(keyAttendanceToday, attendance);
    }
  }

  // ============ Message Caching for Offline Support ============

  /// Cache key for messages in a specific channel
  String _getMessagesKey(String channelId) => 'cache_messages_$channelId';

  /// Get cached messages for a channel
  Future<List<dynamic>?> getCachedMessages(String channelId) async {
    return await get<List<dynamic>>(_getMessagesKey(channelId));
  }

  /// Cache messages for a channel
  Future<void> cacheMessages(String channelId, List<dynamic> messages) async {
    // Only keep the last 100 messages to avoid storage bloat
    final toCache = messages.length > 100 ? messages.sublist(0, 100) : messages;
    await set(_getMessagesKey(channelId), toCache);
  }

  /// Add a message to the cache (for optimistic UI updates)
  Future<void> addMessageToCache(
      String channelId, Map<String, dynamic> message) async {
    final existing = await getCachedMessages(channelId) ?? [];
    final messages = [message, ...existing.cast<Map<String, dynamic>>()];
    await cacheMessages(channelId, messages);
  }

  // ============ Home Page Data Caching ============

  static const String keyHomeStats = 'cache_home_stats';
  static const String keyAuraScore = 'cache_aura_score';

  /// Get cached home stats
  Future<Map<String, dynamic>?> getCachedHomeStats() async {
    return await get<Map<String, dynamic>>(keyHomeStats);
  }

  /// Cache home stats
  Future<void> cacheHomeStats(Map<String, dynamic> stats) async {
    await set(keyHomeStats, stats);
  }

  /// Get cached AURA score
  Future<Map<String, dynamic>?> getCachedAuraScore() async {
    return await get<Map<String, dynamic>>(keyAuraScore);
  }

  /// Cache AURA score
  Future<void> cacheAuraScore(Map<String, dynamic> aura) async {
    await set(keyAuraScore, aura);
  }

  // ============ Reference Face Caching ============

  static const String keyReferenceFace = 'cache_reference_face';

  /// Get cached reference face
  Future<Map<String, dynamic>?> getCachedReferenceFace() async {
    return await get<Map<String, dynamic>>(keyReferenceFace);
  }

  /// Cache reference face
  Future<void> cacheReferenceFace(Map<String, dynamic> faceData) async {
    await set(keyReferenceFace, faceData);
  }
}
