import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';

import 'reports_viewmodel.dart';

// Date formatting helpers (avoid intl dependency)
String _formatShortDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
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
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

String _formatFullDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
}

class ReportsView extends StackedView<ReportsViewModel> {
  const ReportsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, ReportsViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: viewModel.refresh,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Daily Reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kcTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit your daily work report',
                      style: TextStyle(
                        fontSize: 14,
                        color: kcTextMutedColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards
                    if (!viewModel.isBusy) _buildStatsSection(viewModel),
                    const SizedBox(height: 24),

                    // Today's Report Status
                    _buildTodayStatus(context, viewModel),
                    const SizedBox(height: 24),

                    // Recent Reports
                    const Text(
                      'Recent Reports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // Reports List
            if (viewModel.isBusy)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (viewModel.reports.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildEmptyState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= viewModel.reports.length) return null;
                      final report = viewModel.reports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildReportCard(context, report, viewModel),
                      );
                    },
                    childCount: viewModel.reports.length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      floatingActionButton: viewModel.hasSubmittedToday
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showSubmitReportSheet(context, viewModel),
              backgroundColor: kcPrimaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Submit Report',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildStatsSection(ReportsViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today_rounded,
            iconColor: kcPrimaryColor,
            label: 'This Week',
            value: '${viewModel.weeklyReportsSubmitted}/5',
            subtitle: 'reports',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            iconColor: kcAmberColor,
            label: 'Avg. Score',
            value: viewModel.weeklyAverageScore > 0
                ? '${viewModel.weeklyAverageScore.toStringAsFixed(0)}%'
                : '--',
            subtitle: 'weekly',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            iconColor: kcTealColor,
            label: 'Quarter',
            value: viewModel.quarterlyAverageScore > 0
                ? '${viewModel.quarterlyAverageScore.toStringAsFixed(0)}%'
                : '--',
            subtitle: 'average',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kcTextColor,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: kcTextMutedColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatus(BuildContext context, ReportsViewModel viewModel) {
    final hasSubmitted = viewModel.hasSubmittedToday;
    final todayReport = viewModel.todayReport;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasSubmitted
              ? [kcTealColor.withOpacity(0.1), kcTealColor.withOpacity(0.05)]
              : [kcAmberColor.withOpacity(0.1), kcAmberColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSubmitted
              ? kcTealColor.withOpacity(0.3)
              : kcAmberColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasSubmitted
                  ? kcTealColor.withOpacity(0.1)
                  : kcAmberColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasSubmitted
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: hasSubmitted ? kcTealColor : kcAmberColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSubmitted ? 'Today\'s Report Submitted' : 'Pending Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasSubmitted ? kcTealColor : kcAmberColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSubmitted
                      ? 'AI Score: ${todayReport?['aiScore']?.toStringAsFixed(0) ?? '--'}%'
                      : 'Submit your daily report to track progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: kcTextMutedColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (hasSubmitted && todayReport != null)
            GestureDetector(
              onTap: () => _showReportDetail(context, todayReport),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: kcTealColor.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: kcTextMutedColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Reports Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start submitting daily reports to track your progress',
            style: TextStyle(
              fontSize: 13,
              color: kcTextMutedColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report,
      ReportsViewModel viewModel) {
    final reportDate =
        DateTime.tryParse(report['reportDate'] ?? '') ?? DateTime.now();
    final aiScore = report['aiScore'] as num?;
    final status = report['status'] as String? ?? 'submitted';

    Color statusColor = kcPrimaryColor;
    if (status == 'reviewed') statusColor = kcTealColor;
    if (status == 'flagged') statusColor = kcRoseColor;

    return GestureDetector(
      onTap: () => _showReportDetail(context, report),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kcPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatShortDate(reportDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kcPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (aiScore != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          _getScoreColor(aiScore.toDouble()).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: _getScoreColor(aiScore.toDouble()),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${aiScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(aiScore.toDouble()),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report['tasksCompleted'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: kcTextColor,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (report['aiFeedback'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: kcAmberColor.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report['aiFeedback'],
                        style: TextStyle(
                          fontSize: 12,
                          color: kcTextMutedColor.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return kcTealColor;
    if (score >= 60) return kcAmberColor;
    return kcRoseColor;
  }

  void _showSubmitReportSheet(
      BuildContext context, ReportsViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubmitReportSheet(viewModel: viewModel),
    );
  }

  void _showReportDetail(BuildContext context, Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailSheet(report: report),
    );
  }

  @override
  ReportsViewModel viewModelBuilder(BuildContext context) => ReportsViewModel();

  @override
  void onViewModelReady(ReportsViewModel viewModel) {
    viewModel.initialize();
  }
}

class _SubmitReportSheet extends StatefulWidget {
  final ReportsViewModel viewModel;

  const _SubmitReportSheet({required this.viewModel});

  @override
  State<_SubmitReportSheet> createState() => _SubmitReportSheetState();
}

class _SubmitReportSheetState extends State<_SubmitReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tasksCompletedController = TextEditingController();
  final _tasksInProgressController = TextEditingController();
  final _blockersController = TextEditingController();
  final _plannedController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tasksCompletedController.dispose();
    _tasksInProgressController.dispose();
    _blockersController.dispose();
    _plannedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Submit Daily Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      label: 'Tasks Completed *',
                      hint: 'What did you accomplish today?',
                      controller: _tasksCompletedController,
                      maxLines: 4,
                      required: true,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Tasks In Progress',
                      hint: 'What are you currently working on?',
                      controller: _tasksInProgressController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Blockers',
                      hint: 'Any challenges or blockers?',
                      controller: _blockersController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Planned for Tomorrow',
                      hint: 'What do you plan to work on tomorrow?',
                      controller: _plannedController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Additional Notes',
                      hint: 'Any other notes or updates',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          // Submit Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: kcBorderColor)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kcTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: kcTextMutedColor.withOpacity(0.5),
              fontSize: 14,
            ),
            filled: true,
            fillColor: kcBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.viewModel.submitReport(
        tasksCompleted: _tasksCompletedController.text.trim(),
        tasksInProgress: _tasksInProgressController.text.trim().isEmpty
            ? null
            : _tasksInProgressController.text.trim(),
        blockers: _blockersController.text.trim().isEmpty
            ? null
            : _blockersController.text.trim(),
        plannedForTomorrow: _plannedController.text.trim().isEmpty
            ? null
            : _plannedController.text.trim(),
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: kcTealColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: kcRoseColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ReportDetailSheet extends StatelessWidget {
  final Map<String, dynamic> report;

  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final reportDate =
        DateTime.tryParse(report['reportDate'] ?? '') ?? DateTime.now();
    final aiScore = report['aiScore'] as num?;
    final status = report['status'] as String? ?? 'submitted';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatFullDate(reportDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kcTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: kcTextMutedColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          // AI Score Banner
          if (aiScore != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kcPrimaryColor.withOpacity(0.1),
                    Colors.purple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: kcPrimaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Assessment Score',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report['aiFeedback'] ?? 'No feedback available',
                          style: TextStyle(
                            fontSize: 12,
                            color: kcTextMutedColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${aiScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kcPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                      'Tasks Completed', report['tasksCompleted'] ?? 'N/A'),
                  if (report['tasksInProgress'] != null)
                    _buildSection(
                        'Tasks In Progress', report['tasksInProgress']),
                  if (report['blockers'] != null)
                    _buildSection('Blockers', report['blockers']),
                  if (report['plannedForTomorrow'] != null)
                    _buildSection(
                        'Planned for Tomorrow', report['plannedForTomorrow']),
                  if (report['additionalNotes'] != null)
                    _buildSection(
                        'Additional Notes', report['additionalNotes']),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kcBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: kcTextMutedColor.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
