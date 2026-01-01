import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';

/// ViewModel for Growth & Learning page
/// Handles certificate uploads and tracking
class GrowthViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();

  File? _selectedFile;
  File? get selectedFile => _selectedFile;

  String get selectedFileName =>
      _selectedFile?.path.split('/').last ?? 'certificate.jpg';

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  List<Map<String, dynamic>> _certificates = [];
  List<Map<String, dynamic>> get certificates => _certificates;

  bool _currentQuarterSubmitted = false;
  bool get currentQuarterSubmitted => _currentQuarterSubmitted;

  String get currentQuarter {
    final month = DateTime.now().month;
    if (month <= 3) return 'Q1';
    if (month <= 6) return 'Q2';
    if (month <= 9) return 'Q3';
    return 'Q4';
  }

  GrowthViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    setBusy(true);
    await fetchCertificates();
    setBusy(false);
  }

  /// Fetch user's certificates from backend
  Future<void> fetchCertificates() async {
    try {
      _certificates = await _backendService.getTrainingRecords();

      // Check if submitted for this quarter
      _currentQuarterSubmitted = _certificates.any((c) =>
          c['quarter'] == currentQuarter &&
          c['year'] == DateTime.now().year &&
          c['status'] != 'rejected');
    } catch (e) {
      debugPrint('Error fetching certificates: $e');
      _certificates = [];
      _currentQuarterSubmitted = false;
    }
    notifyListeners();
  }

  /// Pick image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedFile = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  /// Clear selected file
  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  /// Upload certificate to backend
  Future<void> uploadCertificate() async {
    if (_selectedFile == null || nameController.text.isEmpty) {
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      await _backendService.uploadCertificate(
        _selectedFile!.path,
        nameController.text,
        currentQuarter,
        DateTime.now().year,
      );

      // Success
      _selectedFile = null;
      nameController.clear();
      _currentQuarterSubmitted = true;
      await fetchCertificates();
    } catch (e) {
      debugPrint('Error uploading certificate: $e');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
