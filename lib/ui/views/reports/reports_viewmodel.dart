import 'package:stacked/stacked.dart';
import 'package:schoolable/services/backend_api_service.dart';

class ReportsViewModel extends BaseViewModel {
  final BackendApiService _api = BackendApiService();

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

  Map<String, dynamic>? _todayReport;
  Map<String, dynamic>? get todayReport => _todayReport;

  bool _hasSubmittedToday = false;
  bool get hasSubmittedToday => _hasSubmittedToday;

  // Stats
  int _weeklyReportsSubmitted = 0;
  int get weeklyReportsSubmitted => _weeklyReportsSubmitted;

  double _weeklyAverageScore = 0;
  double get weeklyAverageScore => _weeklyAverageScore;

  double _monthlyAverageScore = 0;
  double get monthlyAverageScore => _monthlyAverageScore;

  double _quarterlyAverageScore = 0;
  double get quarterlyAverageScore => _quarterlyAverageScore;

  Future<void> initialize() async {
    setBusy(true);
    try {
      await Future.wait([
        _loadTodayStatus(),
        _loadReports(),
        _loadStats(),
      ]);
    } catch (e) {
      print('Error initializing reports: $e');
    } finally {
      setBusy(false);
    }
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
      print('Error refreshing reports: $e');
    }
  }

  Future<void> _loadTodayStatus() async {
    try {
      final response = await _api.getTodayReport();
      _hasSubmittedToday = response['hasSubmittedToday'] == true;
      if (_hasSubmittedToday && response['report'] != null) {
        _todayReport = Map<String, dynamic>.from(response['report']);
      }
    } catch (e) {
      print('Error loading today status: $e');
    }
  }

  Future<void> _loadReports() async {
    try {
      final response = await _api.getMyReports(limit: 20);
      _reports = response.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      print('Error loading reports: $e');
      _reports = [];
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
    } catch (e) {
      print('Error loading stats: $e');
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
}
