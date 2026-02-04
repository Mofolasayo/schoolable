import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/services/logging_service.dart';

class ReportsViewModel extends BaseViewModel {
  final BackendApiService _api = locator<BackendApiService>();
  final CacheService _cacheService = locator<CacheService>();

  Timer? _pollingTimer;
  bool _isInitialized = false;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

  Map<String, dynamic>? _todayReport;
  Map<String, dynamic>? get todayReport => _todayReport;

  bool _hasSubmittedToday = false;
  bool get hasSubmittedToday => _hasSubmittedToday;

  Map<String, dynamic>? _submissionWindow;
  Map<String, dynamic>? get submissionWindow => _submissionWindow;

  DateTime? _historyStartDate;
  DateTime? _historyEndDate;
  bool get hasHistoryFilter =>
      _historyStartDate != null && _historyEndDate != null;

  String get historyRangeLabel {
    if (!hasHistoryFilter) {
      return 'All dates';
    }
    return '${_formatDate(_historyStartDate!)} - ${_formatDate(_historyEndDate!)}';
  }

  List<Map<String, dynamic>> get filteredReports {
    if (!hasHistoryFilter) {
      return _reports;
    }
    final start = DateTime(
      _historyStartDate!.year,
      _historyStartDate!.month,
      _historyStartDate!.day,
    );
    final end = DateTime(
      _historyEndDate!.year,
      _historyEndDate!.month,
      _historyEndDate!.day,
      23,
      59,
      59,
    );
    return _reports.where((report) {
      final reportDate = _parseReportDate(report);
      if (reportDate == null) return false;
      return !reportDate.isBefore(start) && !reportDate.isAfter(end);
    }).toList();
  }

  // Stats
  int _weeklyReportsSubmitted = 0;
  int get weeklyReportsSubmitted => _weeklyReportsSubmitted;

  double _weeklyAverageScore = 0;
  double get weeklyAverageScore => _weeklyAverageScore;

  double _monthlyAverageScore = 0;
  double get monthlyAverageScore => _monthlyAverageScore;

  double _quarterlyAverageScore = 0;
  double get quarterlyAverageScore => _quarterlyAverageScore;

  // Time remaining to submit today's report
  String get timeRemainingToday {
    final window = _submissionWindow;
    if (window != null) {
      final minutesRemaining = window['minutesRemaining'];
      final cutoffTime = window['cutoffTime'];
      if (minutesRemaining is num) {
        if (minutesRemaining <= 0) {
          return cutoffTime != null
              ? 'Submission window closed ($cutoffTime)'
              : 'Submission window closed';
        }
        final hours = minutesRemaining ~/ 60;
        final minutes = minutesRemaining % 60;
        final timeLeft =
            hours > 0 ? '${hours}h ${minutes}m left' : '${minutes}m left';
        if (cutoffTime != null) {
          return 'Submit by $cutoffTime • $timeLeft';
        }
        return timeLeft;
      }
      if (cutoffTime is String && cutoffTime.isNotEmpty) {
        return 'Submit by $cutoffTime';
      }
    }

    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    final diff = endOfDay.difference(now);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    }
    return '${diff.inMinutes}m left';
  }

  // Is it too late to submit today?
  bool get isLateSubmission {
    final windowLate = _submissionWindow?['isLate'];
    if (windowLate is bool) {
      return windowLate;
    }
    final now = DateTime.now();
    return now.hour >= 18; // After 6 PM is considered late
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      // Already initialized - just do a silent refresh
      _refreshSilently();
      return;
    }

    setBusy(true);
    try {
      // 1. Load cached data first for instant display
      await _loadCachedData();

      // 2. Fetch fresh data
      await Future.wait([
        _loadTodayStatus(),
        _loadReports(),
        _loadStats(),
      ]);

      // 3. Start silent polling (every 5 minutes)
      _startPolling();

      _isInitialized = true;
    } catch (e) {
      AppLogger.log('Error initializing reports: $e');
    } finally {
      setBusy(false);
    }
  }

  /// Load cached data for instant display
  Future<void> _loadCachedData() async {
    try {
      final cachedReports = await _cacheService.get('cache_reports');
      if (cachedReports != null && cachedReports is List) {
        _reports =
            cachedReports.map((r) => Map<String, dynamic>.from(r)).toList();

        // Check if any report is from today
        final today = DateTime.now();
        for (final report in _reports) {
          final createdAt = report['createdAt'] ?? report['created_at'];
          if (createdAt != null) {
            try {
              final date = DateTime.parse(createdAt.toString());
              if (date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year) {
                _hasSubmittedToday = true;
                _todayReport = report;
                break;
              }
            } catch (_) {}
          }
        }

        notifyListeners();
      }
    } catch (e) {
      AppLogger.log('Error loading cached reports: $e');
    }
  }

  /// Start silent polling
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshSilently();
    });
  }

  /// Refresh data silently without loading state
  Future<void> _refreshSilently() async {
    try {
      await Future.wait([
        _loadTodayStatus(),
        _loadReports(),
        _loadStats(),
      ]);
    } catch (e) {
      AppLogger.log('Error in silent refresh: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      await Future.wait([
        _loadTodayStatus(),
        _loadReports(),
        _loadStats(),
      ]);
      notifyListeners();
    } catch (e) {
      AppLogger.log('Error refreshing reports: $e');
    }
  }

  Future<void> _loadTodayStatus() async {
    try {
      final response = await _api.getTodayReport();
      _hasSubmittedToday = response['hasSubmittedToday'] == true;
      if (response['submissionWindow'] is Map) {
        _submissionWindow =
            Map<String, dynamic>.from(response['submissionWindow']);
      } else {
        _submissionWindow = null;
      }
      if (_hasSubmittedToday && response['report'] != null) {
        _todayReport = Map<String, dynamic>.from(response['report']);
      } else {
        _todayReport = null;
      }
      notifyListeners();
    } catch (e) {
      AppLogger.log('Error loading today status: $e');
    }
  }

  Future<void> _loadReports() async {
    try {
      final response = await _api.getMyReports(limit: 20);
      _reports = response.map((r) => Map<String, dynamic>.from(r)).toList();

      // Cache the reports
      await _cacheService.set('cache_reports', _reports);

      notifyListeners();
    } catch (e) {
      AppLogger.log('Error loading reports: $e');
      // Keep existing cached data if API fails
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _api.getDailyReportStats();
      _weeklyReportsSubmitted = stats['weeklyReportsSubmitted'] as int? ?? 0;
      _weeklyAverageScore =
          (stats['weeklyAverageScore'] as num?)?.toDouble() ?? 0;
      _monthlyAverageScore =
          (stats['monthlyAverageScore'] as num?)?.toDouble() ?? 0;
      _quarterlyAverageScore =
          (stats['quarterlyAverageScore'] as num?)?.toDouble() ?? 0;
      notifyListeners();
    } catch (e) {
      AppLogger.log('Error loading stats: $e');
    }
  }

  Future<void> submitReport({
    required String tasksCompleted,
    String? tasksInProgress,
    String? blockers,
    String? plannedForTomorrow,
    String? additionalNotes,
  }) async {
    final response = await _api.submitDailyReport(
      tasksCompleted: tasksCompleted,
      tasksInProgress: tasksInProgress,
      blockers: blockers,
      plannedForTomorrow: plannedForTomorrow,
      additionalNotes: additionalNotes,
    );

    if (response['success'] == true) {
      // Refresh data
      await refresh();
    } else {
      throw Exception(response['error'] ?? 'Failed to submit report');
    }
  }

  Future<void> updateReport({
    required int reportId,
    String? tasksCompleted,
    String? tasksInProgress,
    String? blockers,
    String? plannedForTomorrow,
    String? additionalNotes,
  }) async {
    final response = await _api.updateDailyReport(
      reportId: reportId,
      tasksCompleted: tasksCompleted,
      tasksInProgress: tasksInProgress,
      blockers: blockers,
      plannedForTomorrow: plannedForTomorrow,
      additionalNotes: additionalNotes,
    );

    if (response['success'] == true) {
      await refresh();
    } else {
      throw Exception(response['error'] ?? 'Failed to update report');
    }
  }

  void setHistoryDateRange(DateTime? start, DateTime? end) {
    _historyStartDate = start;
    _historyEndDate = end;
    notifyListeners();
  }

  void clearHistoryDateRange() {
    _historyStartDate = null;
    _historyEndDate = null;
    notifyListeners();
  }

  DateTime? _parseReportDate(Map<String, dynamic> report) {
    final rawDate = report['reportDate'] ??
        report['report_date'] ??
        report['createdAt'] ??
        report['created_at'];
    if (rawDate == null) return null;
    try {
      final parsed = DateTime.parse(rawDate.toString());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}