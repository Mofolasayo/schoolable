import 'dart:io';
import 'package:flutter/cupertino.dart';
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
    return SafeArea(
      child: SingleChildScrollView(
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
                Container(
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
                  child:
                      const Icon(Icons.history, color: kcTextColor, size: 22),
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
                  border: Border.all(color: Colors.red.shade200),
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

            // Today's Status Card
            if (viewModel.hasCheckedInToday) ...[
              _buildStatusCard(viewModel),
              const SizedBox(height: 16),
            ],

            // Check-in Card
            Builder(
              builder: (context) {
                // Check day type
                final today = DateTime.now();
                // Saturday (6) and Sunday (7) are weekends - no check-in required
                final isWeekend = today.weekday == DateTime.saturday ||
                    today.weekday == DateTime.sunday;
                // Tuesday and Friday are on-site days
                final isOnsiteDay = today.weekday == DateTime.tuesday ||
                    today.weekday == DateTime.friday;
                // Monday, Wednesday, Thursday are remote work days
                final isRemoteDay = !isOnsiteDay && !isWeekend;

                final isLateWarning = !viewModel.hasCheckedInToday &&
                    !isWeekend &&
                    today.hour >= 9; // After 9 AM and not checked in
                final isVeryLate = !viewModel.hasCheckedInToday &&
                    !isWeekend &&
                    today.hour >= 10; // After 10 AM and not checked in

                // If it's a weekend, show a different UI
                if (isWeekend) {
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
                          'It\'s the weekend! 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No check-in required today. Enjoy your time off!',
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
                      color: isVeryLate
                          ? Colors.red.shade200
                          : isLateWarning
                              ? Colors.orange.shade200
                              : kcBorderColor,
                      width: isLateWarning || isVeryLate ? 2 : 1,
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
                      // Day type indicator
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

                      // Late warning banner
                      if (isVeryLate) ...[
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
                                  'You\'re running very late! Please check in immediately.',
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
                      ] else if (isLateWarning) ...[
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
                      ],

                      Text(
                        viewModel.hasCheckedInToday
                            ? (viewModel.hasCheckedOutToday
                                ? 'You\'re all set for today!'
                                : 'Ready to check out?')
                            : (isOnsiteDay
                                ? 'Check-in Steps'
                                : 'Mark your remote attendance'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        viewModel.hasCheckedInToday
                            ? (viewModel.hasCheckedOutToday
                                ? 'Your attendance has been recorded.'
                                : 'Tap below when you\'re leaving.')
                            : (isOnsiteDay
                                ? 'Verify location, take a selfie, then complete check-in.'
                                : 'Confirm your remote work status for today.'),
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

                      // Step-by-step check-in for on-site days
                      if (!viewModel.hasCheckedInToday && isOnsiteDay) ...[
                        // Step 1: Verify Location
                        _buildCheckInStep(
                          stepNumber: 1,
                          title: 'Verify Location',
                          subtitle: viewModel.isLocationVerified
                              ? viewModel.currentAddress ?? 'Location verified'
                              : 'We need to confirm where you\'re checking in from',
                          isCompleted: viewModel.isLocationVerified,
                          isLoading: viewModel.isVerifyingLocation,
                          isEnabled: !viewModel.isLocationVerified &&
                              !viewModel.isBusy,
                          icon: Icons.location_on,
                          onTap: viewModel.verifyLocation,
                        ),
                        const SizedBox(height: 12),

                        // Step 2: Take Selfie
                        _buildCheckInStep(
                          stepNumber: 2,
                          title: 'Take Selfie',
                          subtitle: viewModel.isFaceVerified
                              ? 'Face verified ✓'
                              : 'Camera only - no gallery uploads. Face must be visible.',
                          isCompleted: viewModel.isFaceVerified,
                          isLoading: viewModel.isCapturing ||
                              viewModel.isVerifyingFace,
                          isEnabled: viewModel.isLocationVerified &&
                              !viewModel.isFaceVerified &&
                              !viewModel.isBusy,
                          icon: Icons.face,
                          onTap: viewModel.capturePhoto,
                        ),

                        // Show captured photo preview
                        if (viewModel.capturedPhotoPath != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.green.shade200, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(viewModel.capturedPhotoPath!),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check,
                                              color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Face Verified',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Late check-in warning banner
                        if (viewModel.isLateCheckIn &&
                            !viewModel.hasCheckedInToday) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You are ${viewModel.minutesLate} minutes late. A reason will be required.',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Step 3: Complete Check-in Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (viewModel.isLocationVerified &&
                                    viewModel.isFaceVerified &&
                                    !viewModel.isBusy)
                                ? () async {
                                    // If late, show reason dialog first
                                    if (viewModel.isLateCheckIn) {
                                      final reason =
                                          await _showLateReasonDialog(context);
                                      if (reason != null && reason.isNotEmpty) {
                                        viewModel.performCheckIn(
                                            lateReason: reason);
                                      }
                                    } else {
                                      viewModel.performCheckIn();
                                    }
                                  }
                                : null,
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
                                        color: (viewModel.isLocationVerified &&
                                                viewModel.isFaceVerified)
                                            ? Colors.white
                                            : Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        viewModel.isLateCheckIn
                                            ? 'Check-in Late (${viewModel.minutesLate}min)'
                                            : 'Complete Check-in',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color:
                                              (viewModel.isLocationVerified &&
                                                      viewModel.isFaceVerified)
                                                  ? Colors.white
                                                  : Colors.grey.shade500,
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
                            onPressed: viewModel.isBusy
                                ? null
                                : viewModel.performRemoteCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isVeryLate
                                  ? Colors.red
                                  : (isLateWarning
                                      ? Colors.orange
                                      : kcPrimaryColor),
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
                                        'Check In (Remote)',
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
                              backgroundColor: Colors.orange,
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

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 12),

            if (viewModel.recentActivity.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kcBorderColor),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 40,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No activity yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your check-in history will appear here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.recentActivity.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildActivityItem(viewModel.recentActivity[index]);
                },
              ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AttendanceHistoryView(),
                    ),
                  );
                },
                child: const Text(
                  'View full history',
                  style: TextStyle(
                    color: kcPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AttendanceViewModel viewModel) {
    final today = viewModel.todayAttendance;
    final status = today?['status'] as String? ?? 'present';
    final isLate = status.toLowerCase() == 'late';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLate ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLate ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLate ? Colors.orange.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLate ? Icons.access_time : Icons.check_circle,
              color: isLate ? Colors.orange.shade700 : Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLate ? 'Checked in late' : 'Checked in on time',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        isLate ? Colors.orange.shade800 : Colors.green.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  viewModel.hasCheckedOutToday
                      ? 'Day completed'
                      : 'Currently at work',
                  style: TextStyle(
                    color:
                        isLate ? Colors.orange.shade600 : Colors.green.shade600,
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
              status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: isLate ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AttendanceRecord record) {
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
                    const Text(
                      'Check In',
                      style: TextStyle(
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
                  '${record.time} • ${record.date}',
                  style: const TextStyle(
                    color: kcTextMutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (record.location != null || record.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: kcTextMutedColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          // Priority: Address -> Location -> Empty
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
                    maxLines: 2,
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
  Future<String?> _showLateReasonDialog(BuildContext context) async {
    final TextEditingController reasonController = TextEditingController();
    String? selectedReason;

    final predefinedReasons = [
      'Traffic congestion',
      'Public transport delay',
      'Family emergency',
      'Health issue',
      'Weather conditions',
      'Other',
    ];

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

                // Quick select reasons
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
                            color:
                                isSelected ? kcPrimaryColor : kcTextMutedColor,
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
                if (selectedReason == 'Other')
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
