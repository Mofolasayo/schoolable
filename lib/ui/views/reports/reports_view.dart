import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';

import 'reports_viewmodel.dart';

// Date formatting helpers
String _formatShortDate(DateTime date) {
  return DateFormat('EEE, MMM d').format(date);
}

String _formatFullDate(DateTime date) {
  return DateFormat('EEEE, MMMM d, y').format(date);
}

String _formatStatusLabel(String status) {
  final normalized = status.replaceAll('_', ' ').trim().toLowerCase();
  if (normalized.isEmpty) return status;
  return normalized
      .split(' ')
      .map((word) =>
          word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase().replaceAll(' ', '_');
  switch (normalized) {
    case 'reviewed':
      return kcTealColor;
    case 'flagged':
      return kcRoseColor;
    case 'submitted':
      return kcPrimaryColor;
    default:
      return kcTextMutedColor;
  }
}

List<String> _parseJsonList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } catch (_) {}
  }
  return [];
}

Color _getScoreColor(double score) {
  if (score >= 80) return kcTealColor;
  if (score >= 60) return kcAmberColor;
  return kcRoseColor;
}

class ReportsView extends StackedView<ReportsViewModel> {
  const ReportsView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, ReportsViewModel viewModel, Widget? child) {
    const previewLimit = 5;
    final previewReports =
        viewModel.reports.take(previewLimit).toList(growable: false);

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Reports',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: kcTextColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Submit today\'s report',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kcTextMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _HeaderIconButton(
                          icon: Icons.history_rounded,
                          onTap: () => _openHistory(context, viewModel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards - show skeleton when loading
                    if (viewModel.isBusy)
                      _buildSkeletonStatsSection()
                    else
                      _buildStatsSection(viewModel),
                    const SizedBox(height: 24),

                    // Today's Report Status - show skeleton when loading
                    if (viewModel.isBusy)
                      _buildSkeletonTodayStatus()
                    else
                      _buildTodayStatus(context, viewModel),
                    const SizedBox(height: 24),

                    // Latest Reports
                    const Text(
                      'Latest Reports',
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
                  child: const _EmptyReportsState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= previewReports.length) return null;
                      final report = previewReports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReportCard(
                          report: report,
                          onTap: () => _showReportDetail(context, report),
                        ),
                      );
                    },
                    childCount: previewReports.length,
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
            dotColor: kcPrimaryColor,
            label: 'This Week',
            value: '${viewModel.weeklyReportsSubmitted}/5',
            subtitle: 'reports',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            dotColor: kcAmberColor,
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
            dotColor: kcTealColor,
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
    required Color dotColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kcTextMutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: kcTextMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton loading for stats section
  Widget _buildSkeletonStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildSkeletonStatCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonStatCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonStatCard()),
      ],
    );
  }

  Widget _buildSkeletonStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 30,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton loading for today's status
  Widget _buildSkeletonTodayStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatus(BuildContext context, ReportsViewModel viewModel) {
    final hasSubmitted = viewModel.hasSubmittedToday;
    final todayReport = viewModel.todayReport;
    final isLate = viewModel.isLateSubmission;
    final accentColor =
        hasSubmitted ? kcTealColor : (isLate ? kcRoseColor : kcAmberColor);

    if (hasSubmitted && todayReport != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report submitted',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kcTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI score: ${todayReport['aiScore']?.toStringAsFixed(0) ?? '--'}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kcTextMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showReportDetail(context, todayReport),
              child: const Text(
                'View',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kcPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLate ? Icons.warning_amber_rounded : Icons.edit_note_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLate ? 'Report overdue' : 'Report pending',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.timeRemainingToday,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kcTextMutedColor,
                  ),
                ),
              ],
            ),
          ),
          // TextButton(
          //   onPressed: () => _showSubmitReportSheet(context, viewModel),
          //   child: const Text(
          //     'Submit',
          //     style: TextStyle(
          //       fontSize: 12,
          //       fontWeight: FontWeight.w600,
          //       color: kcPrimaryColor,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
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

  void _openHistory(BuildContext context, ReportsViewModel viewModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReportHistoryView(viewModel: viewModel),
      ),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kcBorderColor),
        ),
        child: Icon(icon, size: 20, color: kcTextMutedColor),
      ),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState({
    this.title = 'No Reports Yet',
    this.subtitle = 'Start submitting daily reports to track your progress',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: kcSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 56,
            color: kcTextMutedColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kcTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: kcTextMutedColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final Map<String, dynamic> report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reportDate =
        DateTime.tryParse(report['reportDate'] ?? '') ?? DateTime.now();
    final aiScore = report['aiScore'] as num?;
    final status = report['status'] as String? ?? 'submitted';
    final statusColor = _statusColor(status);
    final statusLabel = _formatStatusLabel(status);
    final strengths = _parseJsonList(report['aiStrengths']);
    final improvements = _parseJsonList(report['aiImprovements']);
    final auraTips = _parseJsonList(report['aiAuraBoostTips']);
    final suggestions = _parseJsonList(report['aiSuggestions']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kcSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kcBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatShortDate(reportDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kcTextMutedColor,
                  ),
                ),
                if (aiScore != null)
                  _ReportPill(
                    label: '${aiScore.toStringAsFixed(0)}%',
                    icon: Icons.auto_awesome,
                    color: _getScoreColor(aiScore.toDouble()),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _ReportPill(label: statusLabel, color: statusColor),
            const SizedBox(height: 10),
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
              const SizedBox(height: 8),
              Text(
                report['aiFeedback'],
                style: TextStyle(
                  fontSize: 12,
                  color: kcTextMutedColor.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportHistoryView extends StatelessWidget {
  const _ReportHistoryView({required this.viewModel});

  final ReportsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Report History',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: kcTextColor),
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          final reports = viewModel.filteredReports;
          final hasFilter = viewModel.hasHistoryFilter;

          if (viewModel.isBusy && viewModel.reports.isEmpty) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (reports.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyReportsState(
                title: hasFilter ? 'No reports in range' : 'No reports found',
                subtitle: hasFilter
                    ? 'Try a different date range.'
                    : 'Start submitting daily reports to track your progress',
              ),
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: viewModel.refresh),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          viewModel.historyRangeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kcTextMutedColor,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime(DateTime.now().year + 1),
                          );
                          if (range != null) {
                            viewModel.setHistoryDateRange(
                                range.start, range.end);
                          }
                        },
                        child: const Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kcPrimaryColor,
                          ),
                        ),
                      ),
                      if (hasFilter)
                        TextButton(
                          onPressed: viewModel.clearHistoryDateRange,
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kcTextMutedColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= reports.length) return null;
                      final report = reports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReportCard(
                          report: report,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                _ReportDetailSheet(report: report),
                          ),
                        ),
                      );
                    },
                    childCount: reports.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
          // Form - Expanded and scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset > 0 ? 20 : 0),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          // Submit Button - Make always visible
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, bottomInset > 0 ? bottomInset + 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: kcBorderColor)),
              boxShadow: bottomInset > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ]
                  : null,
            ),
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
    final statusColor = _statusColor(status);
    final statusLabel = _formatStatusLabel(status);
    final strengths = _parseJsonList(report['aiStrengths']);
    final improvements = _parseJsonList(report['aiImprovements']);
    final auraTips = _parseJsonList(report['aiAuraBoostTips']);
    final suggestions = _parseJsonList(report['aiSuggestions']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: kcSurfaceColor,
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
                Expanded(
                  child: Text(
                    _formatFullDate(reportDate),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: kcTextColor,
                    ),
                  ),
                ),
                _ReportPill(label: statusLabel, color: statusColor),
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
                color: kcSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withOpacity(0.12),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report['aiFeedback'] ?? 'No feedback available',
                          style: TextStyle(
                            fontSize: 12,
                            color: kcTextMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${aiScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
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
                  if (strengths.isNotEmpty)
                    _buildListSection('Strengths', strengths, kcTealColor),
                  if (improvements.isNotEmpty)
                    _buildListSection(
                        'Improvements', improvements, kcAmberColor),
                  if (suggestions.isNotEmpty)
                    _buildListSection(
                        'Tomorrow Priorities', suggestions, kcPrimaryColor),
                  if (auraTips.isNotEmpty)
                    _buildListSection(
                        'Aura Boost Tips', auraTips, kcPurpleColor),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kcTextMutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kcSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kcBorderColor),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: kcTextColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: kcTextColor,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPill extends StatelessWidget {
  const _ReportPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
