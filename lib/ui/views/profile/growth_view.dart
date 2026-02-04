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
        backgroundColor: kcBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                                      padding: EdgeInsets.only(left: 4),

                   // decoration: _cardDecoration(),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Training certificates',
                          style: TextStyle(
                            color: kcTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Upload one per quarter for the Growth pillar.',
                          style: TextStyle(
                            color: kcTextMutedColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Certificates contribute 25% to your Aura Score.',
                          style: TextStyle(
                            color: kcTextMutedColor,
                            fontSize: 12,
                            height: 1.4,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kcTextColor,
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
    final accentColor = hasSubmitted ? kcTealColor : kcAmberColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentQuarter ${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSubmitted
                      ? 'Requirement met for this quarter'
                      : 'Pending certificate submission',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kcTextMutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            hasSubmitted ? 'Complete' : 'Pending',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context, GrowthViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Selected file preview
          if (viewModel.selectedFile != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kcBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kcBorderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: kcTextMutedColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
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
                            color: kcTextMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: kcTextMutedColor),
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
              labelText: 'Certificate name',
              hintText: 'Enter certificate name',
              hintStyle: TextStyle(
                  color: kcTextMutedColor.withOpacity(0.6), fontSize: 14),
              filled: true,
              fillColor: kcBackgroundColor,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Upload Button
          if (viewModel.selectedFile == null)
            GestureDetector(
              onTap: () => _showUploadOptions(context, viewModel),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kcBorderColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      color: kcTextMutedColor,
                      size: 26,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to upload',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kcTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PDF, JPG or PNG (Max 5MB)',
                      style: TextStyle(
                        fontSize: 11,
                        color: kcTextMutedColor.withOpacity(0.8),
                      ),
                    ),
                  ],
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              color: kcTextMutedColor.withOpacity(0.6),
              size: 28,
            ),
            const SizedBox(height: 12),
            const Text(
              'No certificates yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your uploaded documents will appear here',
              style: TextStyle(
                fontSize: 12,
                color: kcTextMutedColor,
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
          decoration: _cardDecoration(),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const Icon(
              Icons.description_outlined,
              color: kcTextMutedColor,
              size: 20,
            ),
            title: Text(
              cert['name'] ?? 'Certificate',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: kcTextColor,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${cert['quarter']} ${cert['year']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: kcTextMutedColor,
                ),
              ),
            ),
            trailing: Text(
              _formatStatus(status.toString()),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(status),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: kcSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kcBorderColor),
    );
  }

  String _formatStatus(String status) {
    if (status.trim().isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
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
          color: kcSurfaceColor,
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
              'Upload certificate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                viewModel.pickImage(ImageSource.gallery);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kcBorderColor),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.photo_library_outlined,
                        color: kcTextMutedColor),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose from gallery',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kcBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kcBorderColor),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, color: kcTextMutedColor),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take a photo',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
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
