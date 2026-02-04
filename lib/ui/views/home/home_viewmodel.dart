import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/services/websocket_service.dart';
import 'package:schoolable/ui/views/tasks/task_model.dart';
import 'package:schoolable/services/logging_service.dart';

class KpiCard {
  KpiCard({required this.label, required this.value, required this.trend});

  final String label;
  final String value;
  final String trend;
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
    this.policyFileUrl,
    this.policyFileName,
  });

  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String type; // 'policy', 'upload', 'training'
  String status; // 'pending', 'submitted', 'approved', 'rejected'
  final String? policyFileUrl;
  final String? policyFileName;
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
    this.scoreChange, // Daily score change from previous day
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
  final double? scoreChange; // Change from previous day (e.g., +2.5 or -1.3)

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
      scoreChange: (map['scoreChange'] as num?)?.toDouble(),
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
    this.generationStatus,
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
  final String? generationStatus;

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
      generationStatus: map['generationStatus']?.toString(),
    );
  }
}

/// Individual KPI data - KPIs set by team lead for an employee
class IndividualKpi {
  IndividualKpi({
    required this.id,
    required this.name,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.targetUnit,
    required this.weight,
    required this.quarter,
    required this.year,
    required this.achievementPercentage,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? description;
  final double targetValue;
  final double currentValue;
  final String? targetUnit;
  final int weight;
  final String quarter;
  final int year;
  final double achievementPercentage;
  final bool isActive;

  factory IndividualKpi.fromMap(Map<String, dynamic> map) {
    return IndividualKpi(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed KPI',
      description: map['description']?.toString(),
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0,
      currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
      targetUnit: map['targetUnit']?.toString(),
      weight: (map['weight'] as num?)?.toInt() ?? 0,
      quarter: map['quarter']?.toString() ?? 'Q1',
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      achievementPercentage:
          (map['achievementPercentage'] as num?)?.toDouble() ?? 0,
      isActive: map['isActive'] == true,
    );
  }
}

class HomeViewModel extends IndexTrackingViewModel {
  final _backendService = locator<BackendApiService>();
  final _cacheService = locator<CacheService>();
  final _wsService = locator<WebSocketService>();
  Timer? _timer;
  Timer? _taskDebounce;
  Timer? _auraDebounce;
  Timer? _announcementDebounce;
  Timer? _complianceDebounce;
  MessageCallback? _notificationHandler;

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
  bool auraLoadFailed = false;

  // Team Score & AI Insights
  TeamScoreData? teamScore;
  TeamInsightData? teamInsight;
  bool isLoadingTeamData = false;

  // Individual KPIs - set by team lead
  List<IndividualKpi> myKpis = [];
  double myKpiAverageAchievement = 0;
  int myKpiTotalWeight = 0;
  bool isLoadingMyKpis = false;

  // Compliance Data
  List<ComplianceItem> complianceItems = [];

  // Peer Helpfulness Rating Status
  bool hasPendingPeerRatings = false;
  int pendingPeerRatingsCount = 0;
  String? peerRatingPromptMessage;

  // Task Quality Rating Status
  bool hasPendingTaskRatings = false;
  int pendingTaskRatingsCount = 0;
  List<Map<String, dynamic>> pendingTaskRatings = [];

  HomeViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCachedData();

    _loadUserProfile();
    _fetchAnnouncements();
    _fetchTasks();
    _fetchAuraData(); // Fetch Aura score
    loadTeamData(); // Fetch Team Score & AI Insights (public for refresh)
    fetchMyKpis(); // Fetch individual KPIs
    _fetchComplianceItems(); // Fetch Compliance items
    _fetchPeerHelpfulnessStatus(); // Check if peer ratings needed
    _fetchTaskRatingStatus(); // Check if task ratings needed

    _connectWebSocket();
    _startPolling();
  }

  Future<void> _connectWebSocket() async {
    try {
      final token = await _backendService.getCurrentToken();
      if (token == null) {
        AppLogger.log('⚠️ No token available for WebSocket connection');
        return;
      }

      await _wsService.connect(token);

      _notificationHandler ??= (message) {
        AppLogger.log('📥 Received notification via WebSocket: ${message.type}');
        final notificationType =
            message.data['notificationType']?.toString() ?? '';
        if (notificationType.contains('task')) {
          _fetchTasksDebounced();
          _fetchAuraDebounced();
        } else if (notificationType.contains('announcement')) {
          _fetchAnnouncementsDebounced();
        } else if (notificationType.contains('compliance')) {
          _fetchComplianceDebounced();
        } else if (notificationType.contains('attendance')) {
          _fetchAuraDebounced();
        } else {
          _fetchTasksDebounced();
          _fetchAnnouncementsDebounced();
          _fetchAuraDebounced();
          _fetchComplianceDebounced();
        }
      };

      _wsService.subscribeToNotifications(
        onNotification: _notificationHandler!,
      );
    } catch (e) {
      AppLogger.log('⚠️ WebSocket connection failed: $e');
    }
  }

  void _fetchTasksDebounced() {
    _taskDebounce?.cancel();
    _taskDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchTasks();
    });
  }

  void _fetchAuraDebounced() {
    _auraDebounce?.cancel();
    _auraDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAuraData();
    });
  }

  void _fetchAnnouncementsDebounced() {
    _announcementDebounce?.cancel();
    _announcementDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAnnouncements();
    });
  }

  void _fetchComplianceDebounced() {
    _complianceDebounce?.cancel();
    _complianceDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchComplianceItems();
    });
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
    // Light polling as a fallback alongside WebSocket updates.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchAnnouncements();
      _fetchTasks();
      _fetchComplianceItems();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskDebounce?.cancel();
    _auraDebounce?.cancel();
    _announcementDebounce?.cancel();
    _complianceDebounce?.cancel();
    if (_notificationHandler != null) {
      _wsService.unsubscribeFromNotifications(_notificationHandler!);
      _notificationHandler = null;
    }
    super.dispose();
  }

  Future<void> refresh() async {
    await Future.wait([
      _fetchAnnouncements(),
      _loadUserProfile(),
      _fetchTasks(),
      _fetchAuraData(),
      loadTeamData(),
      _fetchComplianceItems(),
    ]);
  }

  Future<void> refreshCompliance() async {
    await _fetchComplianceItems();
  }

  /// Fetch Auto-calculated Aura performance data from backend
  /// Uses department-specific KPIs for real-time calculation
  Future<void> _fetchAuraData() async {
    if (auraData == null) {
      isLoadingAura = true;
      rebuildUi();
    }

    auraLoadFailed = false;
    try {
      // Use auto-aura endpoint for real-time calculation with department KPIs
      final data = await _backendService.getAutoAuraDashboard();
      if (data != null) {
        auraData = AuraData.fromMap(data);
        AppLogger.log(
            '✅ Auto-Aura loaded: ${auraData?.auraScore} (${auraData?.departmentProfile})');
      } else {
        // Fallback to standard endpoint if auto fails
        final fallbackData = await _backendService.getMyAuraDashboard();
        if (fallbackData != null) {
          auraData = AuraData.fromMap(fallbackData);
        } else {
          auraData = null;
          auraLoadFailed = true;
        }
      }
    } catch (e) {
      AppLogger.log('Error fetching Aura data: $e');
      auraData = null;
      auraLoadFailed = true;
    } finally {
      isLoadingAura = false;
      rebuildUi();
    }
  }

  /// Fetch Team Score and AI Insights from backend
  Future<void> loadTeamData() async {
    if (teamScore == null) {
      isLoadingTeamData = true;
      rebuildUi();
    }

    try {
      // Fetch team score
      final scoreData = await _backendService.getMyTeamScore();
      if (scoreData != null && scoreData['overallTeamScore'] != null) {
        teamScore = TeamScoreData.fromMap(scoreData);
        AppLogger.log(
            '✅ Team Score loaded: ${teamScore?.overallScore} (${teamScore?.grade})');
      }

      // Fetch latest team insight
      final insightData = await _backendService.getTeamInsight();
      if (insightData != null && insightData['kpiScore'] != null) {
        teamInsight = TeamInsightData.fromMap(insightData);
        AppLogger.log('✅ Team Insight loaded: Week ${teamInsight?.weekNumber}');
      }
    } catch (e) {
      AppLogger.log('Error fetching team data: $e');
      // Keep null on error - UI will show fallback
    } finally {
      isLoadingTeamData = false;
      rebuildUi();
    }
  }

  /// Fetch individual KPIs set by team lead for this employee
  Future<void> fetchMyKpis() async {
    isLoadingMyKpis = true;
    rebuildUi();

    try {
      final response = await _backendService.getMyIndividualKpis();
      if (response != null) {
        final kpisList = response['kpis'] as List<dynamic>? ?? [];
        myKpis = kpisList
            .map((k) => IndividualKpi.fromMap(k as Map<String, dynamic>))
            .toList();
        myKpiAverageAchievement =
            (response['averageAchievement'] as num?)?.toDouble() ?? 0;
        myKpiTotalWeight = (response['totalWeight'] as num?)?.toInt() ?? 0;
        AppLogger.log(
            '✅ Individual KPIs loaded: ${myKpis.length} KPIs, avg: $myKpiAverageAchievement%');
      }
    } catch (e) {
      AppLogger.log('Error fetching individual KPIs: $e');
      myKpis = [];
    } finally {
      isLoadingMyKpis = false;
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
          policyFileUrl: item['fileUrl']?.toString() ??
              item['policyFileUrl']?.toString(),
          policyFileName: item['fileName']?.toString() ??
              item['policyFileName']?.toString(),
        );
      }).toList();

      rebuildUi();
    } catch (e) {
      AppLogger.log('Error fetching compliance items: $e');
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
      AppLogger.log('Error fetching peer helpfulness status: $e');
      hasPendingPeerRatings = false;
      pendingPeerRatingsCount = 0;
    }
  }

  /// Fetch task quality rating status
  Future<void> _fetchTaskRatingStatus() async {
    try {
      final result = await _backendService.getTasksPendingRating();
      final ratings = result['pendingRatings'] as List<dynamic>? ?? [];

      pendingTaskRatings =
          ratings.map((r) => Map<String, dynamic>.from(r)).toList();
      pendingTaskRatingsCount = ratings.length;
      hasPendingTaskRatings = pendingTaskRatingsCount > 0;

      rebuildUi();
    } catch (e) {
      AppLogger.log('Error fetching task rating status: $e');
      hasPendingTaskRatings = false;
      pendingTaskRatingsCount = 0;
      pendingTaskRatings = [];
    }
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
      AppLogger.log('Error loading announcements: $e');
    }
  }

  Future<List<Announcement>> fetchAllAnnouncements() async {
    // Fetch regular announcements
    final data = await _backendService.getAnnouncements();
    final announcements = _parseAnnouncements(data);

    // Also fetch notification history (includes smart reminders)
    try {
      final notificationsData = await _backendService.getNotifications();
      final notifications =
          notificationsData['notifications'] as List<dynamic>? ?? [];

      // Convert notifications to Announcement format
      for (final notif in notifications) {
        final id = notif['id']?.toString() ?? '';
        final title = notif['title']?.toString() ?? 'Notification';
        final body = notif['body']?.toString() ?? '';
        final type = notif['type']?.toString().toLowerCase() ?? 'info';
        final isRead = notif['isRead'] as bool? ?? false;
        final sentAt = notif['sentAt']?.toString();

        // Convert to time string
        String timeStr = 'Just now';
        if (sentAt != null) {
          try {
            final dateTime = DateTime.parse(sentAt);
            timeStr = _getTimeAgo(dateTime);
          } catch (_) {}
        }

        // Map notification type to announcement type
        String announcementType = 'info';
        if (type.contains('task')) {
          announcementType = 'info';
        } else if (type.contains('alert') || type.contains('urgent')) {
          announcementType = 'alert';
        } else if (type.contains('success') || type.contains('completed')) {
          announcementType = 'success';
        } else if (type.contains('smart_reminder')) {
          announcementType = 'alert'; // Make smart reminders stand out
        }

        announcements.add(Announcement(
          id: 'notif_$id',
          title: title,
          message: body,
          time: timeStr,
          type: announcementType,
          isRead: isRead,
        ));
      }
    } catch (e) {
      AppLogger.log('Error fetching notifications: $e');
      // Continue with just announcements if notifications fail
    }

    // Sort by time (most recent first) - unread items first
    announcements.sort((a, b) {
      if (a.isRead != b.isRead) {
        return a.isRead ? 1 : -1; // Unread first
      }
      return 0;
    });

    return announcements;
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
    if (announcement.id.startsWith('notif_')) {
      final rawId = announcement.id.replaceFirst('notif_', '');
      final notifId = int.tryParse(rawId);
      if (notifId != null) {
        await _backendService.markNotificationAsRead(notifId);
      }
    } else {
      await _backendService.markAnnouncementAsRead(announcement.id);
    }
    await _fetchAnnouncements();

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
      AppLogger.log('Error loading tasks: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    if (userName == null) {
      setBusy(true);
    }
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
      AppLogger.log('Error loading profile: $e');
    } finally {
      if (userName == null) {
        setBusy(false);
      }
    }
  }

  int get currentTab => currentIndex;

  /// Dynamic KPI cards based on real data
  List<KpiCard> get kpiCards {
    // Task Score: based on user's actual task completion
    // If no tasks, show 0%
    String taskScoreValue;
    if (totalTaskCount > 0) {
      final taskPercentage =
          (completedTaskCount / totalTaskCount * 100).round();
      taskScoreValue = '$taskPercentage%';
    } else {
      taskScoreValue = '0%';
    }

    // Attendance: Check if we have actual attendance data in aura pillars
    // Look for punctuality submetric or default to 0 if no check-ins
    String attendanceValue = '0%';
    final cultureFit = auraData?.pillars['cultureFit'];
    if (cultureFit != null && cultureFit.subMetrics.isNotEmpty) {
      // Find punctuality/attendance submetric
      final punctuality = cultureFit.subMetrics
          .where((s) =>
              s.displayName.toLowerCase().contains('punctuality') ||
              s.displayName.toLowerCase().contains('attendance'))
          .firstOrNull;
      if (punctuality != null) {
        attendanceValue = '${punctuality.score.round()}%';
      } else if (cultureFit.score > 0) {
        attendanceValue = '${cultureFit.score.round()}%';
      }
    }

    // Compliance: from Behavioral pillar
    final behavioralScore = auraData?.pillars['behavioral']?.score ?? 0.0;
    final complianceValue =
        behavioralScore > 0 ? '${behavioralScore.round()}%' : '0%';

    // Team Score: Show actual value or '--' if no data
    String teamScoreDisplay;
    String teamGrade = '';
    String teamLabel = 'Team Score';
    if (teamScore != null) {
      teamScoreDisplay = '${teamScore!.overallScore.round()}%';
      teamGrade = teamScore!.grade;
    } else if (teamInsight != null) {
      teamScoreDisplay = '${teamInsight!.kpiScore.round()}%';
    } else {
      teamScoreDisplay = '--';
    }

    return [
      KpiCard(label: 'Task Score', value: taskScoreValue, trend: '--'),
      KpiCard(label: 'Attendance', value: attendanceValue, trend: '--'),
      KpiCard(label: 'Compliance', value: complianceValue, trend: '--'),
      KpiCard(label: teamLabel, value: teamScoreDisplay, trend: teamGrade),
    ];
  }

  // Use real tasks instead of mock
  List<Task> get todayTasks {
    final active = <Task>[];
    final completed = <Task>[];
    for (final task in tasks) {
      if (_isCompletedStatus(task.status)) {
        completed.add(task);
      } else {
        active.add(task);
      }
    }
    return [...active, ...completed];
  }

  bool isTaskCompleted(String status) => _isCompletedStatus(status);

  void updateTask(Task updatedTask) {
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index == -1) {
      return;
    }
    final updated = List<Task>.from(tasks);
    updated[index] = updatedTask;
    tasks = updated;
    rebuildUi();
  }

  // Task distribution computed properties
  bool _isCompletedStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'completed' || normalized == 'done';
  }

  bool _isPendingStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'pending' ||
        normalized == 'todo' ||
        normalized == 'in progress' ||
        normalized == 'in_progress' ||
        normalized == 'review';
  }

  int get completedTaskCount =>
      tasks.where((t) => _isCompletedStatus(t.status)).length;

  int get pendingTaskCount =>
      tasks.where((t) => _isPendingStatus(t.status)).length;

  int get overdueTaskCount {
    return tasks.where((t) {
      final due = t.due.trim().toLowerCase();
      return due == 'overdue' || t.status.trim().toLowerCase() == 'overdue';
    }).length;
  }

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

  void setTab(int index) {
    setIndex(index);
  }
}
