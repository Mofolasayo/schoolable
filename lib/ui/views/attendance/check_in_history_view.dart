import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';

/// Dedicated view for viewing check-in history
class CheckInHistoryView extends StackedView<CheckInHistoryViewModel> {
  const CheckInHistoryView({Key? key}) : super(key: key);

  @override
  CheckInHistoryViewModel viewModelBuilder(BuildContext context) =>
      CheckInHistoryViewModel();

  @override
  void onViewModelReady(CheckInHistoryViewModel viewModel) {
    viewModel.initialize();
  }

  @override
  Widget builder(
      BuildContext context, CheckInHistoryViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Check-in History',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kcTextColor),
        actions: [
          IconButton(
            onPressed: viewModel.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
        ],
      ),
      body: viewModel.isBusy
          ? const Center(child: CupertinoActivityIndicator())
          : viewModel.hasError
              ? _buildErrorState(viewModel)
              : _buildContent(context, viewModel),
    );
  }

  Widget _buildErrorState(CheckInHistoryViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, CheckInHistoryViewModel viewModel) {
    return Column(
      children: [
        // Summary Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kcPrimaryColor, kcPrimaryColor.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'This Month',
                viewModel.thisMonthCount.toString(),
                Icons.calendar_month,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem(
                'On Time',
                '${viewModel.onTimePercentage}%',
                Icons.check_circle_outline,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem(
                'Late',
                viewModel.lateCount.toString(),
                Icons.access_time,
              ),
            ],
          ),
        ),

        // Month filter
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.availableMonths.length,
            itemBuilder: (context, index) {
              final month = viewModel.availableMonths[index];
              final isSelected = viewModel.selectedMonth == month;
              return GestureDetector(
                onTap: () => viewModel.setSelectedMonth(month),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? kcPrimaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? kcPrimaryColor : kcBorderColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    month,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : kcTextMutedColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // History List
        Expanded(
          child: viewModel.filteredHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No check-ins found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kcTextMutedColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: viewModel.filteredHistory.length,
                  itemBuilder: (context, index) {
                    final record = viewModel.filteredHistory[index];
                    return _buildHistoryCard(record);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final date = _parseDate(record['date'] ?? record['check_in']);
    final checkIn = _formatTime(record['check_in']);
    final checkOut = _formatTime(record['check_out']);
    final status = _normalizeStatus(record['status']?.toString());
    final location = record['location'] ?? record['address'] ?? 'Unknown';
    final photoUrl = record['photo_url'];
    final isLate = status == 'late';
    final isPresent = status == 'present';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Date column
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isLate
                  ? Colors.orange.shade50
                  : isPresent
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  date['day'] ?? '--',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isLate
                        ? Colors.orange.shade700
                        : isPresent
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                  ),
                ),
                Text(
                  date['weekday'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isLate
                        ? Colors.orange.shade600
                        : isPresent
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLate
                            ? Colors.orange.shade100
                            : isPresent
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isLate
                              ? Colors.orange.shade700
                              : isPresent
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      date['fullDate'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: kcTextMutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.login, size: 14, color: kcTextMutedColor),
                    const SizedBox(width: 4),
                    Text(
                      checkIn,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
                      ),
                    ),
                    if (checkOut.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.logout,
                          size: 14, color: kcTextMutedColor),
                      const SizedBox(width: 4),
                      Text(
                        checkOut,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: kcTextMutedColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: kcTextMutedColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Photo thumbnail
          if (photoUrl != null)
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kcBorderColor),
                image: DecorationImage(
                  image: NetworkImage(photoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, String> _parseDate(String? dateStr) {
    if (dateStr == null) return {'day': '--', 'weekday': '', 'fullDate': ''};
    try {
      final date = DateTime.parse(dateStr);
      return {
        'day': date.day.toString(),
        'weekday': DateFormat('EEE').format(date),
        'fullDate': DateFormat('MMM d, y').format(date),
      };
    } catch (_) {
      return {'day': '--', 'weekday': '', 'fullDate': ''};
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final date = DateTime.parse(timeStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

/// ViewModel for Check-in History
class CheckInHistoryViewModel extends BaseViewModel {
  final BackendApiService _backendService = locator<BackendApiService>();
  final CacheService _cacheService = locator<CacheService>();

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => _history;

  String _selectedMonth = 'All';
  String get selectedMonth => _selectedMonth;

  List<String> get availableMonths {
    final months = <String>{'All'};
    for (final record in _history) {
      try {
        final date = DateTime.parse(record['check_in'] ?? record['date'] ?? '');
        months.add(DateFormat('MMM y').format(date));
      } catch (_) {}
    }
    return months.toList();
  }

  List<Map<String, dynamic>> get filteredHistory {
    if (_selectedMonth == 'All') return _history;
    return _history.where((record) {
      try {
        final date = DateTime.parse(record['check_in'] ?? record['date'] ?? '');
        return DateFormat('MMM y').format(date) == _selectedMonth;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String _normalizeStatus(String? status) {
    final normalized = (status ?? 'present').toLowerCase();
    return normalized == 'excused' ? 'late' : normalized;
  }

  int get thisMonthCount {
    final now = DateTime.now();
    return _history.where((r) {
      try {
        final date = DateTime.parse(r['check_in'] ?? r['date'] ?? '');
        return date.month == now.month && date.year == now.year;
      } catch (_) {
        return false;
      }
    }).length;
  }

  int get lateCount {
    return _history
        .where((r) => _normalizeStatus(r['status']?.toString()) == 'late')
        .length;
  }

  int get onTimePercentage {
    if (_history.isEmpty) return 0;
    final onTime = _history.where((r) {
      final status = _normalizeStatus(r['status']?.toString());
      return status == 'present' || status == 'early';
    }).length;
    return ((onTime / _history.length) * 100).round();
  }

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    rebuildUi();
  }

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    setBusy(true);
    setError(null);

    try {
      // Load cached history first
      final cached = await _cacheService.getCachedAttendanceHistory();
      if (cached != null && cached.isNotEmpty) {
        _history = cached.map((e) => Map<String, dynamic>.from(e)).toList();
        rebuildUi();
      }

      // Fetch fresh data
      final freshHistory = await _backendService.getAttendanceHistory();
      _history = freshHistory;

      // Cache the data
      await _cacheService.cacheAttendanceHistory(freshHistory);

      notifyListeners();
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }
}
