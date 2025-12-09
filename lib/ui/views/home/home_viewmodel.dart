import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/supabase_service.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';

class KpiCard {
  KpiCard({required this.label, required this.value, required this.trend});

  final String label;
  final String value;
  final String trend;
}

class ChatMessage {
  ChatMessage({
    required this.sender,
    required this.time,
    required this.text,
    required this.isMe,
  });

  final String sender;
  final String time;
  final String text;
  final bool isMe;
}

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final String type; // 'info', 'alert', 'success'
  final bool isRead;
}

class HomeViewModel extends IndexTrackingViewModel {
  final _supabaseService = locator<SupabaseService>();
  Timer? _timer;

  // Profile data
  String? userName;
  String? userRole;
  String? userDepartment;
  String? userStatus;
  String? userGender;
  String? avatarUrl;

  List<Announcement> announcements = [];

  List<Task> tasks = []; // Real tasks

  HomeViewModel() {
    _loadUserProfile();
    _fetchAnnouncements();
    _fetchTasks();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _fetchAnnouncements();
      _fetchTasks();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    await Future.wait([
      _fetchAnnouncements(),
      _loadUserProfile(),
      _fetchTasks(),
    ]);
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final data = await _supabaseService.getAnnouncements();
      announcements = data.map((item) {
        final createdAt = DateTime.parse(item['created_at']);
        final isPinned = item['pinned'] == true;

        return Announcement(
          id: item['id'],
          title: item['title'] ?? 'Announcement',
          message: item['content'] ?? '',
          time: _getTimeAgo(createdAt),
          type: isPinned ? 'alert' : 'info',
          isRead: false,
        );
      }).toList();
      rebuildUi();
    } catch (e) {
      print('Error loading announcements: $e');
    }
  }

  Future<List<Announcement>> fetchAllAnnouncements() async {
    final data = await _supabaseService.getAllAnnouncementsWithReadStatus();
    return data.map((item) {
      final createdAt = DateTime.parse(item['created_at']);
      final isPinned = item['pinned'] == true;

      return Announcement(
        id: item['id'],
        title: item['title'] ?? 'Announcement',
        message: item['content'] ?? '',
        time: _getTimeAgo(createdAt),
        type: isPinned ? 'alert' : 'info',
        isRead: item['is_read'] ?? false,
      );
    }).toList();
  }

  String _getTimeAgo(DateTime dateTime) {
    // ... existing implementation
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> markAsRead(Announcement announcement) async {
    // 1. Optimistic update
    announcements.remove(announcement);
    rebuildUi();

    // 2. Call API
    await _supabaseService.markAnnouncementAsRead(announcement.id);
  }

  Future<void> _fetchTasks() async {
    final data = await _supabaseService.getTasks();
    tasks = data.map((e) => Task.fromMap(e)).toList();
    rebuildUi();
  }

  Future<void> _loadUserProfile() async {
    setBusy(true);
    try {
      final profile = await _supabaseService.getUserProfile();
      if (profile != null) {
        userName = profile['full_name'] ?? 'User';
        userRole = profile['role'];
        userDepartment = profile['department'];
        userStatus = profile['status'] ?? 'active';
        userGender = profile['gender'];

        // Generate DiceBear avatar URL
        final seed =
            profile['employee_id'] ?? profile['email'] ?? userName ?? 'default';
        avatarUrl = _supabaseService.getAvatarUrl(userGender, seed);

        rebuildUi();
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setBusy(false);
    }
  }

  int get currentTab => currentIndex;

  final kpiCards = <KpiCard>[
    KpiCard(label: 'Task Score', value: '92%', trend: '+5%'),
    KpiCard(label: 'Attendance', value: '88%', trend: '+2%'),
    KpiCard(label: 'Compliance', value: '96%', trend: '+1%'),
    KpiCard(label: 'Feedback', value: '4.6', trend: '+0.3'),
  ];

  // Use real tasks instead of mock
  List<Task> get todayTasks => tasks;

  final chatMessages = <ChatMessage>[
    ChatMessage(
      sender: 'Deborah',
      time: '09:14',
      text: 'Reminder: maintenance Sat 2AM',
      isMe: false,
    ),
    ChatMessage(
      sender: 'You',
      time: '09:16',
      text: 'Copy, will notify ops.',
      isMe: true,
    ),
    ChatMessage(
      sender: 'Darlington',
      time: '09:20',
      text: 'Drafting announcement now.',
      isMe: false,
    ),
  ];

  void setTab(int index) {
    setIndex(index);
  }
}
