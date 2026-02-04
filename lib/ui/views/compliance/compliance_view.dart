import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/websocket_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';
import 'package:schoolable/ui/views/compliance/compliance_submission_view.dart';
import 'package:schoolable/services/logging_service.dart';

class ComplianceView extends StackedView<ComplianceViewModel> {
  const ComplianceView({Key? key}) : super(key: key);

  @override
  ComplianceViewModel viewModelBuilder(BuildContext context) =>
      ComplianceViewModel();

  @override
  void onViewModelReady(ComplianceViewModel viewModel) {
    viewModel.initialize();
  }

  @override
  Widget builder(
      BuildContext context, ComplianceViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Compliance',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kcTextColor),
        actions: [
          IconButton(
            onPressed: viewModel.fetchComplianceItems,
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
        ],
      ),
      body: viewModel.isBusy
          ? const Center(
              child: CircularProgressIndicator(color: kcPrimaryColor),
            )
          : viewModel.hasError
              ? _buildErrorState(viewModel)
              : viewModel.complianceItems.isEmpty
                  ? _buildEmptyState()
                  : _buildComplianceList(context, viewModel),
    );
  }

  Widget _buildErrorState(ComplianceViewModel viewModel) {
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
              'Failed to load compliance items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 14,
                color: kcTextMutedColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: viewModel.fetchComplianceItems,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kcTealColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: kcTealColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No pending compliance requirements.',
              style: TextStyle(
                fontSize: 14,
                color: kcTextMutedColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceList(
      BuildContext context, ComplianceViewModel viewModel) {
    final pending = viewModel.complianceItems
        .where((item) => item.status == 'pending' || item.status == 'rejected')
        .toList();
    final inReview = viewModel.complianceItems
        .where((item) => item.status == 'submitted')
        .toList();
    final completed = viewModel.complianceItems
        .where((item) => item.status == 'approved')
        .toList();
    final total = viewModel.complianceItems.length;
    final resolved = total - pending.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kcPrimaryColor,
                  kcPrimaryColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compliance Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$resolved/$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pending.isEmpty && inReview.isEmpty
                            ? 'All requirements complete ✓'
                            : '${pending.length} pending • ${inReview.length} in review',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pending.isEmpty
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // Pending Items Section
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kcAmberColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: kcAmberColor, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Pending Requirements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...pending.map((item) => _buildComplianceCard(context, item, true)),
          ],

          // In Review Section
          if (inReview.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: kcPrimaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'In Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...inReview
                .map((item) => _buildComplianceCard(context, item, false)),
          ],

          // Completed Items Section
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kcTealColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: kcTealColor, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...completed
                .map((item) => _buildComplianceCard(context, item, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceCard(
      BuildContext context, ComplianceItem item, bool isPending) {
    final isInReview = item.status == 'submitted';
    final isApproved = item.status == 'approved';
    final isRejected = item.status == 'rejected';
    final isActionable = isPending || isRejected;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActionable
              ? kcAmberColor.withOpacity(0.3)
              : kcBorderColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActionable
              ? () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplianceSubmissionView(item: item),
                    ),
                  );
                  if (result == true && context.mounted) {
                    await viewModel.fetchComplianceItems();
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActionable
                    ? kcAmberColor.withOpacity(0.1)
                    : isInReview
                        ? kcPrimaryColor.withOpacity(0.1)
                        : kcTealColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.type == 'upload'
                    ? Icons.upload_file_rounded
                    : Icons.policy_rounded,
                color: isActionable
                    ? kcAmberColor
                    : isInReview
                        ? kcPrimaryColor
                        : kcTealColor,
                size: 22,
              ),
            ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isApproved
                            ? 'Approved'
                            : isInReview
                                ? 'Submitted • awaiting review'
                                : isRejected
                                    ? 'Rejected • resubmit required'
                                    : 'Due: ${_formatDate(item.deadline)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActionable
                              ? kcAmberColor
                              : isInReview
                                  ? kcPrimaryColor
                                  : kcTealColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow or checkmark
                isActionable
                    ? const Icon(Icons.chevron_right,
                        color: kcTextMutedColor, size: 22)
                    : isInReview
                        ? const Icon(Icons.hourglass_top_rounded,
                            color: kcPrimaryColor, size: 22)
                    : const Icon(Icons.check_circle,
                        color: kcTealColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }
}

/// ViewModel for Compliance View
class ComplianceViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  final _wsService = locator<WebSocketService>();

  List<ComplianceItem> _complianceItems = [];
  List<ComplianceItem> get complianceItems => _complianceItems;

  MessageCallback? _notificationHandler;

  Future<void> initialize() async {
    await fetchComplianceItems();
    await _subscribeToRealtimeUpdates();
  }

  Future<void> fetchComplianceItems() async {
    setBusy(true);
    try {
      final items = await _backendService.getMyComplianceItems();

      _complianceItems = items.map((item) {
        // Parse date from string if needed
        DateTime deadline;
        if (item['deadline'] != null) {
          deadline = DateTime.tryParse(item['deadline'].toString()) ??
              DateTime.now().add(const Duration(days: 7));
        } else {
          deadline = DateTime.now().add(const Duration(days: 7));
        }

        return ComplianceItem(
          id: item['id']?.toString() ?? '',
          title: item['title']?.toString() ?? 'Compliance Item',
          description: item['description']?.toString() ?? '',
          type: item['type']?.toString() ?? 'policy', // 'policy' or 'upload'
          status: item['status']?.toString() ??
              'pending', // 'pending', 'submitted', 'approved', 'rejected'
          deadline: deadline,
          policyFileUrl: item['fileUrl']?.toString() ??
              item['policyFileUrl']?.toString(),
          policyFileName: item['fileName']?.toString() ??
              item['policyFileName']?.toString(),
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      AppLogger.log('Error fetching compliance items: $e');
      setError('Failed to load compliance items');
    } finally {
      setBusy(false);
    }
  }

  Future<void> _subscribeToRealtimeUpdates() async {
    if (_notificationHandler != null) {
      return;
    }

    if (!_wsService.isConnected) {
      final token = await _backendService.getCurrentToken();
      if (token != null) {
        await _wsService.connect(token);
      }
    }

    _notificationHandler = (message) {
      final notificationType =
          message.data['notificationType']?.toString() ?? '';
      if (notificationType.contains('compliance')) {
        fetchComplianceItems();
      }
    };

    _wsService.subscribeToNotifications(onNotification: _notificationHandler!);
  }

  @override
  void dispose() {
    if (_notificationHandler != null) {
      _wsService.unsubscribeFromNotifications(_notificationHandler!);
      _notificationHandler = null;
    }
    super.dispose();
  }
}
