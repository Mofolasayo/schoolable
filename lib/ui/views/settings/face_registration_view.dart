import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:schoolable/services/logging_service.dart';

/// View for registering/updating reference face for check-in verification
class FaceRegistrationView extends StackedView<FaceRegistrationViewModel> {
  const FaceRegistrationView({Key? key}) : super(key: key);

  @override
  FaceRegistrationViewModel viewModelBuilder(BuildContext context) =>
      FaceRegistrationViewModel();

  @override
  void onViewModelReady(FaceRegistrationViewModel viewModel) {
    viewModel.initialize();
  }

  @override
  Widget builder(BuildContext context, FaceRegistrationViewModel viewModel,
      Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Face Registration',
          style: TextStyle(
            color: kcTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kcTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header illustration
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kcPrimaryColor.withValues(alpha: 0.1),
                    Colors.purple.withValues(alpha: 0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.face_retouching_natural,
                    size: 64,
                    color: kcPrimaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Register Your Face',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kcTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your face will be used to verify your identity during check-in. This helps prevent proxy attendance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: kcTextMutedColor.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current registered face
            if (viewModel.hasRegisteredFace) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Face Registered',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: kcTextColor,
                                ),
                              ),
                              Text(
                                'Your face is registered for check-in verification',
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
                    if (viewModel.registeredFaceUrl != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          viewModel.registeredFaceUrl!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            width: 150,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person,
                                size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Registered: ${viewModel.registeredDate ?? 'Unknown'}',
                      style: const TextStyle(
                          fontSize: 12, color: kcTextMutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Capture preview
            if (viewModel.capturedPhotoPath != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kcBorderColor),
                ),
                child: Column(
                  children: [
                    const Text(
                      'New Photo Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: kcTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(viewModel.capturedPhotoPath!),
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.isFaceDetected) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Face detected successfully',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning,
                              color: Colors.orange.shade600, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'No face detected - try again',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Status message
            if (viewModel.statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.blue.shade600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      viewModel.statusMessage!,
                      style:
                          TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kcBorderColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tips for a good photo:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: kcTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTip(
                      Icons.light_mode, 'Good lighting - face clearly visible'),
                  _buildTip(Icons.face, 'Face the camera directly'),
                  _buildTip(Icons.visibility_off,
                      'Remove sunglasses or obstructions'),
                  _buildTip(
                      Icons.sentiment_neutral, 'Neutral expression works best'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.isBusy ? null : viewModel.capturePhoto,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: Text(
                  viewModel.capturedPhotoPath != null
                      ? 'Retake Photo'
                      : 'Take Photo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            if (viewModel.capturedPhotoPath != null &&
                viewModel.isFaceDetected) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: viewModel.isBusy ? null : viewModel.registerFace,
                  icon: viewModel.isBusy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check, size: 20),
                  label: Text(
                    viewModel.hasRegisteredFace
                        ? 'Update Face'
                        : 'Register Face',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kcPrimaryColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: kcTextMutedColor),
          ),
        ],
      ),
    );
  }
}

/// ViewModel for Face Registration
class FaceRegistrationViewModel extends BaseViewModel {
  final BackendApiService _backendService = locator<BackendApiService>();
  final CacheService _cacheService = locator<CacheService>();
  final ImagePicker _imagePicker = ImagePicker();

  bool _hasRegisteredFace = false;
  String? _registeredFaceUrl;
  String? _registeredDate;
  String? _capturedPhotoPath;
  bool _isFaceDetected = false;
  String? _errorMessage;
  String? _statusMessage;

  // Getters
  bool get hasRegisteredFace => _hasRegisteredFace;
  String? get registeredFaceUrl => _registeredFaceUrl;
  String? get registeredDate => _registeredDate;
  String? get capturedPhotoPath => _capturedPhotoPath;
  bool get isFaceDetected => _isFaceDetected;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  Future<void> initialize() async {
    await _loadRegisteredFace();
  }

  Future<void> _loadRegisteredFace() async {
    setBusy(true);
    try {
      // Try cache first
      final cached = await _cacheService.getCachedReferenceFace();
      if (cached != null) {
        _hasRegisteredFace = true;
        _registeredFaceUrl = cached['url'];
        _registeredDate = cached['registered_at'];
        rebuildUi();
      }

      // Fetch from backend
      final result = await _backendService.getReferenceFace();
      if (result != null && result['url'] != null) {
        _hasRegisteredFace = true;
        _registeredFaceUrl = result['url'];
        _registeredDate = _formatDate(result['registered_at']);
        await _cacheService.cacheReferenceFace(result);
      }
    } catch (e) {
      AppLogger.log('Error loading registered face: $e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> capturePhoto() async {
    _errorMessage = null;
    _statusMessage = 'Opening camera...';
    rebuildUi();

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo == null) {
        _statusMessage = null;
        rebuildUi();
        return;
      }

      _capturedPhotoPath = photo.path;
      _statusMessage = 'Detecting face...';
      rebuildUi();

      // Detect face
      _isFaceDetected = await _detectFace(photo.path);
      _statusMessage = null;
      rebuildUi();
    } catch (e) {
      _errorMessage = 'Error capturing photo: $e';
      _statusMessage = null;
      rebuildUi();
    }
  }

  Future<bool> _detectFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          minFaceSize: 0.15,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      // For registration, we want exactly one clear face
      if (faces.length == 1) {
        final face = faces.first;
        // Check face quality (should be relatively straight)
        final headEulerY = face.headEulerAngleY ?? 0;
        final headEulerZ = face.headEulerAngleZ ?? 0;

        if (headEulerY.abs() < 30 && headEulerZ.abs() < 15) {
          return true;
        } else {
          _errorMessage = 'Please face the camera more directly';
          return false;
        }
      } else if (faces.isEmpty) {
        _errorMessage = 'No face detected in the photo';
        return false;
      } else {
        _errorMessage = 'Multiple faces detected - only one person allowed';
        return false;
      }
    } catch (e) {
      AppLogger.log('Face detection error: $e');
      return false;
    }
  }

  Future<void> registerFace() async {
    if (_capturedPhotoPath == null || !_isFaceDetected) return;

    setBusy(true);
    _errorMessage = null;
    _statusMessage = 'Uploading photo...';
    rebuildUi();

    try {
      // Upload the face image
      final uploadResult = await _backendService.uploadFile(
        _capturedPhotoPath!,
        'reference_face_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folder: 'reference_faces',
      );

      if (uploadResult == null || uploadResult['url'] == null) {
        throw Exception('Failed to upload photo');
      }

      _statusMessage = 'Registering face...';
      rebuildUi();

      // Register with backend
      final result = await _backendService.registerReferenceFace(
        photoUrl: uploadResult['url'],
      );

      if (result != null) {
        _hasRegisteredFace = true;
        _registeredFaceUrl = uploadResult['url'];
        _registeredDate = _formatDate(DateTime.now().toIso8601String());
        _capturedPhotoPath = null;
        _isFaceDetected = false;
        _statusMessage = null;

        // Cache the result
        await _cacheService.cacheReferenceFace({
          'url': uploadResult['url'],
          'registered_at': DateTime.now().toIso8601String(),
        });

        rebuildUi();
      } else {
        throw Exception('Failed to register face');
      }
    } catch (e) {
      _errorMessage = 'Error registering face: $e';
      _statusMessage = null;
      rebuildUi();
    } finally {
      setBusy(false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, y').format(date);
    } catch (_) {
      return 'Unknown';
    }
  }
}