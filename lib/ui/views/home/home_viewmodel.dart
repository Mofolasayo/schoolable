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

/// Aura Performance Score Data (Auto-calculated with Department KPIs)
class AuraData {
  AuraData({
    required this.auraScore,
    required this.grade,
    required this.qgpa,
    required this.pillars,
    this.quarterStart,
    this.lastUpdated,
    this.department,
    this.departmentProfile,
    this.automationRate,
    this.calculatedAt,
  });

  final double auraScore;
  final String grade;
  final double qgpa;
  final Map<String, PillarDetail> pillars;
  final String? quarterStart;
  final String? lastUpdated;
  final String? department;
  final String? departmentProfile; // e.g., "Engineering", "Sales"
  final double? automationRate; // e.g., 80.0 for 80% automated
  final String? calculatedAt;

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
      department: map['department']?.toString(),
      departmentProfile: map['departmentProfile']?.toString(),
      automationRate: (map['automationRate'] as num?)?.toDouble(),
      calculatedAt: map['calculatedAt']?.toString(),
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
    this.subMetrics = const [],
  });

  final String name;
  final double score;
  final double weight;
  final double contribution;
  final String dataSource;
  final List<SubMetricDetail> subMetrics;

  factory PillarDetail.fromMap(Map<String, dynamic> map) {
    final subMetricsList = <SubMetricDetail>[];
    final rawSubMetrics = map['subMetrics'] as List<dynamic>? ?? [];
    for (final sm in rawSubMetrics) {
      if (sm is Map) {
        subMetricsList
            .add(SubMetricDetail.fromMap(Map<String, dynamic>.from(sm)));
      }
    }

    return PillarDetail(
      name: map['name']?.toString() ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      contribution: (map['contribution'] as num?)?.toDouble() ?? 0.0,
      dataSource: map['dataSource']?.toString() ?? 'auto',
      subMetrics: subMetricsList,
    );
  }
}

/// Sub-metric detail for enhanced Aura display
class SubMetricDetail {
  SubMetricDetail({
    required this.key,
    required this.displayName,
    required this.score,
    required this.source,
    required this.weightInPillar,
    required this.contribution,
  });

  final String key;
  final String displayName;
  final double score;
  final String source;
  final double weightInPillar;
  final double contribution;

  factory SubMetricDetail.fromMap(Map<String, dynamic> map) {
    return SubMetricDetail(
      key: map['key']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      source: map['source']?.toString() ?? 'auto',
      weightInPillar: (map['weightInPillar'] as num?)?.toDouble() ?? 20.0,
      contribution: (map['contribution'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Team Score Data - aggregated team KPI achievement
class TeamScoreData {
  TeamScoreData({
    required this.teamName,
    required this.department,
    required this.quarter,
    required this.year,
    required this.kpiScore,
    required this.overallScore,
    required this.grade,
    this.aiSummary,
  });

  final String teamName;
  final String department;
  final String quarter;
  final int year;
  final double kpiScore;
  final double overallScore;
  final String grade;
  final String? aiSummary;

  factory TeamScoreData.fromMap(Map<String, dynamic> map) {
    return TeamScoreData(
      teamName: map['teamName']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      quarter: map['quarter']?.toString() ?? '',
      year: (map['year'] as num?)?.toInt() ?? 2026,
      kpiScore: (map['kpiAchievementScore'] as num?)?.toDouble() ?? 0.0,
      overallScore: (map['overallTeamScore'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade']?.toString() ?? 'N/A',
      aiSummary: map['aiSummary']?.toString(),
    );
  }
}

/// Team AI Insight Data - weekly AI-generated insights
class TeamInsightData {
  TeamInsightData({
    required this.weekNumber,
    required this.quarter,
    required this.year,
    required this.kpiScore,
    required this.summary,
    this.topPerforming = const [],
    this.needsAttention = const [],
    this.recommendations = const [],
    this.riskAlerts = const [],
  });

  final int weekNumber;
  final String quarter;
  final int year;
  final double kpiScore;
  final String summary;
  final List<String> topPerforming;
  final List<String> needsAttention;
  final List<String> recommendations;
  final List<String> riskAlerts;

  factory TeamInsightData.fromMap(Map<String, dynamic> map) {
    // Parse nested insights
    final insights = map['insights'] as Map<String, dynamic>? ?? {};
    final recs = map['recommendations'] as Map<String, dynamic>? ?? {};
    final risks = map['riskAlerts'] as Map<String, dynamic>? ?? {};

    List<String> toStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return TeamInsightData(
      weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 0,
      quarter: map['quarter']?.toString() ?? '',
      year: (map['year'] as num?)?.toInt() ?? 2026,
      kpiScore: (map['kpiScore'] as num?)?.toDouble() ?? 0.0,
      summary: map['summary']?.toString() ?? 'No insights available',
      topPerforming: toStringList(insights['topPerforming']),
      needsAttention: toStringList(insights['needsAttention']),
      recommendations: toStringList(recs['items']),
      riskAlerts: toStringList(risks['items']),
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

  // Team Score & AI Insights
  TeamScoreData? teamScore;
  TeamInsightData? teamInsight;
  bool isLoadingTeamData = false;

  // Compliance Data
  List<ComplianceItem> complianceItems = [];

  // Peer Helpfulness Rating Status
  bool hasPendingPeerRatings = false;
  int pendingPeerRatingsCount = 0;
  String? peerRatingPromptMessage;

  HomeViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCachedData();

    _loadUserProfile();
    _fetchAnnouncements();
    _fetchTasks();
    _fetchAuraData(); // Fetch Aura score
    _fetchTeamData(); // Fetch Team Score & AI Insights
    _fetchComplianceItems(); // Fetch Compliance items
    _fetchPeerHelpfulnessStatus(); // Check if peer ratings needed

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

  /// Fetch Auto-calculated Aura performance data from backend
  /// Uses department-specific KPIs for real-time calculation
  Future<void> _fetchAuraData() async {
    isLoadingAura = true;
    rebuildUi();

    try {
      // Use auto-aura endpoint for real-time calculation with department KPIs
      final data = await _backendService.getAutoAuraDashboard();
      if (data != null) {
        auraData = AuraData.fromMap(data);
        print(
            '✅ Auto-Aura loaded: ${auraData?.auraScore} (${auraData?.departmentProfile})');
      } else {
        // Fallback to standard endpoint if auto fails
        final fallbackData = await _backendService.getMyAuraDashboard();
        if (fallbackData != null) {
          auraData = AuraData.fromMap(fallbackData);
        } else {
          _setDemoAuraData();
        }
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

  /// Fetch Team Score and AI Insights from backend
  Future<void> _fetchTeamData() async {
    isLoadingTeamData = true;
    rebuildUi();

    try {
      // Fetch team score
      final scoreData = await _backendService.getMyTeamScore();
      if (scoreData != null && scoreData['overallTeamScore'] != null) {
        teamScore = TeamScoreData.fromMap(scoreData);
        print(
            '✅ Team Score loaded: ${teamScore?.overallScore} (${teamScore?.grade})');
      }

      // Fetch latest team insight
      final insightData = await _backendService.getTeamInsight();
      if (insightData != null && insightData['kpiScore'] != null) {
        teamInsight = TeamInsightData.fromMap(insightData);
        print('✅ Team Insight loaded: Week ${teamInsight?.weekNumber}');
      }
    } catch (e) {
      print('Error fetching team data: $e');
      // Keep null on error - UI will show fallback
    } finally {
      isLoadingTeamData = false;
      rebuildUi();
    }
  }

  Future<void> _fetchComplianceItems() async {
    try {
      final items = await _backendService.getMyComplianceItems();

      complianceItems = items.map((item) {
        final deadlineStr = item['deadline'] as String?;
        DateTime deadline;

        if (deadlineStr != null) {
          try {
            deadline = DateTime.parse(deadlineStr);
          } catch (_) {
            deadline = DateTime.now().add(const Duration(days: 7));
          }
        } else {
          deadline = DateTime.now().add(const Duration(days: 7));
        }

        return ComplianceItem(
          id: item['id']?.toString() ?? item['policyId']?.toString() ?? '',
          title: item['title'] ?? 'Untitled Policy',
          description: item['description'] ?? '',
          deadline: deadline,
          type: item['type'] ?? 'policy',
          status: item['status'] ?? 'pending',
        );
      }).toList();

      rebuildUi();
    } catch (e) {
      print('Error fetching compliance items: $e');
      // Keep empty list on error
      complianceItems = [];
      rebuildUi();
    }
  }

  /// Fetch peer helpfulness rating status
  Future<void> _fetchPeerHelpfulnessStatus() async {
    try {
      final result = await _backendService.getPeerHelpfulnessStatus();
      final pendingRatings = result['pendingRatings'] as int? ?? 0;
      final isComplete = result['isComplete'] as bool? ?? true;

      hasPendingPeerRatings = !isComplete && pendingRatings > 0;
      pendingPeerRatingsCount = pendingRatings;
      peerRatingPromptMessage = result['promptMessage'] as String?;

      rebuildUi();
    } catch (e) {
      print('Error fetching peer helpfulness status: $e');
      hasPendingPeerRatings = false;
      pendingPeerRatingsCount = 0;
    }
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

    // Team Score: from Team KPI data (replaces QGPA)
    // Shows team's KPI achievement score with grade
    final teamScoreValue =
        teamScore != null ? '${teamScore!.overallScore.round()}%' : '--';
    final teamGrade = teamScore?.grade ?? '';
    final teamScoreDisplay =
        teamScore != null ? '$teamScoreValue ($teamGrade)' : 'Team Score';

    return [
      KpiCard(label: 'Task Score', value: taskScoreValue, trend: '--'),
      KpiCard(label: 'Attendance', value: attendanceValue, trend: '--'),
      KpiCard(label: 'Compliance', value: complianceValue, trend: '--'),
      KpiCard(label: 'Team Score', value: teamScoreDisplay, trend: teamGrade),
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
