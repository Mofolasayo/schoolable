import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/compliance/compliance_submission_view.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';

class ComplianceListView extends StatefulWidget {
  final HomeViewModel viewModel;

  const ComplianceListView({Key? key, required this.viewModel})
      : super(key: key);

  @override
  State<ComplianceListView> createState() => _ComplianceListViewState();
}

class _ComplianceListViewState extends State<ComplianceListView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompliance();
  }

  Future<void> _loadCompliance() async {
    await widget.viewModel.refreshCompliance();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.viewModel.complianceItems;
    final isEmpty = items.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Compliance',
          style: TextStyle(color: kcTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kcTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _loadCompliance,
            icon: const Icon(Icons.refresh_rounded, color: kcTextColor),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No compliance items',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Action Required',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kcTextMutedColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) => _buildComplianceItem(context, item)),
                  ],
                ),
    );
  }

  Widget _buildComplianceItem(BuildContext context, ComplianceItem item) {
    final isActionable =
        item.status == 'pending' || item.status == 'rejected';
    final isInReview = item.status == 'submitted';
    final isApproved = item.status == 'approved';
    final chipLabel = isActionable
        ? 'ACTION'
        : isInReview
            ? 'IN REVIEW'
            : 'COMPLETED';
    final chipColor = isActionable
        ? kcPrimaryColor
        : isInReview
            ? kcPrimaryColor
            : kcTealColor;
    return GestureDetector(
      onTap: isActionable ? () => _openComplianceDetails(context, item) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle_outline
                            : Icons.assignment_late_outlined,
                        size: 14,
                        color: chipColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chipLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: chipColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isActionable)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: kcRoseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isInReview)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'IN REVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kcPrimaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: kcTextMutedColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: kcAmberColor),
                const SizedBox(width: 4),
                Text(
                  'Due: ${item.deadline.toString().split(' ')[0]}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kcAmberColor,
                  ),
                ),
                const Spacer(),
                Text(
                  isActionable
                      ? 'Tap to review'
                      : isInReview
                          ? 'Awaiting review'
                          : 'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActionable
                        ? kcPrimaryColor
                        : isInReview
                            ? kcPrimaryColor
                            : kcTextMutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openComplianceDetails(
      BuildContext context, ComplianceItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComplianceSubmissionView(item: item),
      ),
    );
    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      await _loadCompliance();
    }
  }
}
