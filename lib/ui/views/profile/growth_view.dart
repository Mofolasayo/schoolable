import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:image_picker/image_picker.dart';

import 'growth_viewmodel.dart';

/// Growth & Learning page where employees upload training certificates
/// One certificate per quarter is required for the Growth pillar
class GrowthView extends StackedView<GrowthViewModel> {
  const GrowthView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, GrowthViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kcTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Growth & Learning',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: viewModel.isBusy
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Training Certificates',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Upload 1 per quarter for Growth Pillar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Certificates contribute 25% to your Aura Score under the Growth & Learning pillar.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Current Quarter Status
                  _buildQuarterStatus(viewModel),
                  const SizedBox(height: 32),

                  // Upload Section
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Upload Certificate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kcTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUploadSection(context, viewModel),
                  const SizedBox(height: 32),

                  // Previous Certificates
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kcTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (viewModel.certificates.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kcBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kcBorderColor),
                          ),
                          child: Text(
                            '${viewModel.certificates.length} Total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kcTextMutedColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCertificatesList(viewModel),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildQuarterStatus(GrowthViewModel viewModel) {
    final hasSubmitted = viewModel.currentQuarterSubmitted;
    final currentQuarter = viewModel.currentQuarter;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kcBorderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasSubmitted
                    ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                    : [const Color(0xFFF97316), const Color(0xFFFB923C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasSubmitted ? Icons.check_circle_outline : Icons.schedule,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentQuarter ${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSubmitted
                      ? 'Requirement met for this quarter'
                      : 'Pending certificate submission',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasSubmitted
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF97316),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasSubmitted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Complete',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context, GrowthViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kcBorderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selected file preview
          if (viewModel.selectedFile != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Blue 50
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)), // Blue 200
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.selectedFileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ready to submit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: kcTextMutedColor),
                    ),
                    onPressed: viewModel.clearSelectedFile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Certificate Name Input
          TextField(
            controller: viewModel.nameController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: kcBackgroundColor,
              hintText: 'Enter certificate name',
              hintStyle: TextStyle(
                  color: kcTextMutedColor.withOpacity(0.6), fontSize: 14),
              prefixIcon: const Icon(Icons.badge_outlined,
                  color: kcTextMutedColor, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kcPrimaryColor, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          // Upload Button
          if (viewModel.selectedFile == null)
            GestureDetector(
              onTap: () => _showUploadOptions(context, viewModel),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kcBorderColor,
                    style: BorderStyle.none,
                  ),
                ),
                child: CustomPaint(
                  painter: DashedBorderPainter(
                      color: kcTextMutedColor.withOpacity(0.4), strokeWidth: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kcPrimaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: kcPrimaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to upload certificate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kcTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PDF, JPG or PNG (Max 5MB)',
                        style: TextStyle(
                          fontSize: 12,
                          color: kcTextMutedColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Submit Button
          if (viewModel.selectedFile != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    viewModel.isUploading ? null : viewModel.uploadCertificate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: viewModel.isUploading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'Submit Certificate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificatesList(GrowthViewModel viewModel) {
    if (viewModel.certificates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kcBorderColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kcBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                color: kcTextMutedColor.withOpacity(0.5),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No certificates yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your uploaded documents will appear here',
              style: TextStyle(
                fontSize: 13,
                color: kcTextMutedColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.certificates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cert = viewModel.certificates[index];
        final status = cert['status'] ?? 'pending';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kcBorderColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                status == 'approved'
                    ? Icons.verified_rounded
                    : status == 'pending'
                        ? Icons.schedule_rounded
                        : Icons.close_rounded,
                color: _getStatusColor(status),
                size: 22,
              ),
            ),
            title: Text(
              cert['name'] ?? 'Certificate',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: kcTextColor,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    '${cert['quarter']} ${cert['year']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: kcTextMutedColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: kcTextMutedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(Icons.chevron_right,
                color: kcTextMutedColor.withOpacity(0.5)),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF97316);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return kcTextMutedColor;
    }
  }

  void _showUploadOptions(BuildContext context, GrowthViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Certificate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                viewModel.pickImage(ImageSource.gallery);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library_rounded,
                          color: kcPrimaryColor),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose from Gallery',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Select an image from your photos',
                          style:
                              TextStyle(fontSize: 12, color: kcTextMutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                viewModel.pickImage(ImageSource.camera);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: kcPrimaryColor),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take a Photo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Capture a new image now',
                          style:
                              TextStyle(fontSize: 12, color: kcTextMutedColor),
                        ),
                      ],
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

  @override
  GrowthViewModel viewModelBuilder(BuildContext context) => GrowthViewModel();
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final Path dashedPath =
        _dashPath(path, dashArray: CircularIntervalList<double>([10, gap]));
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path path, {required CircularIntervalList<double> dashArray}) {
    final Path dest = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(
              metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircularIntervalList<T> {
  final List<T> _values;
  int _index = 0;

  CircularIntervalList(this._values);

  T get next {
    if (_index >= _values.length) {
      _index = 0;
    }
    return _values[_index++];
  }
}
