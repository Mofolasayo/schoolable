import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';

import 'leave_viewmodel.dart';

class LeaveView extends StackedView<LeaveViewModel> {
  const LeaveView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, LeaveViewModel viewModel, Widget? child) {
    final totalRequests = viewModel.requests.length;
    final approvedCount = viewModel.requests
        .where((r) => r.status.toLowerCase() == 'approved')
        .length;
    final pendingCount = viewModel.requests
        .where((r) => r.status.toLowerCase() == 'pending')
        .length;
    final rejectedCount = viewModel.requests
        .where((r) => r.status.toLowerCase() == 'rejected')
        .length;
    final startDate = viewModel.startDate;
    final endDate = viewModel.endDate;
    String? durationLabel;
    if (startDate != null && endDate != null) {
      final days = endDate.difference(startDate).inDays + 1;
      if (days > 0) {
        durationLabel = '$days day${days == 1 ? '' : 's'} requested';
      } else {
        durationLabel = 'End date must be after start date';
      }
    }
    final isInvalidRange =
        durationLabel == 'End date must be after start date';

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: kcBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kcTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Apply for Leave',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kcTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose dates and provide details for approval.',
                    style: TextStyle(
                      fontSize: 12,
                      color: kcTextMutedColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (viewModel.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kcRoseColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kcRoseColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: kcRoseColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: const TextStyle(
                                color: kcRoseColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: kcRoseColor),
                            onPressed: viewModel.clearError,
                            iconSize: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request time off',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Submit a leave request for approval.',
                          style: TextStyle(
                            fontSize: 12,
                            color: kcTextMutedColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: 'Start date',
                                value: viewModel.startDate,
                                onTap: () => _pickDate(context,
                                    viewModel.startDate, viewModel.setStartDate),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateField(
                                label: 'End date',
                                value: viewModel.endDate,
                                onTap: () => _pickDate(context, viewModel.endDate,
                                    viewModel.setEndDate),
                              ),
                            ),
                          ],
                        ),
                        if (durationLabel != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: kcBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: (isInvalidRange
                                          ? kcRoseColor
                                          : kcTextMutedColor)
                                      .withOpacity(0.2)),
                            ),
                            child: Text(
                              durationLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isInvalidRange
                                    ? kcRoseColor
                                    : kcTextMutedColor,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: viewModel.typeController,
                          decoration: InputDecoration(
                            labelText: 'Leave type',
                            hintText: 'Annual leave, sick, medical, etc',
                            filled: true,
                            fillColor: kcBackgroundColor,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: kcBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: kcBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: kcPrimaryColor, width: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: viewModel.notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Add a short reason or context',
                            filled: true,
                            fillColor: kcBackgroundColor,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: kcBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: kcBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: kcPrimaryColor, width: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: viewModel.isSubmitting
                                ? null
                                : viewModel.submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kcPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded,
                                size: 16, color: Colors.white),
                            label:  Text(
                              viewModel.isSubmitting
                                  ? 'Submitting...'
                                  : 'Submit request',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Your leave requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kcBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kcBorderColor),
                        ),
                        child: Text(
                          totalRequests.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kcTextMutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CountChip(
                        label: 'Approved',
                        count: approvedCount,
                        color: const Color(0xFF10B981),
                      ),
                      _CountChip(
                        label: 'Pending',
                        count: pendingCount,
                        color: const Color(0xFFF59E0B),
                      ),
                      _CountChip(
                        label: 'Rejected',
                        count: rejectedCount,
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (viewModel.requests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: _cardDecoration(),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.inbox_rounded,
                              color: kcTextMutedColor, size: 20),
                          SizedBox(height: 10),
                          Text(
                            'No leave requests yet.',
                            style: TextStyle(
                              color: kcTextMutedColor,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your submitted requests will appear here.',
                            style: TextStyle(
                              color: kcTextMutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...viewModel.requests.map((request) {
                      final statusColor = _statusColor(request.status);
                      final rangeLabel = _formatRange(
                        request.startDate,
                        request.endDate,
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      request.type,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: kcTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  request.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.date_range,
                                  size: 14,
                                  color: kcTextMutedColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    rangeLabel,
                                    style: const TextStyle(
                                      color: kcTextMutedColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (request.notes != null &&
                                request.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.notes,
                                    size: 14,
                                    color: kcTextMutedColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      request.notes!,
                                      style: const TextStyle(
                                        color: kcTextMutedColor,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  @override
  LeaveViewModel viewModelBuilder(BuildContext context) => LeaveViewModel();

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: kcSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kcBorderColor),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    void Function(DateTime) onSelected,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'No dates selected';
    final formatter = DateFormat('EEE, d MMM yyyy');
    if (start != null && end != null) {
      return '${formatter.format(start)} → ${formatter.format(end)}';
    }
    return formatter.format(start ?? end!);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? 'Select date'
        : DateFormat('EEE, d MMM yyyy').format(value!);
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kcBackgroundColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kcBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kcBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kcPrimaryColor, width: 1.2),
          ),
        ),
        child: Text(
          formatted,
          style: const TextStyle(
            fontSize: 13,
            color: kcTextColor,
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kcBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kcTextMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
