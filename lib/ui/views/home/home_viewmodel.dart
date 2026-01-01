import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/services/websocket_service.dart';
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
  final String type;
  final bool isRead;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': message,
        'time': time,
        'type': type,
        'is_read': isRead,
      };
}

class ComplianceItem {
  ComplianceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.type,
    this.status = 'pending',
  });

  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String type; // 'policy', 'upload', 'training'
  String status; // 'pending', 'complied'
}

/// Aura Performance Score Data
class AuraData {
  AuraData({
    required this.auraScore,
    required this.grade,
    required this.qgpa,
    required this.pillars,
    this.quarterStart,
    this.lastUpdated,
  });

  final double auraScore;
  final String grade;
  final double qgpa;
  final Map<String, PillarDetail> pillars;
  final String? quarterStart;
  final String? lastUpdated;

  factory AuraData.fromMap(Map<String, dynamic> map) {
    final pillarsMap = map['pillars'] as Map<String, dynamic>? ?? {};
    final pillars = <String, PillarDetail>{};

    pillarsMap.forEach((key, value) {
      if (value is Map) {
        pillars[key] = PillarDetail.fromMap(Map<String, dynamic>.from(value));
      }
    });

    return AuraData(
      auraScore: (map['auraScore'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade']?.toString() ?? 'N/A',
      qgpa: (map['qgpa'] as num?)?.toDouble() ?? 0.0,
      pillars: pillars,
      quarterStart: map['quarterStart']?.toString(),
      lastUpdated: map['lastUpdated']?.toString(),
    );
  }
}

class PillarDetail {
  PillarDetail({
    required this.name,
    required this.score,
    required this.weight,
    required this.contribution,
    required this.dataSource,
  });

  final String name;
  final double score;
  final double weight;
  final double contribution;
  final String dataSource;

  factory PillarDetail.fromMap(Map<String, dynamic> map) {
    return PillarDetail(
      name: map['name']?.toString() ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      contribution: (map['contribution'] as num?)?.toDouble() ?? 0.0,
      dataSource: map['dataSource']?.toString() ?? 'auto',
    );
  }
}

class HomeViewModel extends IndexTrackingViewModel {
  final _backendService = locator<BackendApiService>();
  final _cacheService = locator<CacheService>();
  final _wsService = locator<WebSocketService>();
  Timer? _timer;
  StreamSubscription? _taskSubscription;

  String? userName;
  String? userRole;
  String? userDepartment;
  String? userStatus;
  String? userGender;
  String? avatarUrl;

  List<Announcement> announcements = [];
  List<Task> tasks = [];

  // Aura Performance Data
  AuraData? auraData;
  bool isLoadingAura = false;

  // Compliance Data
  List<ComplianceItem> complianceItems = [];

  HomeViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCachedData();

    _loadUserProfile();
    _fetchAnnouncements();
    _fetchTasks();
    _fetchAuraData(); // Fetch Aura score
    _fetchComplianceItems(); // Fetch Compliance items

    _connectWebSocket();

    _startPolling();
  }

  Future<void> _connectWebSocket() async {
    try {
      // Get the auth token
      final token = await _backendService.getCurrentToken();
      if (token == null) {
        print('⚠️ No token available for WebSocket connection');
        return;
      }

      await _wsService.connect(token);

      // Subscribe to notifications for task/announcement updates
      _wsService.subscribeToNotifications(onNotification: (message) {
        print('📥 Received notification via WebSocket: ${message.type}');
        // Check notification type and refresh accordingly
        final notificationType =
            message.data['notificationType']?.toString() ?? '';
        if (notificationType.contains('task')) {
          _fetchTasks();
        } else if (notificationType.contains('announcement')) {
          _fetchAnnouncements();
        } else {
          // Refresh both for general notifications
          _fetchTasks();
          _fetchAnnouncements();
        }
      });
    } catch (e) {
      print('⚠️ WebSocket connection failed: $e');
    }
  }

  Future<void> _loadCachedData() async {
    final cachedProfile = await _cacheService.getCachedProfile();
    if (cachedProfile != null) {
      _applyProfileData(cachedProfile);
    }

    final cachedAnnouncements = await _cacheService.getCachedAnnouncements();
    if (cachedAnnouncements != null) {
      announcements =
          _parseAnnouncements(cachedAnnouncements.cast<Map<String, dynamic>>());
      rebuildUi();
    }

    final cachedTasks = await _cacheService.getCachedTasks();
    if (cachedTasks != null) {
      tasks = cachedTasks
          .cast<Map<String, dynamic>>()
          .map((e) => Task.fromMap(e))
          .toList();
      rebuildUi();
    }
  }

  void _startPolling() {
    // Reduce polling frequency since WebSocket handles real-time updates
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchAnnouncements();
      _fetchTasks();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskSubscription?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    await Future.wait([
      _fetchAnnouncements(),
      _loadUserProfile(),
      _fetchTasks(),
      _fetchAuraData(),
    ]);
  }

  /// Fetch Aura performance data from backend
  Future<void> _fetchAuraData() async {
    isLoadingAura = true;
    rebuildUi();

    try {
      final data = await _backendService.getMyAuraDashboard();
      if (data != null) {
        auraData = AuraData.fromMap(data);
      } else {
        // Use demo data if API returns null
        _setDemoAuraData();
      }
    } catch (e) {
      print('Error fetching Aura data: $e');
      // Use demo data on any error
      _setDemoAuraData();
    } finally {
      isLoadingAura = false;
      rebuildUi();
    }
  }

  Future<void> _fetchComplianceItems() async {
    // Mock data for now
    complianceItems = [
      ComplianceItem(
        id: '1',
        title: 'New Workplace Policy',
        description:
            'Please review and acknowledge the updated workplace anti-harassment policy. This is mandatory for all employees.',
        deadline: DateTime.now().add(const Duration(days: 3)),
        type: 'policy',
      ),
      ComplianceItem(
        id: '2',
        title: 'Submit ID Document',
        description:
            'Upload a clear copy of your government-issued ID for our improved security records.',
        deadline: DateTime.now().add(const Duration(days: 7)),
        type: 'upload',
      ),
    ];
    rebuildUi();
  }

  /// Set placeholder Aura data for display when API is unavailable
  /// Shows 0 score to avoid misleading users
  /// 4 pillars × 25% each
  void _setDemoAuraData() {
    auraData = AuraData(
      auraScore: 0.0,
      grade: 'N/A',
      qgpa: 0.0,
      pillars: {
        'technical': PillarDetail(
          name: 'Technical Competence',
          score: 0.0,
          weight: 25.0,
          contribution: 0.0,
          dataSource: 'auto',
        ),
        'behavioral': PillarDetail(
          name: 'Behavioral Competence',
          score: 0.0,
          weight: 25.0,
          contribution: 0.0,
          dataSource: 'mixed',
        ),
        'cultureFit': PillarDetail(
          name: 'Culture Fit',
          score: 0.0,
          weight: 25.0,
          contribution: 0.0,
          dataSource: 'mixed',
        ),
        'growthLearning': PillarDetail(
          name: 'Growth & Learning',
          score: 0.0,
          weight: 25.0,
          contribution: 0.0,
          dataSource: 'auto',
        ),
      },
      quarterStart: 'Awaiting data...',
    );
  }

  /// Apply profile data to view model properties
  void _applyProfileData(Map<String, dynamic> profile) {
    userName = profile['full_name'] ?? 'User';
    userRole =
        profile['job_title'] ?? profile['role']; // Prefer job_title for display
    userDepartment = profile['department'];
    userStatus = profile['status'] ?? 'active';
    userGender = profile['gender'];
    avatarUrl = profile['avatar_url'];
    rebuildUi();
  }

  /// Parse raw announcement data into Announcement objects
  List<Announcement> _parseAnnouncements(List<Map<String, dynamic>> data) {
    return data.map((item) {
      final createdAtStr = item['created_at'];
      final createdAt = createdAtStr != null
          ? DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now()
          : DateTime.now();
      final isPinned = item['pinned'] == true;

      return Announcement(
        id: item['id']?.toString() ?? '',
        title: item['title'] ?? 'Announcement',
        message: item['content'] ?? '',
        time: _getTimeAgo(createdAt),
        type: isPinned ? 'alert' : 'info',
        isRead: item['is_read'] ?? false,
      );
    }).toList();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      // Fetch from API
      final data = await _backendService.getUnreadAnnouncements();

      // Cache the raw data for future use
      await _cacheService.cacheAnnouncements(data);

      // Parse and update UI
      announcements = _parseAnnouncements(data);
      rebuildUi();
    } catch (e) {
      print('Error loading announcements: $e');
    }
  }

  Future<List<Announcement>> fetchAllAnnouncements() async {
    // Use BackendApiService for all announcements with read status
    final data = await _backendService.getAnnouncements();
    return _parseAnnouncements(data);
  }

  String _getTimeAgo(DateTime dateTime) {
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

    // 2. Call Backend API
    await _backendService.markAnnouncementAsRead(announcement.id);

    // 3. Update cache
    await _cacheService.cacheAnnouncements(
      announcements.map((a) => a.toMap()).toList(),
    );
  }

  Future<void> _fetchTasks() async {
    try {
      // Fetch from API
      final data = await _backendService.getTasks();

      // Cache the raw data
      await _cacheService.cacheTasks(data);

      // Parse and update UI
      tasks = data.map((e) => Task.fromMap(e)).toList();
      rebuildUi();
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    setBusy(true);
    try {
      // Fetch from API
      final profile = await _backendService.getUserProfile(forceRefresh: true);
      if (profile != null) {
        // Cache the profile
        await _cacheService.cacheProfile(profile);

        // Apply to UI
        _applyProfileData(profile);
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setBusy(false);
    }
  }

  int get currentTab => currentIndex;

  /// Dynamic KPI cards based on real data
  List<KpiCard> get kpiCards {
    // Task Score: from Technical pillar or task completion rate
    final technicalScore = auraData?.pillars['technical']?.score ?? 0.0;
    final taskScoreValue = technicalScore > 0
        ? '${technicalScore.round()}%'
        : totalTaskCount > 0
            ? '${(completedTaskCount / totalTaskCount * 100).round()}%'
            : '0%';

    // Attendance: from Culture Fit pillar (includes punctuality)
    final cultureFitScore = auraData?.pillars['cultureFit']?.score ?? 0.0;
    final attendanceValue =
        cultureFitScore > 0 ? '${cultureFitScore.round()}%' : '0%';

    // Compliance: from Behavioral pillar
    final behavioralScore = auraData?.pillars['behavioral']?.score ?? 0.0;
    final complianceValue =
        behavioralScore > 0 ? '${behavioralScore.round()}%' : '0%';

    // QGPA: from Aura data
    final qgpaValue = auraData?.qgpa ?? 0.0;
    final qgpaDisplay = qgpaValue > 0 ? qgpaValue.toStringAsFixed(2) : '0.00';

    return [
      KpiCard(label: 'Task Score', value: taskScoreValue, trend: '--'),
      KpiCard(label: 'Attendance', value: attendanceValue, trend: '--'),
      KpiCard(label: 'Compliance', value: complianceValue, trend: '--'),
      KpiCard(label: 'QGPA', value: qgpaDisplay, trend: '--'),
    ];
  }

  // Use real tasks instead of mock
  List<Task> get todayTasks => tasks;

  // Task distribution computed properties
  int get completedTaskCount =>
      tasks.where((t) => t.status.toLowerCase() == 'completed').length;

  int get pendingTaskCount => tasks
      .where((t) =>
          t.status.toLowerCase() == 'pending' ||
          t.status.toLowerCase() == 'in progress')
      .length;

  int get overdueTaskCount =>
      tasks.where((t) => t.due.toLowerCase() == 'overdue').length;

  int get totalTaskCount => tasks.length;

  /// Returns flex values for the task distribution bar chart
  /// Returns [completedFlex, pendingFlex, overdueFlex]
  List<int> get taskDistributionFlex {
    if (totalTaskCount == 0) return [1, 0, 0]; // Avoid division by zero

    final completed = (completedTaskCount / totalTaskCount * 100).round();
    final pending = (pendingTaskCount / totalTaskCount * 100).round();
    final overdue = (overdueTaskCount / totalTaskCount * 100).round();

    // Ensure at least 1 flex for non-zero counts so they're visible
    return [
      completed > 0 ? (completed < 5 ? 5 : completed) : 0,
      pending > 0 ? (pending < 5 ? 5 : pending) : 0,
      overdue > 0 ? (overdue < 5 ? 5 : overdue) : 0,
    ];
  }

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
