import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'attendance_viewmodel.dart';
import 'attendance_history_view.dart';

class AttendanceView extends StackedView<AttendanceViewModel> {
  const AttendanceView({Key? key}) : super(key: key);

  @override
  AttendanceViewModel viewModelBuilder(BuildContext context) =>
      AttendanceViewModel();

  @override
  void onViewModelReady(AttendanceViewModel viewModel) {
    viewModel.initialize();
  }

  @override
  Widget builder(
      BuildContext context, AttendanceViewModel viewModel, Widget? child) {
    // Show loading skeleton while initializing
    if (viewModel.isBusy) {
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          color: kcPrimaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check In',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Loading your attendance...',
                          style: TextStyle(
                            fontSize: 13,
                            color: kcTextMutedColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Skeleton loading card
                _buildSkeletonCheckInCard(),
              ],
            ),
          ),
        ),
      );
    }

    final todayAttendance = viewModel.todayAttendance;
    final hasCheckedIn = viewModel.hasCheckedInToday ||
        (todayAttendance?['check_in'] != null);
    final hasCheckedOut = viewModel.hasCheckedOutToday ||
        (todayAttendance?['check_out'] != null);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: viewModel.refresh,
        color: kcPrimaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check In',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your daily attendance.',
                      style: TextStyle(
                        fontSize: 13,
                        color: kcTextMutedColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AttendanceHistoryView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kcBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.history,
                        color: kcTextColor, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error message
            if (viewModel.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                //  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red.shade700),
                      onPressed: viewModel.clearError,
                      iconSize: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (hasCheckedIn) ...[
              _buildStatusCard(viewModel),
              const SizedBox(height: 16),
            ],

            Builder(
              builder: (context) {
                final isNonWorkingDay = !viewModel.isWorkDay;
                final isRemoteDay = viewModel.isRemoteDay;
                final isOnsiteDay = viewModel.isOnsiteDay;
                final isLateWarning = viewModel.isLateCheckIn;
                final isVeryLate = viewModel.isLateCheckIn && viewModel.minutesLate > 30;

                if (isNonWorkingDay) {
                  final holidayName = viewModel.holidayName;
                  final dayLabel = viewModel.isHoliday
                      ? (holidayName != null && holidayName.isNotEmpty
                          ? 'Yay, it\'s $holidayName!'
                          : 'It\'s a holiday today')
                      : viewModel.isOnLeave
                          ? 'You\'re on leave today'
                          : 'It\'s a non-working day';
                  final subtitle = viewModel.isHoliday
                      ? 'Enjoy your day off.'
                      : 'No check-in required today.';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kcBorderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.weekend,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kcBorderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnsiteDay
                              ? Colors.blue.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnsiteDay ? Icons.business : Icons.home_work,
                              size: 14,
                              color: isOnsiteDay
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnsiteDay ? 'On-site Day' : 'Remote Day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOnsiteDay
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!hasCheckedIn && isVeryLate) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You haven\'t checked in yet. Please check in now.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else if (!hasCheckedIn && isLateWarning) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reminder: You haven\'t checked in yet today.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else if (hasCheckedIn) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasCheckedOut
                                    ? Icons.logout
                                    : Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hasCheckedOut
                                      ? 'You\'ve checked out for today.'
                                      : 'You\'re checked in for today.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Text(
                        hasCheckedIn
                            ? (hasCheckedOut
                                ? 'Checked out'
                                : 'Check out when ready')
                            : (isOnsiteDay
                                ? 'On-site check-in'
                                : 'Remote check-in'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasCheckedIn
                            ? (hasCheckedOut
                                ? 'Attendance recorded for today.'
                                : 'Tap below when you are leaving.')
                            : (isOnsiteDay
                                ? 'Tap to check in for today.'
                                : 'Confirm your attendance for today.'),
                        style: const TextStyle(
                          color: kcTextMutedColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      // Status message
                      if (viewModel.statusMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              if (viewModel.isVerifyingLocation ||
                                  viewModel.isCapturing ||
                                  viewModel.isVerifyingFace ||
                                  viewModel.isBusy)
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              else
                                Icon(Icons.info_outline,
                                    size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  viewModel.statusMessage!,
                                  style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Single action check-in for on-site days
                      if (!viewModel.hasCheckedInToday && isOnsiteDay) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                viewModel.isBusy
                                ? null
                                : () async {
                                    final locationOk =
                                        await viewModel.verifyLocation();
                                    if (!locationOk) return;

                                    final photoOk =
                                        await viewModel.capturePhoto();
                                    if (!photoOk) return;

                                    if (viewModel.isLateCheckIn) {
                                      final reason =
                                          await _showLateReasonDialog(
                                              context, viewModel);
                                      if (reason != null && reason.isNotEmpty) {
                                        viewModel.performCheckIn(
                                            lateReason: reason);
                                      }
                                    } else {
                                      viewModel.performCheckIn();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kcPrimaryColor,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: viewModel.isBusy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        viewModel.isLateCheckIn
                                            ? 'Check-in Late (${viewModel.minutesLate}min)'
                                            : 'Check In',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],

                      // Remote day check-in (simple one-button flow)
                      if (!viewModel.hasCheckedInToday && isRemoteDay) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                viewModel.isBusy
                                ? null
                                : viewModel.performRemoteCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kcPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: viewModel.isBusy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Check In',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],

                      // Check-out button
                      if (viewModel.hasCheckedInToday &&
                          !viewModel.hasCheckedOutToday)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: viewModel.isBusy
                                ? null
                                : viewModel.performCheckOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kcPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: viewModel.isBusy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout,
                                          size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Check Out',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatusCard(AttendanceViewModel viewModel) {
    final today = viewModel.todayAttendance;
    final status = (today?['status'] as String? ?? 'present').toLowerCase();
    final normalizedStatus = status == 'excused' ? 'late' : status;
    final isLate = normalizedStatus == 'late';

    final Color baseColor = isLate ? Colors.orange : Colors.green;
    final Color background = baseColor.withOpacity(0.08);
    final Color border = baseColor.withOpacity(0.25);
    final Color iconBackground = baseColor.withOpacity(0.15);
    final Color iconColor = baseColor.withOpacity(0.9);
    final Color titleColor = baseColor.withOpacity(0.9);
    final Color subtitleColor = baseColor.withOpacity(0.7);
    final Color badgeText = baseColor.withOpacity(0.9);
    final hasCheckedOut = viewModel.hasCheckedOutToday ||
        (viewModel.todayAttendance?['check_out'] != null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLate ? Icons.access_time : Icons.check_circle,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLate ? 'Checked in late' : 'Checked in today',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCheckedOut
                      ? 'Day completed'
                      : 'Currently at work',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              normalizedStatus.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for step-by-step check-in flow
  Widget _buildCheckInStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLoading,
    required bool isEnabled,
    required IconData icon,
    required Future<dynamic> Function() onTap,
  }) {
    final Color bgColor = isCompleted
        ? Colors.green.shade50
        : (isEnabled ? Colors.white : Colors.grey.shade50);
    final Color borderColor = isCompleted
        ? Colors.green.shade300
        : (isEnabled ? kcPrimaryColor.withOpacity(0.3) : Colors.grey.shade200);
    final Color iconColor = isCompleted
        ? Colors.green.shade600
        : (isEnabled ? kcPrimaryColor : Colors.grey.shade400);
    final Color textColor = isCompleted
        ? Colors.green.shade700
        : (isEnabled ? kcTextColor : Colors.grey.shade500);

    return GestureDetector(
      onTap: isEnabled && !isLoading ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isEnabled ? 1.5 : 1),
        ),
        child: Row(
          children: [
            // Step number circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : (isEnabled ? kcPrimaryColor : Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        '$stepNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Icon
            isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCompleted
                          ? Colors.green.shade600
                          : kcTextMutedColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Action indicator
            if (isEnabled && !isLoading && !isCompleted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kcPrimaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Tap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to collect late check-in reason
  Future<String?> _showLateReasonDialog(
      BuildContext context, AttendanceViewModel viewModel) async {
    final TextEditingController reasonController = TextEditingController();
    final predefinedReasons = viewModel.lateReasons;
    String? selectedReason = predefinedReasons.isEmpty ? 'Other' : null;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.access_time,
                          color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Late Check-in',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kcTextColor,
                            ),
                          ),
                          Text(
                            'Please provide a reason for checking in late',
                            style: TextStyle(
                              fontSize: 12,
                              color: kcTextMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (predefinedReasons.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedReasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedReason = reason;
                            if (reason != 'Other') {
                              reasonController.text = reason;
                            } else {
                              reasonController.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kcPrimaryColor.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? kcPrimaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? kcPrimaryColor
                                  : kcTextMutedColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // Custom reason input (shows when 'Other' is selected)
                if (selectedReason == 'Other' || predefinedReasons.isEmpty)
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter your reason...',
                      hintStyle: const TextStyle(color: kcTextMutedColor),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kcPrimaryColor),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final reason = selectedReason == 'Other'
                          ? reasonController.text.trim()
                          : selectedReason;
                      if (reason != null && reason.isNotEmpty) {
                        Navigator.of(context).pop(reason);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kcPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit & Check-in',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: kcTextMutedColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Skeleton loading card while data is loading
  Widget _buildSkeletonCheckInCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        children: [
          // Skeleton icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton title
          Container(
            width: 180,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          // Skeleton subtitle
          Container(
            width: 220,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          // Skeleton button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
