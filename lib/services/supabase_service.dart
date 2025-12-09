import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // Temporary storage for password during signup flow
  String? _tempPassword;

  void setTempPassword(String password) {
    _tempPassword = password;
  }

  String? get tempPassword => _tempPassword;

  // Auth
  User? get currentUser => _client.auth.currentUser;

  // Check if user email is confirmed
  bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;

  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    return await _client.auth
        .signInWithPassword(email: email, password: password);
  }

  // Sign up with extended metadata (Deferred Signup)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? employeeId,
    String? phone,
    String? department,
    String? role,
    DateTime? dateJoined,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? state,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (employeeId != null) 'employee_id': employeeId,
        if (phone != null) 'phone': phone,
        if (department != null) 'department': department,
        if (role != null) 'role': role,
        if (dateJoined != null) 'date_joined': dateJoined.toIso8601String(),
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
      },
      emailRedirectTo: null,
    );
  }

  // Resend confirmation email
  Future<void> resendConfirmationEmail({required String email}) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // Reset password - sends email with reset link
  Future<void> resetPasswordForEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Update user profile with additional information
  Future<void> updateProfile({
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
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    // Update user metadata
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          ...user.userMetadata ?? {},
          'employee_id': employeeId,
          'phone': phone,
          'department': department,
          'role': role,
          'date_joined': dateJoined.toIso8601String(),
          if (gender != null) 'gender': gender,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String(),
          if (address != null) 'address': address,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
        },
      ),
    );

    // Save to profiles table (create if doesn't exist)
    final profileData = {
      'id': user.id,
      'employee_id': employeeId,
      'phone': phone,
      'department': department,
      'role': role,
      'date_joined': dateJoined.toIso8601String(),
      'full_name': user.userMetadata?['full_name'],
      'email': user.email,
      'updated_at': DateTime.now().toIso8601String(),
      'status': 'active', // Default status for new users
    };

    // Add optional fields if provided
    if (gender != null) profileData['gender'] = gender;
    if (dateOfBirth != null) {
      // Format as date only (YYYY-MM-DD) for DATE column
      final dateStr =
          '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
      profileData['date_of_birth'] = dateStr;
    }
    if (address != null) profileData['address'] = address;
    if (city != null) profileData['city'] = city;
    if (state != null) profileData['state'] = state;

    print('📝 Saving profile data: $profileData');

    try {
      final response =
          await _client.from('profiles').upsert(profileData).select();
      print('✅ Profile saved successfully: $response');
    } catch (e) {
      print('❌ Error saving profile: $e');
      rethrow;
    }
  }

  // Get all staff profiles for DM selection
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .neq('id', currentUser?.id ?? '') // Exclude self
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }

  Future<void> signOut() async {
    clearProfileCache();
    await _client.auth.signOut();
  }

  // Cache for user profile to prevent flickering
  Map<String, dynamic>? _cachedProfile;

  // Get user profile from profiles table
  Future<Map<String, dynamic>?> getUserProfile(
      {bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return null;

    // Return cached profile if available and not forcing refresh
    if (_cachedProfile != null && !forceRefresh) {
      return _cachedProfile;
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      _cachedProfile = response;
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  void clearProfileCache() {
    _cachedProfile = null;
  }

  // Generate DiceBear avatar URL based on gender
  String getAvatarUrl(String? gender, String seed) {
    // DiceBear API v7
    // Choose style based on gender
    String style;
    if (gender?.toLowerCase() == 'male') {
      style = 'adventurer'; // Male avatar style
    } else if (gender?.toLowerCase() == 'female') {
      style = 'adventurer-neutral'; // Female avatar style
    } else {
      style = 'bottts'; // Neutral/robot style
    }

    return 'https://api.dicebear.com/7.x/$style/svg?seed=$seed';
  }

  // Example: Get Attendance
  Future<List<Map<String, dynamic>>> getAttendance() async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('user_id', currentUser!.id);
    return response;
  }

  Future<void> checkIn() async {
    await _client.from('attendance').insert({
      'user_id': currentUser!.id,
      'check_in': DateTime.now().toIso8601String(),
      'status': 'present',
    });
  }

  // Get active unread announcements
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      // 1. Get IDs of announcements read by this user
      final readResponse = await _client
          .from('announcement_reads')
          .select('announcement_id')
          .eq('user_id', user.id);

      final readIds = (readResponse as List)
          .map((r) => r['announcement_id'] as String)
          .toList();

      // 2. Fetch published and due scheduled announcements
      var query = _client
          .from('announcements')
          .select()
          .or('status.eq.Published,status.eq.Scheduled')
          .order('created_at', ascending: false)
          .limit(20);

      final response = await query;
      final List<Map<String, dynamic>> rawAnnouncements =
          List<Map<String, dynamic>>.from(response);

      // Filter: Keep Published OR (Scheduled AND scheduled_at <= now)
      final allAnnouncements = rawAnnouncements.where((a) {
        // 1. Status Check
        bool isStatusValid = false;
        if (a['status'] == 'Published') {
          isStatusValid = true;
        } else if (a['status'] == 'Scheduled' && a['scheduled_at'] != null) {
          isStatusValid =
              DateTime.parse(a['scheduled_at']).isBefore(DateTime.now());
        }

        if (!isStatusValid) return false;

        // 2. Audience Check
        final String? userDepartment = user.userMetadata?['department'];
        final String audience = a['audience'] ?? 'All Staff';

        if (audience == 'All Staff') return true;
        if (userDepartment != null &&
            audience.toLowerCase() == userDepartment.toLowerCase()) return true;

        return false;
      }).toList();

      // 4. Filter out read IDs in memory (simpler and reliable)
      return allAnnouncements.where((a) => !readIds.contains(a['id'])).toList();
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  // Get all announcements with read status
  Future<List<Map<String, dynamic>>> getAllAnnouncementsWithReadStatus() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      // 1. Get IDs of announcements read by this user
      final readResponse = await _client
          .from('announcement_reads')
          .select('announcement_id')
          .eq('user_id', user.id);

      final readIds = (readResponse as List)
          .map((r) => r['announcement_id'] as String)
          .toSet();

      // 2. Fetch published and due scheduled announcements
      var query = _client
          .from('announcements')
          .select()
          .or('status.eq.Published,status.eq.Scheduled')
          .order('created_at', ascending: false)
          .limit(50); // Higher limit for history

      final response = await query;
      final List<Map<String, dynamic>> rawAnnouncements =
          List<Map<String, dynamic>>.from(response);

      // Filter and Map
      final allAnnouncements = rawAnnouncements.where((a) {
        // 1. Status Check
        bool isStatusValid = false;
        if (a['status'] == 'Published') {
          isStatusValid = true;
        } else if (a['status'] == 'Scheduled' && a['scheduled_at'] != null) {
          isStatusValid =
              DateTime.parse(a['scheduled_at']).isBefore(DateTime.now());
        }

        if (!isStatusValid) return false;

        // 2. Audience Check
        final String? userDepartment = user.userMetadata?['department'];
        final String audience = a['audience'] ?? 'All Staff';

        if (audience == 'All Staff') return true;
        if (userDepartment != null &&
            audience.toLowerCase() == userDepartment.toLowerCase()) return true;

        return false;
      }).map((a) {
        return {
          ...a,
          'is_read': readIds.contains(a['id']),
        };
      }).toList();

      return allAnnouncements;
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  // Mark announcement as read
  Future<void> markAnnouncementAsRead(String announcementId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _client.from('announcement_reads').upsert({
        'user_id': user.id,
        'announcement_id': announcementId,
        'read_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error marking announcement as read: $e');
    }
  }

  // Update task description
  Future<void> updateTaskDescription(int taskId, String description) async {
    await _client.from('tasks').update({
      'description': description,
    }).eq('id', taskId);
  }

  // Get tasks assigned to current user
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      // Fetch tasks and subtasks
      final response = await _client
          .from('tasks')
          .select(
              '*, assignee:assignee_id(full_name, department, avatar_url, gender, email, employee_id), subtasks:task_subtasks(*), attachments:task_attachments(*), comments:task_comments(*, author:user_id(full_name, avatar_url, gender, email, employee_id))')
          .eq('assignee_id', user.id)
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTask(int id) async {
    try {
      final response = await _client
          .from('tasks')
          .select(
              '*, assignee:assignee_id(full_name, department, avatar_url, gender, email, employee_id), subtasks:task_subtasks(*), attachments:task_attachments(*), comments:task_comments(*, author:user_id(full_name, avatar_url, gender, email, employee_id))')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      print('Error fetching task: $e');
      return null;
    }
  }

  // Update task status
  Future<void> updateTaskStatus(int taskId, String status, int progress) async {
    await _client.from('tasks').update({
      'status': status,
      'progress': progress,
    }).eq('id', taskId);
  }

  Future<void> updateSubtaskStatus(int subtaskId, bool completed) async {
    // 1. Update the subtask
    final subtaskOrder = await _client
        .from('task_subtasks')
        .update({'completed': completed})
        .eq('id', subtaskId)
        .select('task_id')
        .single();

    final taskId = subtaskOrder['task_id'];

    // 2. Fetch all subtasks for this task to calculate new progress
    final subtasksResponse = await _client
        .from('task_subtasks')
        .select('completed')
        .eq('task_id', taskId);

    final subtasks = subtasksResponse as List;
    if (subtasks.isEmpty) return;

    final completedCount = subtasks.where((s) => s['completed'] == true).length;
    final totalCount = subtasks.length;
    final newProgress = ((completedCount / totalCount) * 100).round();

    // 3. Update task progress
    // Also perform a check: if 100%, maybe mark as Completed?
    // For now, let's just update progress.
    await _client.from('tasks').update({
      'progress': newProgress,
      // Optional: Auto-complete if 100%?
      // 'status': newProgress == 100 ? 'Completed' : 'In Progress'
    }).eq('id', taskId);
  }

  Future<void> createTaskComment(int taskId, String text) async {
    final user = currentUser;
    if (user == null) return;
    await _client.from('task_comments').insert({
      'task_id': taskId,
      'user_id': user.id,
      'content': text,
    });
  }

  // Placeholder for file upload - requires file_picker/image_picker
  Future<void> uploadAttachment(
      int taskId, String fileName, dynamic fileBytes) async {
    // NOTE: Real implementation requires 'supabase_storage' and a File object or bytes.
    // await _client.storage.from('task-attachments').uploadBinary(fileName, fileBytes);
    // await _client.from('task_attachments').insert({...});
  }
  Future<void> completeTask(int taskId) async {
    // 1. Mark task as completed
    await _client.from('tasks').update({
      'status': 'Completed',
      'progress': 100,
    }).eq('id', taskId);

    // 2. Mark all subtasks as completed
    await _client
        .from('task_subtasks')
        .update({'completed': true}).eq('task_id', taskId);
  }
  // --- Messaging Features ---

  // Get channels the current user is a member of
  // Also fetches the last message for preview
  Future<List<Map<String, dynamic>>> getMyChannels() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      // Fetch channels the user has joined.
      // Eagerly fetch all members and their profiles to determine DM counterparts.
      final response = await _client
          .from('channels')
          .select('''
            *,
            channel_members!inner(user_id),
            members:channel_members(
              user_id,
              profiles:user_id(full_name, avatar_url, gender, email, employee_id)
            )
          ''')
          .eq('channel_members.user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching channels: $e');
      return [];
    }
  }

  // Get the profile of the other person in a DM
  Future<Map<String, dynamic>?> getOtherMemberProfile(
      String channelId, String myUserId) async {
    try {
      // Fetch channel members that are NOT me
      final response = await _client
          .from('channel_members')
          .select(
              'user_id, profiles:user_id(full_name, avatar_url, gender, email, employee_id)')
          .eq('channel_id', channelId)
          .neq('user_id', myUserId)
          .maybeSingle();

      if (response != null && response['profiles'] != null) {
        return response['profiles'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching other member: $e');
      return null;
    }
  }

  // Get last message content for a channel
  Future<String?> getLastMessageContent(String channelId) async {
    try {
      final response = await _client
          .from('messages')
          .select('content')
          .eq('channel_id', channelId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['content'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all public channels (that user might not have joined yet)
  Future<List<Map<String, dynamic>>> getPublicChannels() async {
    try {
      final response = await _client
          .from('channels')
          .select('*')
          .eq('type', 'public')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching public channels: $e');
      return [];
    }
  }

  // Get messages for a specific channel
  Future<List<Map<String, dynamic>>> getMessages(String channelId,
      {int limit = 50}) async {
    try {
      final response = await _client
          .from('messages')
          .select('*, sender:user_id(id, full_name, avatar_url, email)')
          .eq('channel_id', channelId)
          .order('created_at', ascending: false) // Get newest first
          .limit(limit);

      // Return newest first for reverse: true ListView
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Send a message
  Future<void> sendMessage(String channelId, String content) async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('messages').insert({
      'channel_id': channelId,
      'user_id': user.id,
      'content': content,
    });
  }

  // Create a new channel (Public or Private)
  Future<void> createChannel(String name, String type,
      {List<String>? initialMembers}) async {
    final user = currentUser;
    if (user == null) return;

    final response = await _client
        .from('channels')
        .insert({
          'name': name,
          'type': type,
          'created_by': user.id,
        })
        .select()
        .single();

    final channelId = response['id'];

    // Add creator as member
    await joinChannel(channelId);

    // Add initial members
    if (initialMembers != null && initialMembers.isNotEmpty) {
      await addMembersToChannel(channelId, initialMembers);
    }
  }

  // Add members to a channel
  Future<void> addMembersToChannel(
      String channelId, List<String> userIds) async {
    if (userIds.isEmpty) return;

    final toInsert = userIds
        .map((uid) => {
              'channel_id': channelId,
              'user_id': uid,
            })
        .toList();

    await _client.from('channel_members').upsert(toInsert);
  }

  // Get channel members with profiles
  Future<List<Map<String, dynamic>>> getChannelMembers(String channelId) async {
    try {
      final response = await _client
          .from('channel_members')
          .select('*, profiles:user_id(*)')
          .eq('channel_id', channelId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }

  // Join a channel
  Future<void> joinChannel(String channelId) async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('channel_members').upsert({
      'channel_id': channelId,
      'user_id': user.id,
    });
  }

  // Create or retrieve a DM channel with another user
  Future<String> getOrCreateDirectMessageChannel(String otherUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');

    // 1. Check if a DM channel already exists with these 2 users
    // This logic is tricky in SQL/Supabase without a dedicated function.
    // For MVP, we can fetch all my DM channels, then check members of each.
    // Optimisation: Create a unique constraint on members? Hard for sets.

    // Client-side filtering for MVP:
    // Get all my DM channels
    final myChannels = await _client
        .from('channel_members')
        .select('channel_id, channels!inner(type)')
        .eq('user_id', user.id)
        .eq('channels.type', 'dm');

    for (var item in myChannels) {
      final channelId = item['channel_id'] as String;
      // Check if other user is also member
      final memberCheck = await _client
          .from('channel_members')
          .select('user_id')
          .eq('channel_id', channelId)
          .eq('user_id', otherUserId)
          .maybeSingle();

      if (memberCheck != null) {
        return channelId; // Found existing DM
      }
    }

    // 2. Create new DM channel if not found
    final channelRes = await _client
        .from('channels')
        .insert({
          'name': 'dm', // Generic name, UI will display other user's name
          'type': 'dm',
          'created_by': user.id,
        })
        .select()
        .single();

    final newChannelId = channelRes['id'];

    // Add both users
    await _client.from('channel_members').insert([
      {'channel_id': newChannelId, 'user_id': user.id},
      {'channel_id': newChannelId, 'user_id': otherUserId},
    ]);

    return newChannelId;
  }
}
