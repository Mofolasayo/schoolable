import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';

class ComplianceSubmissionView extends StatefulWidget {
  final ComplianceItem item;

  const ComplianceSubmissionView({Key? key, required this.item})
      : super(key: key);

  @override
  State<ComplianceSubmissionView> createState() =>
      _ComplianceSubmissionViewState();
}

class _ComplianceSubmissionViewState extends State<ComplianceSubmissionView> {
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isAccepted = false; // For policy acknowledgement

  final ImagePicker _picker = ImagePicker();
  final BackendApiService _backendService = locator<BackendApiService>();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  Future<void> _submit() async {
    if (widget.item.type == 'upload' && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document first')),
      );
      return;
    }

    if (widget.item.type == 'policy' && !_isAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please acknowledge the policy to continue')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      bool success = false;

      if (widget.item.type == 'policy') {
        // Policy acknowledgement
        success = await _backendService.acknowledgePolicy(widget.item.id);
      } else if (widget.item.type == 'upload' && _selectedFile != null) {
        // Document upload
        success = await _backendService.submitComplianceDocument(
          policyId: widget.item.id,
          filePath: _selectedFile!.path,
          fileName: _selectedFile!.path.split('/').last,
        );
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          widget.item.status = 'complied';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submitted successfully!'),
              backgroundColor: kcTealColor,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submission failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcBackgroundColor, // Use app background color
      appBar: AppBar(
        title: const Text('Compliance Submission',
            style: TextStyle(
                color: kcTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kcTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_late_outlined,
                            size: 14, color: kcPrimaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'REQUIRED ACTION',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kcPrimaryColor,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kcTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: kcTextMutedColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: kcBorderColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: kcAmberColor),
                      const SizedBox(width: 8),
                      Text(
                        'Due by ${widget.item.deadline.toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kcAmberColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Section
            Text(
              widget.item.type == 'upload'
                  ? 'Document Upload'
                  : 'Acknowledgement',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kcTextColor,
              ),
            ),
            const SizedBox(height: 12),

            if (widget.item.type == 'upload')
              _buildUploadSection()
            else
              _buildAcknowledgementSection(),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: kcPrimaryColor.withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        widget.item.type == 'upload'
                            ? 'Submit Document'
                            : 'Acknowledge & Sign',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Please upload a clear image of the required document.',
          style: TextStyle(fontSize: 14, color: kcTextMutedColor),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedFile != null ? kcTealColor : kcBorderColor,
                width: 2,
              ),
            ),
            child: _selectedFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _selectedFile!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child:
                                Icon(Icons.edit, color: Colors.white, size: 32),
                          ),
                        )
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kcPrimaryColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_rounded,
                            size: 32, color: kcPrimaryColor),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to upload document',
                        style: TextStyle(
                          color: kcTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Supports JPG, PNG (Max 5MB)',
                        style: TextStyle(
                          color: kcTextMutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcknowledgementSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _isAccepted ? kcPrimaryColor : kcBorderColor,
            width: _isAccepted ? 1.5 : 1),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isAccepted = !_isAccepted;
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _isAccepted,
                onChanged: (v) {
                  setState(() {
                    _isAccepted = v ?? false;
                  });
                },
                activeColor: kcPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'I certify that I have read and understood the policy outlined above, and I agree to comply with its terms.',
                style: TextStyle(
                  fontSize: 14,
                  color: kcTextColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
