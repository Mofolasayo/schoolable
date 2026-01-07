import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Minimal backend client to replace Supabase auth/profile flows.
class BackendApiService {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _cachedProfile;
  String? _inMemoryToken;

  String get _baseUrl {
    final url = dotenv.env['BACKEND_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BACKEND_URL is not set in assets/.env');
    }
    return url;
  }

  Future<String?> _getToken() async {
    // First check in-memory token
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      print('🔑 Using in-memory token');
      return _inMemoryToken;
    }
    // Fallback to secure storage
    final storedToken = await _storage.read(key: 'jwt_token');
    if (storedToken != null && storedToken.isNotEmpty) {
      print('🔑 Using stored token from secure storage');
      // Cache it in memory for future use
      _inMemoryToken = storedToken;
      return storedToken;
    }
    print('⚠️ No token found');
    return null;
  }

  Future<void> _saveToken(String token) async {
    print('💾 Saving token (length: ${token.length})');
    _inMemoryToken = token;
    await _storage.write(key: 'jwt_token', value: token);

    // Verify the token was saved correctly
    final verifyToken = await _storage.read(key: 'jwt_token');
    if (verifyToken == null || verifyToken.isEmpty) {
      print('❌ CRITICAL: Token save verification failed!');
      throw Exception('Failed to save authentication token');
    }

    print('✅ Token saved and verified (length: ${verifyToken.length})');
  }

  Future<void> clearSession() async {
    print('🗑️ Clearing session');
    _cachedProfile = null;
    _inMemoryToken = null;
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    String? token;
    if (auth) {
      token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ Auth required but no token available for $path');
        throw Exception('Not authenticated');
      }
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    print('📤 POST $path (auth: $auth, hasToken: ${token != null})');

    final resp = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('📥 Response: ${resp.statusCode}');
    if (resp.statusCode >= 400) {
      print('📥 Response body: ${resp.body}');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    }
    throw Exception(_extractError(resp));
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    String? token;
    if (auth) {
      token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ Auth required but no token available for $path');
        throw Exception('Not authenticated');
      }
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    print('📤 PATCH $path (auth: $auth, hasToken: ${token != null})');

    final resp = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('📥 Response: ${resp.statusCode}');
    if (resp.statusCode >= 400) {
      print('📥 Response body: ${resp.body}');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    }
    throw Exception(_extractError(resp));
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    String? token;
    if (auth) {
      token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ Auth required but no token available for $path');
        throw Exception('Not authenticated');
      }
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    print('📤 PUT $path (auth: $auth, hasToken: ${token != null})');

    final resp = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('📥 Response: ${resp.statusCode}');
    if (resp.statusCode >= 400) {
      print('📥 Response body: ${resp.body}');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    }
    throw Exception(_extractError(resp));
  }

  Future<Map<String, dynamic>> _delete(String path, {bool auth = true}) async {
    String? token;
    if (auth) {
      token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ Auth required but no token available for $path');
        throw Exception('Not authenticated');
      }
    }

    final headers = <String, String>{
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    print('📤 DELETE $path (auth: $auth, hasToken: ${token != null})');

    final resp =
        await http.delete(Uri.parse('$_baseUrl$path'), headers: headers);

    print('📥 Response: ${resp.statusCode}');
    if (resp.statusCode >= 400) {
      print('📥 Response body: ${resp.body}');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    }
    throw Exception(_extractError(resp));
  }

  Future<dynamic> _get(String path, {bool auth = true}) async {
    String? token;
    if (auth) {
      token = await _getToken();
      if (token == null || token.isEmpty) {
        print('❌ Auth required but no token available for $path');
        throw Exception('Not authenticated');
      }
    }

    final headers = <String, String>{
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    print('📤 GET $path (auth: $auth, hasToken: ${token != null})');

    final resp = await http.get(Uri.parse('$_baseUrl$path'), headers: headers);

    print('📥 Response: ${resp.statusCode}');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
    }
    throw Exception(_extractError(resp));
  }

  String _extractError(http.Response resp) {
    try {
      final body = jsonDecode(resp.body);
      if (body is Map && body['error'] != null) return body['error'].toString();
    } catch (_) {}
    return 'Request failed (${resp.statusCode})';
  }

  // ==================== FILE UPLOADS ====================

  /// Upload a file using multipart form data
  Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String fileName, {
    String folder = 'general',
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/storage/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', filePath,
        filename: fileName));

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    }
    throw Exception(_extractError(resp));
  }

  /// Upload a check-in photo
  Future<Map<String, dynamic>> uploadCheckInPhoto(String filePath) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/storage/attendance/photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    }
    throw Exception(_extractError(resp));
  }

  /// Upload a task attachment
  Future<Map<String, dynamic>> uploadTaskAttachment(
    int taskId,
    String filePath,
    String fileName,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/storage/tasks/$taskId/attachment');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath,
        filename: fileName));

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    }
    throw Exception(_extractError(resp));
  }

  /// Upload an avatar image
  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Updated to use the correct profile endpoint
    final uri = Uri.parse('$_baseUrl/profile/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    }
    throw Exception(_extractError(resp));
  }

  /// Update profile details
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? jobTitle,
    String? phone,
    String? address,
    String? city,
    String? state,
  }) async {
    print('📋 Updating profile details');
    return _post(
      '/profile/update',
      {
        if (fullName != null) 'fullName': fullName,
        if (jobTitle != null) 'jobTitle': jobTitle,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
      },
      auth: true,
    );
  }

  // ==================== TRAINING RECORDS ====================

  /// Get my training certificates
  Future<List<Map<String, dynamic>>> getTrainingRecords() async {
    try {
      final result = await _get('/api/performance/training-records/my');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching training records: $e');
      return [];
    }
  }

  /// Upload a certificate
  Future<Map<String, dynamic>> uploadCertificate(
    String filePath,
    String name,
    String quarter,
    int year,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/performance/training-records');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files
        .add(await http.MultipartFile.fromPath('certificate', filePath));
    request.fields['name'] = name;
    request.fields['quarter'] = quarter;
    request.fields['year'] = year.toString();

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    }
    throw Exception(_extractError(resp));
  }

  /// Upload from base64 string (useful for camera captures)
  Future<Map<String, dynamic>> uploadBase64({
    required String base64Data,
    String folder = 'general',
    String? filename,
  }) async {
    final result = await _post(
        '/storage/upload/base64',
        {
          'data': base64Data,
          'folder': folder,
          if (filename != null) 'filename': filename,
        },
        auth: true);
    return Map<String, dynamic>.from(result);
  }

  /// Check if storage service is available
  Future<bool> isStorageAvailable() async {
    try {
      final result = await _get('/storage/status', auth: false);
      return result['available'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Upload a chat/message attachment
  Future<Map<String, dynamic>> uploadChatAttachment(
    String channelId,
    String filePath,
    String fileName,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/storage/chat/$channelId/attachment');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath,
        filename: fileName));

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    }
    throw Exception(_extractError(resp));
  }

  /// Upload an announcement image
  Future<Map<String, dynamic>> uploadAnnouncementImage(
    String announcementId,
    String filePath,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri =
        Uri.parse('$_baseUrl/storage/announcements/$announcementId/image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(resp.body));
    }
    throw Exception(_extractError(resp));
  }

  // ----- Public API used by auth flows -----

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    print('📝 Signing up: $email');
    final res = await _post('/auth/signup', {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    return res;
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    print('✉️ Verifying email with token');
    return _post('/auth/verify-email', {'token': token});
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    print('🔄 Resending verification to: $email');
    return _post('/auth/resend-verification', {'email': email});
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 Signing in: $email');
    final res = await _post('/auth/login', {
      'email': email,
      'password': password,
    });

    final token = res['token'] as String?;
    final profile = res['profile'] as Map<String, dynamic>?;

    if (token == null || profile == null) {
      print(
          '❌ Invalid login response: token=${token != null}, profile=${profile != null}');
      throw Exception('Invalid login response');
    }

    print('✅ Login successful, saving token');
    await _saveToken(token);
    _cachedProfile = profile;

    // Verify token was saved
    final savedToken = await _getToken();
    print(
        '🔍 Token verification after save: ${savedToken != null ? 'OK' : 'FAILED'}');

    return res;
  }

  Future<Map<String, dynamic>?> getUserProfile(
      {bool forceRefresh = false}) async {
    if (_cachedProfile != null && !forceRefresh) {
      print('📋 Returning cached profile');
      return _cachedProfile;
    }
    print('📋 Fetching profile from server');
    final res = await _get('/profile/me');
    if (res is Map) {
      _cachedProfile = Map<String, dynamic>.from(res);
      return _cachedProfile;
    }
    return null;
  }

  /// Check if the current user's profile is complete (calls /profile/is-complete)
  /// Returns a map with: is_complete (bool), profile_completed_at, email, full_name
  Future<Map<String, dynamic>> checkProfileComplete() async {
    try {
      final res = await _get('/profile/is-complete');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {'is_complete': false};
    } catch (e) {
      print('Error checking profile completion: $e');
      return {'is_complete': false, 'error': e.toString()};
    }
  }

  Future<void> completeProfile({
    required String employeeId,
    required String phone,
    required String department,
    required String role,
    required DateTime dateJoined,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? state,
    bool isTeamLead = false,
    int? employeeLevel,
  }) async {
    print('📋 Completing profile');

    // Verify we have a token before making the request
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      print('❌ Cannot complete profile: No authentication token');
      throw Exception('Not authenticated. Please log in again.');
    }

    await _post(
        '/profile/complete',
        {
          'employeeId': employeeId,
          'phone': phone,
          'department': department,
          'role': role,
          'dateJoined': dateJoined.toIso8601String(),
          'gender': gender,
          'dateOfBirth': dateOfBirth != null
              ? '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}'
              : null,
          'address': address,
          'city': city,
          'state': state,
          'isTeamLead': isTeamLead,
          if (employeeLevel != null) 'employeeLevel': employeeLevel,
        },
        auth: true);

    print('✅ Profile completed successfully');
  }

  Future<bool> hasSession() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  /// Sign out the current user and clear all session data
  Future<void> signOut() async {
    await clearSession();
  }

  /// Get the cached profile if available
  Map<String, dynamic>? get cachedProfile => _cachedProfile;

  /// Check if user is currently logged in (has a valid token)
  Future<bool> isLoggedIn() async {
    return await hasSession();
  }

  /// Get the current JWT token (for WebSocket authentication)
  Future<String?> getCurrentToken() async {
    return await _getToken();
  }

  /// Debug: Print current auth state
  Future<void> debugAuthState() async {
    print('=== Auth State Debug ===');
    print(
        'In-memory token: ${_inMemoryToken != null ? 'Present (${_inMemoryToken!.length} chars)' : 'None'}');
    final storedToken = await _storage.read(key: 'jwt_token');
    print(
        'Stored token: ${storedToken != null ? 'Present (${storedToken.length} chars)' : 'None'}');
    print('Cached profile: ${_cachedProfile != null ? 'Present' : 'None'}');
    print('========================');
  }

  // ==================== ANNOUNCEMENTS ====================

  /// Get all announcements (with read status) for current user
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final result = await _get('/announcements');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  /// Get unread announcements for current user
  Future<List<Map<String, dynamic>>> getUnreadAnnouncements() async {
    try {
      final result = await _get('/announcements/unread');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching unread announcements: $e');
      return [];
    }
  }

  /// Mark an announcement as read
  Future<void> markAnnouncementAsRead(String announcementId) async {
    try {
      await _post('/announcements/$announcementId/read', {}, auth: true);
    } catch (e) {
      print('Error marking announcement as read: $e');
    }
  }

  // ==================== MESSAGING ====================

  /// Get all channels the current user is a member of
  Future<List<Map<String, dynamic>>> getMyChannels() async {
    try {
      final result = await _get('/messaging/channels');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching channels: $e');
      return [];
    }
  }

  /// Get all public channels
  Future<List<Map<String, dynamic>>> getPublicChannels() async {
    try {
      final result = await _get('/messaging/channels/public');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching public channels: $e');
      return [];
    }
  }

  /// Get or create a DM channel with another user
  Future<Map<String, dynamic>> getOrCreateDM(String otherUserId) async {
    final result = await _post('/messaging/dm/$otherUserId', {}, auth: true);
    return Map<String, dynamic>.from(result);
  }

  /// Get messages for a channel
  Future<List<Map<String, dynamic>>> getMessages(String channelId,
      {int limit = 50}) async {
    try {
      final result =
          await _get('/messaging/channels/$channelId/messages?limit=$limit');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// Send a message to a channel
  Future<Map<String, dynamic>?> sendMessage(
      String channelId, String content) async {
    try {
      final result = await _post(
          '/messaging/channels/$channelId/messages',
          {
            'content': content,
          },
          auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Mark a channel as read (for read receipts)
  Future<bool> markChannelAsRead(String channelId) async {
    try {
      await _post('/messaging/channels/$channelId/read', {}, auth: true);
      return true;
    } catch (e) {
      print('Error marking channel as read: $e');
      return false;
    }
  }

  /// Get unread message count for a channel
  Future<int> getUnreadCount(String channelId) async {
    try {
      final result = await _get('/messaging/channels/$channelId/unread');
      return (result['unread_count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Send heartbeat to update online status
  Future<bool> sendHeartbeat() async {
    try {
      await _post('/messaging/heartbeat', {}, auth: true);
      return true;
    } catch (e) {
      print('Error sending heartbeat: $e');
      return false;
    }
  }

  /// Get list of online users (active in last 2 minutes)
  Future<List<String>> getOnlineUserIds() async {
    try {
      final result = await _get('/messaging/online');
      if (result is List) {
        return result
            .map((u) => u['id']?.toString())
            .where((id) => id != null)
            .cast<String>()
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting online users: $e');
      return [];
    }
  }

  /// Create a new channel
  Future<Map<String, dynamic>?> createChannel(String name, String type,
      {List<String>? memberIds}) async {
    try {
      final result = await _post(
          '/messaging/channels',
          {
            'name': name,
            'type': type,
            if (memberIds != null) 'memberIds': memberIds,
          },
          auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error creating channel: $e');
      return null;
    }
  }

  /// Join a public channel
  Future<bool> joinChannel(String channelId) async {
    try {
      await _post('/messaging/channels/$channelId/join', {}, auth: true);
      return true;
    } catch (e) {
      print('Error joining channel: $e');
      return false;
    }
  }

  /// Leave a channel
  Future<bool> leaveChannel(String channelId) async {
    try {
      await _post('/messaging/channels/$channelId/leave', {}, auth: true);
      return true;
    } catch (e) {
      print('Error leaving channel: $e');
      return false;
    }
  }

  /// Get channel members
  Future<List<Map<String, dynamic>>> getChannelMembers(String channelId) async {
    try {
      final result = await _get('/messaging/channels/$channelId/members');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching channel members: $e');
      return [];
    }
  }

  /// Add members to a channel
  Future<bool> addMembersToChannel(
      String channelId, List<String> userIds) async {
    try {
      await _post(
          '/messaging/channels/$channelId/members',
          {
            'userIds': userIds,
          },
          auth: true);
      return true;
    } catch (e) {
      print('Error adding members: $e');
      return false;
    }
  }

  /// Get all staff profiles (for chat user selection)
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final result = await _get('/profile/all');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }

  /// Get staff for chat - excludes current user and admin/super_admin roles
  Future<List<Map<String, dynamic>>> getStaffForChat() async {
    final allStaff = await getAllStaff();
    final myId = currentUserId;

    // Filter out:
    // 1. Current user (can't message yourself)
    // 2. Admin/Super Admin roles (typically shouldn't message directly)
    return allStaff.where((user) {
      final userId = user['id']?.toString();
      final role = (user['role'] as String?)?.toLowerCase() ?? '';

      // Skip if it's the current user
      if (userId == myId) return false;

      // Skip admin and super_admin roles
      if (role == 'admin' || role == 'super_admin') return false;

      return true;
    }).toList();
  }

  /// Get last message content for a channel (from the channel response)
  String? getLastMessageFromChannel(Map<String, dynamic> channel) {
    return channel['last_message'] as String?;
  }

  /// Get the other user in a DM channel
  Map<String, dynamic>? getOtherUserFromChannel(Map<String, dynamic> channel) {
    if (channel['type'] == 'dm' && channel['other_user'] != null) {
      return Map<String, dynamic>.from(channel['other_user'] as Map);
    }
    return null;
  }

  // ==================== ATTENDANCE ====================

  /// Check in (for mobile app)
  Future<Map<String, dynamic>?> checkIn({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? address,
    String? photoUrl,
    String? deviceInfo,
    String? note,
    bool isRemote = false,
  }) async {
    try {
      final result = await _post(
          '/attendance/check-in',
          {
            'latitude': latitude,
            'longitude': longitude,
            if (accuracy != null) 'accuracy': accuracy,
            if (address != null) 'address': address,
            if (photoUrl != null) 'photoUrl': photoUrl,
            if (deviceInfo != null) 'deviceInfo': deviceInfo,
            if (note != null) 'note': note,
            'isRemote': isRemote,
          },
          auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error checking in: $e');
      return null;
    }
  }

  /// Check out (for mobile app)
  Future<Map<String, dynamic>?> checkOut({String? note}) async {
    try {
      final result = await _post(
          '/attendance/check-out',
          {
            if (note != null) 'note': note,
          },
          auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error checking out: $e');
      return null;
    }
  }

  /// Get today's attendance status
  Future<Map<String, dynamic>?> getTodayAttendance() async {
    try {
      final result = await _get('/attendance/today');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error fetching today attendance: $e');
      return null;
    }
  }

  /// Get attendance history
  Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    try {
      final result = await _get('/attendance/history');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching attendance history: $e');
      return [];
    }
  }

  /// Get office locations (for geo-fencing)
  Future<List<Map<String, dynamic>>> getOfficeLocations() async {
    try {
      final result = await _get('/attendance/offices');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching office locations: $e');
      return [];
    }
  }

  // ==================== REFERENCE FACE ====================

  /// Get registered reference face for current user
  Future<Map<String, dynamic>?> getReferenceFace() async {
    try {
      final result = await _get('/attendance/reference-face', auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error fetching reference face: $e');
      return null;
    }
  }

  /// Register or update reference face
  Future<Map<String, dynamic>?> registerReferenceFace({
    required String photoUrl,
  }) async {
    try {
      final result = await _post(
        '/attendance/reference-face',
        {'photo_url': photoUrl},
        auth: true,
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error registering reference face: $e');
      return null;
    }
  }

  /// Compare check-in photo with reference face (backend would use ML)
  Future<Map<String, dynamic>?> compareFaces({
    required String checkInPhotoUrl,
  }) async {
    try {
      final result = await _post(
        '/attendance/compare-faces',
        {'check_in_photo_url': checkInPhotoUrl},
        auth: true,
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error comparing faces: $e');
      return null;
    }
  }

  // ==================== PULSE SURVEYS ====================

  /// Get current pulse survey (if any)
  Future<Map<String, dynamic>?> getCurrentPulseSurvey() async {
    try {
      final result = await _get('/surveys/pulse/current', auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error fetching pulse survey: $e');
      return null;
    }
  }

  /// Submit pulse survey response
  Future<bool> submitPulseSurveyResponse({
    required String surveyId,
    required int rating, // 1-5
    String? comment,
  }) async {
    try {
      await _post(
        '/surveys/pulse/$surveyId/respond',
        {
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
        auth: true,
      );
      return true;
    } catch (e) {
      print('Error submitting pulse survey: $e');
      return false;
    }
  }

  // ==================== TASK QUALITY RATING ====================

  /// Get tasks pending quality rating (tasks I created that are completed)
  Future<Map<String, dynamic>> getTasksPendingRating() async {
    try {
      final result = await _get('/tasks/rating/pending');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error fetching tasks pending rating: $e');
      return {'pendingRatings': [], 'count': 0};
    }
  }

  /// Rate a completed task
  Future<Map<String, dynamic>?> rateTask({
    required int taskId,
    required int rating,
    String? comment,
  }) async {
    try {
      final result = await _post(
        '/tasks/$taskId/rate',
        {
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
        auth: true,
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error rating task: $e');
      return null;
    }
  }

  /// Get average quality rating for an employee
  Future<Map<String, dynamic>> getAverageRating(String employeeId) async {
    try {
      final result = await _get('/tasks/rating/average/$employeeId');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error fetching average rating: $e');
      return {'averageRating': null, 'hasRatings': false};
    }
  }

  // ==================== TASKS ====================

  /// Get tasks assigned to current user
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final result = await _get('/tasks/assigned');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  /// Get a single task by ID
  Future<Map<String, dynamic>?> getTask(int taskId) async {
    try {
      final result = await _get('/tasks/$taskId');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error fetching task: $e');
      return null;
    }
  }

  /// Update task status
  Future<bool> updateTaskStatus(int taskId, String status, int progress) async {
    try {
      await _patch('/tasks/$taskId/status', {
        'status': status,
        'progress': progress,
      });
      return true;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  /// Update subtask completion status
  Future<bool> updateSubtaskStatus(int subtaskId, bool completed) async {
    try {
      await _patch('/tasks/subtasks/$subtaskId', {
        'completed': completed,
      });
      return true;
    } catch (e) {
      print('Error updating subtask: $e');
      return false;
    }
  }

  /// Add a comment to a task
  Future<bool> createTaskComment(int taskId, String content) async {
    try {
      await _post(
          '/tasks/$taskId/comments',
          {
            'content': content,
          },
          auth: true);
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  /// Update task description
  Future<bool> updateTaskDescription(int taskId, String description) async {
    try {
      await _patch('/tasks/$taskId/description', {
        'description': description,
      });
      return true;
    } catch (e) {
      print('Error updating description: $e');
      return false;
    }
  }

  /// Complete a task (set to 100% and Completed status)
  Future<bool> completeTask(int taskId) async {
    return updateTaskStatus(taskId, 'Completed', 100);
  }

  /// Create a new task
  Future<Map<String, dynamic>?> createTask({
    required String title,
    required String description,
    required String organization, // department
    String priority = 'Medium',
    String? dueDate,
    String? assigneeId,
    List<String> tags = const [],
    List<Map<String, String>> subtasks = const [],
  }) async {
    try {
      final result = await _post(
          '/tasks',
          {
            'title': title,
            'description': description,
            'organization': organization,
            'priority': priority,
            if (dueDate != null) 'dueDate': dueDate,
            if (assigneeId != null) 'assigneeId': assigneeId,
            'tags': tags,
            'subtasks': subtasks,
            'attachments': [],
          },
          auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  /// Add a subtask to a task
  Future<Map<String, dynamic>?> addSubtask(int taskId, String title) async {
    try {
      final result = await _post(
          '/tasks/$taskId/subtasks',
          {
            'title': title,
          },
          auth: true);
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error adding subtask: $e');
      return null;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(int taskId) async {
    try {
      // DELETE usually has no body, but _post is not suited. We need _delete.
      // Since _delete isn't implemented (checked earlier, only get, post, patch),
      // I'll implement a simple _delete helper first or use http directly here.
      // Let's check if _delete exists. It doesn't appear in the lines I read (lines 1-133).
      // I'll implement a dedicated delete request here.

      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('$_baseUrl/tasks/$taskId');
      final resp = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // ==================== HELPERS ====================

  /// Get current user ID from cached profile
  String? get currentUserId => _cachedProfile?['id'] as String?;

  /// Generate DiceBear avatar URL based on gender
  /// This matches the SupabaseService implementation
  String getAvatarUrl(String? gender, String seed) {
    String style;
    if (gender?.toLowerCase() == 'male') {
      style = 'adventurer';
    } else if (gender?.toLowerCase() == 'female') {
      style = 'adventurer-neutral';
    } else {
      style = 'bottts';
    }
    return 'https://api.dicebear.com/7.x/$style/svg?seed=$seed';
  }

  /// Request password reset email
  Future<bool> resetPasswordForEmail({required String email}) async {
    try {
      await _post('/auth/reset-password', {'email': email});
      return true;
    } catch (e) {
      print('Error requesting password reset: $e');
      return false;
    }
  }

  /// Verify reset code
  Future<bool> verifyResetCode(String code) async {
    try {
      final result = await _post('/auth/verify-reset-code', {'code': code});
      return result['valid'] == true;
    } catch (e) {
      print('Error verifying reset code: $e');
      return false;
    }
  }

  /// Complete password reset with new password
  Future<bool> completePasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _post('/auth/complete-reset', {
        'code': code,
        'newPassword': newPassword,
      });
      return true;
    } catch (e) {
      print('Error completing password reset: $e');
      return false;
    }
  }

  // ==================== AURA PERFORMANCE ====================

  /// Get Aura dashboard for the current user
  Future<Map<String, dynamic>?> getMyAuraDashboard() async {
    try {
      final result = await _get('/api/performance/aura/dashboard');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching Aura dashboard: $e');
      return null;
    }
  }

  /// Get Aura dashboard for a specific employee
  Future<Map<String, dynamic>?> getAuraDashboard(String employeeId) async {
    try {
      final result =
          await _get('/api/performance/aura/dashboard?employeeId=$employeeId');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching Aura dashboard for $employeeId: $e');
      return null;
    }
  }

  /// Submit peer feedback for a colleague
  Future<bool> submitPeerFeedback({
    required String toEmployeeId,
    required int supportRating,
    int? collaborationRating,
    int? communicationRating,
    String? strengths,
    String? areasForImprovement,
    bool isAnonymous = true,
  }) async {
    try {
      await _post(
          '/api/performance/peer-feedback',
          {
            'toEmployeeId': toEmployeeId,
            'supportRating': supportRating,
            if (collaborationRating != null)
              'collaborationRating': collaborationRating,
            if (communicationRating != null)
              'communicationRating': communicationRating,
            if (strengths != null) 'strengths': strengths,
            if (areasForImprovement != null)
              'areasForImprovement': areasForImprovement,
            'isAnonymous': isAnonymous,
          },
          auth: true);
      return true;
    } catch (e) {
      print('Error submitting peer feedback: $e');
      return false;
    }
  }

  /// Get peer feedback received by current user
  Future<Map<String, dynamic>?> getReceivedPeerFeedback() async {
    try {
      final result = await _get('/api/performance/peer-feedback/received');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching received peer feedback: $e');
      return null;
    }
  }

  /// Get AUTO-CALCULATED Aura dashboard with department-specific KPIs
  /// This uses real-time data from tasks, attendance, compliance, and training
  Future<Map<String, dynamic>?> getAutoAuraDashboard() async {
    try {
      final result = await _get('/api/performance/my-aura/auto');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching auto Aura dashboard: $e');
      return null;
    }
  }

  /// Get auto-calculated Aura dashboard for a specific employee
  Future<Map<String, dynamic>?> getAutoAuraDashboardFor(
      String employeeId) async {
    try {
      final result =
          await _get('/api/performance/employee/$employeeId/aura/auto');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching auto Aura for $employeeId: $e');
      return null;
    }
  }

  /// Get available department KPI profiles
  Future<Map<String, dynamic>?> getDepartmentKpis() async {
    try {
      final result = await _get('/api/performance/department-kpis');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching department KPIs: $e');
      return null;
    }
  }

  /// Submit extended peer feedback with all rating fields
  Future<bool> submitExtendedPeerFeedback({
    required String toEmployeeId,
    required String quarter,
    required int year,
    required int supportRating,
    int? collaborationRating,
    int? adaptabilityRating,
    int? valuesRating,
    int? accountabilityRating,
    int? feedbackRating,
    // For team leads
    int? orgGuidanceRating,
    int? peopleCultureRating,
    int? influenceRating,
    String? strengths,
    String? areasForImprovement,
    bool isAnonymous = true,
  }) async {
    try {
      await _post(
          '/api/performance/peer-feedback',
          {
            'toEmployeeId': toEmployeeId,
            'quarter': quarter,
            'year': year,
            'supportRating': supportRating,
            if (collaborationRating != null)
              'collaborationRating': collaborationRating,
            if (adaptabilityRating != null)
              'adaptabilityRating': adaptabilityRating,
            if (valuesRating != null) 'valuesRating': valuesRating,
            if (accountabilityRating != null)
              'accountabilityRating': accountabilityRating,
            if (feedbackRating != null) 'feedbackRating': feedbackRating,
            if (orgGuidanceRating != null)
              'orgGuidanceRating': orgGuidanceRating,
            if (peopleCultureRating != null)
              'peopleCultureRating': peopleCultureRating,
            if (influenceRating != null) 'influenceRating': influenceRating,
            if (strengths != null) 'strengths': strengths,
            if (areasForImprovement != null)
              'areasForImprovement': areasForImprovement,
            'isAnonymous': isAnonymous,
          },
          auth: true);
      return true;
    } catch (e) {
      print('Error submitting extended peer feedback: $e');
      return false;
    }
  }

  /// Get peer feedback submission status
  Future<Map<String, dynamic>?> getPeerFeedbackStatus() async {
    try {
      final result = await _get('/api/performance/peer-feedback/status');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching peer feedback status: $e');
      return null;
    }
  }

  // --- GROWTH & LEARNING / CERTIFICATES ---

  /// Check certificate submission status for current quarter
  Future<Map<String, dynamic>?> getCurrentQuarterCertificateStatus() async {
    try {
      final result =
          await _get('/api/performance/training-records/my/current-quarter');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error checking certificate status: $e');
      return null;
    }
  }

  // --- ACCOUNT MANAGEMENT ---

  /// Delete the current user's own account
  /// Returns true on success, throws Exception on failure
  Future<bool> deleteMyAccount() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('$_baseUrl/profile/me');
      final resp = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Clear local session after successful deletion
        await clearSession();
        return true;
      }

      // Extract error message from response
      try {
        final body = jsonDecode(resp.body);
        if (body is Map && body['error'] != null) {
          throw Exception(body['error'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to delete account (${resp.statusCode})');
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // --- COMPLIANCE ---

  /// Get pending compliance items for the current user
  Future<List<Map<String, dynamic>>> getMyComplianceItems() async {
    try {
      final result = await _get('/compliance/my-items', auth: true);
      if (result is List) {
        return result.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching compliance items: $e');
      return [];
    }
  }

  /// Submit a compliance item (acknowledge policy or upload document)
  /// [policyId] - The ID of the policy to submit for
  /// [type] - 'policy' for acknowledgement, 'upload' for document upload
  /// [fileUrl] - URL of uploaded file (for upload type)
  /// [fileName] - Name of uploaded file (for upload type)
  Future<Map<String, dynamic>> submitCompliance({
    required String policyId,
    required String type,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
      };

      if (type == 'upload') {
        body['fileUrl'] = fileUrl;
        body['fileName'] = fileName;
      }

      final result = await _post(
        '/compliance/my-items/$policyId/submit',
        body,
        auth: true,
      );
      return result;
    } catch (e) {
      print('Error submitting compliance: $e');
      rethrow;
    }
  }

  /// Submit a policy acknowledgement
  Future<bool> acknowledgePolicy(String policyId) async {
    try {
      await submitCompliance(policyId: policyId, type: 'policy');
      return true;
    } catch (e) {
      print('Error acknowledging policy: $e');
      return false;
    }
  }

  /// Submit a compliance document upload
  Future<bool> submitComplianceDocument({
    required String policyId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      // First upload the file
      final uploadResult =
          await uploadFile(filePath, fileName, folder: 'compliance');
      final fileUrl = uploadResult['url'] as String?;

      if (fileUrl == null) {
        throw Exception('Failed to upload file');
      }

      // Then submit the compliance
      await submitCompliance(
        policyId: policyId,
        type: 'upload',
        fileUrl: fileUrl,
        fileName: fileName,
      );
      return true;
    } catch (e) {
      print('Error submitting compliance document: $e');
      return false;
    }
  }

  // ==================== TEAM KPIs & AI INSIGHTS ====================

  /// Get team KPIs for the current user's department
  Future<Map<String, dynamic>?> getTeamKpis(
      {String? quarter, int? year}) async {
    try {
      String endpoint = '/api/kpi/team-kpis';
      final params = <String, String>{};
      if (quarter != null) params['quarter'] = quarter;
      if (year != null) params['year'] = year.toString();
      if (params.isNotEmpty) {
        endpoint +=
            '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }
      final result = await _get(endpoint);
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching team KPIs: $e');
      return null;
    }
  }

  /// Get latest AI insight for the team
  Future<Map<String, dynamic>?> getTeamInsight() async {
    try {
      final result = await _get('/api/kpi/insights/team');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching team insight: $e');
      return null;
    }
  }

  /// Get team quarterly score
  Future<Map<String, dynamic>?> getMyTeamScore(
      {String? quarter, int? year}) async {
    try {
      String endpoint = '/api/kpi/score/my-team';
      final params = <String, String>{};
      if (quarter != null) params['quarter'] = quarter;
      if (year != null) params['year'] = year.toString();
      if (params.isNotEmpty) {
        endpoint +=
            '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }
      final result = await _get(endpoint);
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error fetching team score: $e');
      return null;
    }
  }

  // ===================== PEER HELPFULNESS RATINGS =====================

  /// Get colleagues to rate for helpfulness
  Future<Map<String, dynamic>> getColleaguesToRate(
      {int? weekNumber, int? year}) async {
    String endpoint = '/api/peer-helpfulness/colleagues';
    final params = <String, String>{};
    if (weekNumber != null) params['weekNumber'] = weekNumber.toString();
    if (year != null) params['year'] = year.toString();
    if (params.isNotEmpty) {
      endpoint +=
          '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    return await _get(endpoint);
  }

  /// Submit weekly peer helpfulness ratings
  Future<Map<String, dynamic>> submitPeerHelpfulnessRatings(
    List<Map<String, dynamic>> ratings, {
    int? weekNumber,
    int? year,
  }) async {
    String endpoint = '/api/peer-helpfulness/submit';
    final params = <String, String>{};
    if (weekNumber != null) params['weekNumber'] = weekNumber.toString();
    if (year != null) params['year'] = year.toString();
    if (params.isNotEmpty) {
      endpoint +=
          '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    return await _post(endpoint, {'ratings': ratings}, auth: true);
  }

  /// Get peer helpfulness rating status for current user
  Future<Map<String, dynamic>> getPeerHelpfulnessStatus() async {
    return await _get('/api/peer-helpfulness/status');
  }

  /// Get ratings received from colleagues
  Future<Map<String, dynamic>> getReceivedRatings(
      {int? weekNumber, int? year}) async {
    String endpoint = '/api/peer-helpfulness/received';
    final params = <String, String>{};
    if (weekNumber != null) params['weekNumber'] = weekNumber.toString();
    if (year != null) params['year'] = year.toString();
    if (params.isNotEmpty) {
      endpoint +=
          '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    return await _get(endpoint);
  }

  // ==================== PUSH NOTIFICATIONS ====================

  /// Register device token for push notifications
  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceInfo,
  }) async {
    return await _post(
        '/api/notifications/register-device',
        {
          'token': token,
          'platform': platform,
          'deviceInfo': deviceInfo,
        },
        auth: true);
  }

  /// Unregister device token
  Future<Map<String, dynamic>> unregisterDeviceToken({
    required String token,
  }) async {
    return await _post(
        '/api/notifications/unregister-device',
        {
          'token': token,
        },
        auth: true);
  }

  /// Get notification history
  Future<Map<String, dynamic>> getNotifications() async {
    return await _get('/api/notifications');
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final result = await _get('/api/notifications/unread-count');
      return result['unreadCount'] as int? ?? 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      await _post('/api/notifications/$notificationId/read', {}, auth: true);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      await _post('/api/notifications/mark-all-read', {}, auth: true);
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // ==================== DYNAMIC KPIS ====================

  /// Get department KPI profile
  Future<Map<String, dynamic>> getDepartmentKpiProfile(
      String department) async {
    return await _get('/api/kpi/department/$department/profile');
  }

  /// Get all department automation stats
  Future<List<Map<String, dynamic>>> getDepartmentAutomationStats() async {
    try {
      final result = await _get('/api/kpi/departments/automation-stats');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching department stats: $e');
      return [];
    }
  }

  /// Create a new team KPI (for team leads)
  Future<Map<String, dynamic>> createTeamKpi({
    required String name,
    required String description,
    required double targetValue,
    required String targetUnit,
    required int weight,
    String? quarter,
    int? year,
  }) async {
    return await _post(
        '/api/kpi/team-kpi',
        {
          'name': name,
          'description': description,
          'targetValue': targetValue,
          'targetUnit': targetUnit,
          'weight': weight,
          'quarter': quarter ?? _getCurrentQuarter(),
          'year': year ?? DateTime.now().year,
        },
        auth: true);
  }

  /// Update a team KPI
  Future<Map<String, dynamic>> updateTeamKpi({
    required String kpiId,
    double? targetValue,
    double? currentValue,
    int? weight,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (targetValue != null) body['targetValue'] = targetValue;
    if (currentValue != null) body['currentValue'] = currentValue;
    if (weight != null) body['weight'] = weight;
    if (isActive != null) body['isActive'] = isActive;
    return await _put('/api/kpi/team-kpi/$kpiId', body);
  }

  /// Delete a team KPI
  Future<bool> deleteTeamKpi(String kpiId) async {
    try {
      await _delete('/api/kpi/team-kpi/$kpiId');
      return true;
    } catch (e) {
      print('Error deleting KPI: $e');
      return false;
    }
  }

  // ==================== AUDIT LOGS ====================

  /// Get audit logs (admin only)
  Future<Map<String, dynamic>> getAuditLogs({
    int page = 0,
    int size = 50,
    String? entityType,
  }) async {
    String endpoint = '/api/audit/logs?page=$page&size=$size';
    if (entityType != null) endpoint += '&entityType=$entityType';
    return await _get(endpoint);
  }

  /// Get audit logs for a specific entity
  Future<Map<String, dynamic>> getEntityAuditLogs(
      String entityType, String entityId) async {
    return await _get('/api/audit/logs/$entityType/$entityId');
  }

  // ==================== DAILY REPORTS ====================

  /// Get my daily reports
  Future<List<dynamic>> getMyReports({int? limit}) async {
    String endpoint = '/api/daily-reports/my';
    if (limit != null) endpoint += '?limit=$limit';
    final response = await _get(endpoint);
    return response is List ? response : [];
  }

  /// Get today's report status
  Future<Map<String, dynamic>> getTodayReport() async {
    return await _get('/api/daily-reports/today');
  }

  /// Submit a daily report
  Future<Map<String, dynamic>> submitDailyReport({
    required String tasksCompleted,
    String? tasksInProgress,
    String? blockers,
    String? plannedForTomorrow,
    String? additionalNotes,
    String? attachmentUrl,
    String? attachmentName,
    DateTime? reportDate,
  }) async {
    return await _post(
        '/api/daily-reports',
        {
          'tasksCompleted': tasksCompleted,
          if (tasksInProgress != null) 'tasksInProgress': tasksInProgress,
          if (blockers != null) 'blockers': blockers,
          if (plannedForTomorrow != null)
            'plannedForTomorrow': plannedForTomorrow,
          if (additionalNotes != null) 'additionalNotes': additionalNotes,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
          if (attachmentName != null) 'attachmentName': attachmentName,
          if (reportDate != null)
            'reportDate': reportDate.toIso8601String().split('T')[0],
        },
        auth: true);
  }

  /// Update today's daily report
  Future<Map<String, dynamic>> updateDailyReport({
    required int reportId,
    String? tasksCompleted,
    String? tasksInProgress,
    String? blockers,
    String? plannedForTomorrow,
    String? additionalNotes,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    return await _put('/api/daily-reports/$reportId', {
      if (tasksCompleted != null) 'tasksCompleted': tasksCompleted,
      if (tasksInProgress != null) 'tasksInProgress': tasksInProgress,
      if (blockers != null) 'blockers': blockers,
      if (plannedForTomorrow != null) 'plannedForTomorrow': plannedForTomorrow,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentName != null) 'attachmentName': attachmentName,
    });
  }

  /// Get my daily report stats
  Future<Map<String, dynamic>> getDailyReportStats() async {
    return await _get('/api/daily-reports/stats');
  }

  // ==================== INDIVIDUAL KPIS ====================

  /// Get my individual KPIs
  Future<Map<String, dynamic>> getMyIndividualKpis({
    String? quarter,
    int? year,
  }) async {
    String endpoint = '/api/individual-kpis/my';
    List<String> params = [];
    if (quarter != null) params.add('quarter=$quarter');
    if (year != null) params.add('year=$year');
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';
    return await _get(endpoint);
  }

  // ==================== HELPER METHODS ====================

  String _getCurrentQuarter() {
    final month = DateTime.now().month;
    if (month <= 3) return 'Q1';
    if (month <= 6) return 'Q2';
    if (month <= 9) return 'Q3';
    return 'Q4';
  }
}
