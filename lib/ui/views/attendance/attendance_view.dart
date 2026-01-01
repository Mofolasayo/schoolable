import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'attendance_viewmodel.dart';

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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
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
                  Text(
                    viewModel.hasCheckedInToday
                        ? (viewModel.hasCheckedOutToday
                            ? 'You\'re all set for today!'
                            : 'Ready to check out?')
                        : 'Ready to check in?',
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
                        : 'Capture a quick selfie and confirm your location.',
                    style: const TextStyle(
                      color: kcTextMutedColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Camera preview area
                  if (!viewModel.hasCheckedInToday) ...[
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kcBorderColor),
                        color: viewModel.capturedPhotoPath != null
                            ? Colors.black
                            : kcPrimaryColor.withOpacity(0.03),
                      ),
                      child: viewModel.capturedPhotoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
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
                                    child: GestureDetector(
                                      onTap: viewModel.clearCapturedPhoto,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: viewModel.isCapturing
                                  ? const CupertinoActivityIndicator()
                                  : const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.camera_alt_outlined,
                                            color: kcTextMutedColor, size: 32),
                                        SizedBox(height: 8),
                                        Text(
                                          'Camera preview',
                                          style: TextStyle(
                                            color: kcTextMutedColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action button
                  if (!viewModel.hasCheckedOutToday)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: viewModel.isBusy
                            ? null
                            : (viewModel.hasCheckedInToday
                                ? viewModel.performCheckOut
                                : viewModel.performCheckIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: viewModel.hasCheckedInToday
                              ? Colors.orange
                              : kcPrimaryColor,
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
                            : Text(
                                viewModel.hasCheckedInToday
                                    ? 'Check Out'
                                    : 'Start Camera',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
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
                  // TODO: Navigate to full history page
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
                          record.location ?? record.address ?? '',
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
