import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';
import 'package:schoolable/ui/views/compliance/compliance_submission_view.dart';

class ComplianceView extends StackedView<ComplianceViewModel> {
  const ComplianceView({Key? key}) : super(key: key);

  @override
  ComplianceViewModel viewModelBuilder(BuildContext context) =>
      ComplianceViewModel();

  @override
  void onViewModelReady(ComplianceViewModel viewModel) {
    viewModel.fetchComplianceItems();
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
        .where((item) => item.status != 'complied')
        .toList();
    final completed = viewModel.complianceItems
        .where((item) => item.status == 'complied')
        .toList();

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
                        '${completed.length}/${viewModel.complianceItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pending.isEmpty
                            ? 'All requirements complete ✓'
                            : '${pending.length} pending ${pending.length == 1 ? "item" : "items"}',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
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
          onTap: isPending
              ? () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplianceSubmissionView(item: item),
                    ),
                  );
                  if (result == true && context.mounted) {
                    // Refresh the list
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
                    color: isPending
                        ? kcAmberColor.withOpacity(0.1)
                        : kcTealColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.type == 'upload'
                        ? Icons.upload_file_rounded
                        : Icons.policy_rounded,
                    color: isPending ? kcAmberColor : kcTealColor,
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
                        isPending
                            ? 'Due: ${_formatDate(item.deadline)}'
                            : 'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPending ? kcAmberColor : kcTealColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow or checkmark
                isPending
                    ? const Icon(Icons.chevron_right,
                        color: kcTextMutedColor, size: 22)
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
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// ViewModel for Compliance View
class ComplianceViewModel extends BaseViewModel {
  List<ComplianceItem> _complianceItems = [];
  List<ComplianceItem> get complianceItems => _complianceItems;

  Future<void> fetchComplianceItems() async {
    setBusy(true);
    try {
      // For now, using mock data similar to HomeViewModel
      // In production, this would call _backendService.getComplianceItems()
      _complianceItems = [
        ComplianceItem(
          id: '1',
          title: 'IT Security Policy',
          description:
              'Review and acknowledge the updated IT security policy for 2024.',
          type: 'policy',
          status: 'pending',
          deadline: DateTime.now().add(const Duration(days: 7)),
        ),
        ComplianceItem(
          id: '2',
          title: 'Submit Tax Identification',
          description: 'Upload your valid tax ID document for payroll records.',
          type: 'upload',
          status: 'pending',
          deadline: DateTime.now().add(const Duration(days: 14)),
        ),
        ComplianceItem(
          id: '3',
          title: 'Code of Conduct',
          description: 'Annual acknowledgement of the company code of conduct.',
          type: 'policy',
          status: 'complied',
          deadline: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];
      notifyListeners();
    } catch (e) {
      setError('Failed to load compliance items');
    } finally {
      setBusy(false);
    }
  }
}
