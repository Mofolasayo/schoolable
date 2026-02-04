import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Service for local SQLite database operations.
/// Provides offline caching with stale-while-revalidate pattern.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const int _databaseVersion = 1;
  static const String _databaseName = 'schoolable_cache.db';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Cache table for API responses
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        expires_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // Profile cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profiles (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Tasks cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Announcements cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS announcements (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Aura data cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS aura_cache (
        user_id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Pending sync queue for offline mutations
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        body TEXT,
        created_at INTEGER NOT NULL,
        retries INTEGER DEFAULT 0
      )
    ''');

    debugPrint('📦 Database created');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here for future versions
    debugPrint('📦 Database upgraded from $oldVersion to $newVersion');
  }

  // ===== GENERIC CACHE OPERATIONS =====

  /// Set a cache entry with optional expiration
  Future<void> setCache(String key, dynamic data, {Duration? expiresIn}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = expiresIn != null ? now + expiresIn.inMilliseconds : null;

    await db.insert(
      'cache',
      {
        'key': key,
        'data': jsonEncode(data),
        'expires_at': expiresAt,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a cache entry
  Future<dynamic> getCache(String key) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> results = await db.query(
      'cache',
      where: 'key = ? AND (expires_at IS NULL OR expires_at > ?)',
      whereArgs: [key, now],
    );

    if (results.isEmpty) return null;

    return jsonDecode(results.first['data'] as String);
  }

  /// Delete a cache entry
  Future<void> deleteCache(String key) async {
    final db = await database;
    await db.delete('cache', where: 'key = ?', whereArgs: [key]);
  }

  /// Clear all expired cache entries
  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete(
      'cache',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [now],
    );
  }

  // ===== PROFILE CACHE =====

  /// Cache user profile
  Future<void> cacheProfile(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'profiles',
      {
        'id': id,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached profile
  Future<Map<String, dynamic>?> getCachedProfile(String id) async {
    final db = await database;
    final results =
        await db.query('profiles', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return jsonDecode(results.first['data'] as String);
  }

  // ===== TASKS CACHE =====

  /// Cache tasks list
  Future<void> cacheTasks(List<Map<String, dynamic>> tasks) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var task in tasks) {
      batch.insert(
        'tasks',
        {
          'id': task['id'],
          'data': jsonEncode(task),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached tasks
  Future<List<Map<String, dynamic>>> getCachedTasks() async {
    final db = await database;
    final results = await db.query('tasks', orderBy: 'updated_at DESC');

    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  /// Get single cached task
  Future<Map<String, dynamic>?> getCachedTask(int id) async {
    final db = await database;
    final results = await db.query('tasks', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return jsonDecode(results.first['data'] as String);
  }

  // ===== ANNOUNCEMENTS CACHE =====

  /// Cache announcements
  Future<void> cacheAnnouncements(
      List<Map<String, dynamic>> announcements) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var announcement in announcements) {
      batch.insert(
        'announcements',
        {
          'id': announcement['id'],
          'data': jsonEncode(announcement),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached announcements
  Future<List<Map<String, dynamic>>> getCachedAnnouncements() async {
    final db = await database;
    final results = await db.query('announcements', orderBy: 'updated_at DESC');

    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // ===== AURA DATA CACHE =====

  /// Cache Aura data
  Future<void> cacheAuraData(String userId, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'aura_cache',
      {
        'user_id': userId,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached Aura data
  Future<Map<String, dynamic>?> getCachedAuraData(String userId) async {
    final db = await database;
    final results =
        await db.query('aura_cache', where: 'user_id = ?', whereArgs: [userId]);

    if (results.isEmpty) return null;
    return jsonDecode(results.first['data'] as String);
  }

  // ===== PENDING SYNC QUEUE =====

  /// Add action to pending sync queue (for offline mutations)
  Future<void> queueForSync({
    required String action,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final db = await database;
    await db.insert('pending_sync', {
      'action': action,
      'endpoint': endpoint,
      'method': method,
      'body': body != null ? jsonEncode(body) : null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('📤 Queued for sync: $action');
  }

  /// Get all pending sync items
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('pending_sync', orderBy: 'created_at ASC');
  }

  /// Remove a pending sync item
  Future<void> removePendingSyncItem(int id) async {
    final db = await database;
    await db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
  }

  /// Increment retry count for a pending sync item
  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_sync SET retries = retries + 1 WHERE id = ?',
      [id],
    );
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM pending_sync');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===== UTILITY METHODS =====

  /// Clear all cached data
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cache');
    await db.delete('profiles');
    await db.delete('tasks');
    await db.delete('announcements');
    await db.delete('aura_cache');
    await db.delete('pending_sync');
    debugPrint('🗑️ All cache cleared');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
