import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'attendance_viewmodel.dart';
import 'package:schoolable/ui/views/attendance/attendance_view.dart'
    show StringExtension;

class AttendanceHistoryViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();

  List<AttendanceRecord> _history = [];
  List<AttendanceRecord> get history => _history;

  Future<void> initialize() async {
    setBusy(true);
    try {
      final data = await _backendService.getAttendanceHistory();
      _history = data.map((e) => AttendanceRecord.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching history: $e');
    } finally {
      setBusy(false);
    }
  }

  void refresh() => initialize();
}

class AttendanceHistoryView extends StackedView<AttendanceHistoryViewModel> {
  const AttendanceHistoryView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, AttendanceHistoryViewModel viewModel,
      Widget? child) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Attendance History',
            style: TextStyle(color: kcTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: kcTextColor),
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : viewModel.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No history available',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: viewModel.history.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(viewModel.history[index]);
                  },
                ),
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record) {
    // Reuse specific color logic or build similar card
    final statusColor = record.isLate
        ? Colors.orange
        : record.isAbsent
            ? Colors.red
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.login, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.date,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.status.capitalize(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Checked in at ${record.time}',
                  style: const TextStyle(
                    color: kcTextMutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (record.hasCheckedOut && record.checkOutTime != null)
                  Text(
                    'Checked out at ${record.checkOutTime}',
                    style: const TextStyle(
                      color: kcTextMutedColor,
                      fontSize: 12,
                    ),
                  ),
                if (record.address != null || record.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: kcTextMutedColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          // Prioritize address over generic location name
                          record.address ?? record.location ?? '',
                          style: const TextStyle(
                            color: kcTextMutedColor,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  AttendanceHistoryViewModel viewModelBuilder(BuildContext context) =>
      AttendanceHistoryViewModel();

  @override
  void onViewModelReady(AttendanceHistoryViewModel viewModel) =>
      viewModel.initialize();
}
