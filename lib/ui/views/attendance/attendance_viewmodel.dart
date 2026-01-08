import 'dart:async';
import 'dart:io';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class AttendanceRecord {
  final String id;
  final String date;
  final String time;
  final String status; // present, late, absent
  final String? location;
  final String? address;
  final String? photoUrl;
  final bool hasCheckedOut;
  final String? checkOutTime;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    this.location,
    this.address,
    this.photoUrl,
    this.hasCheckedOut = false,
    this.checkOutTime,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final checkIn = map['check_in'] as String?;
    final checkOut = map['check_out'] as String?;

    String formattedTime = '--:--';
    if (checkIn != null) {
      try {
        final dateTime = DateTime.parse(checkIn);
        formattedTime =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    String formattedCheckOutTime = '';
    if (checkOut != null) {
      try {
        final dateTime = DateTime.parse(checkOut);
        formattedCheckOutTime =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    String formattedDate = 'Unknown';
    if (map['date'] != null) {
      try {
        final date = DateTime.parse(map['date'] as String);
        final now = DateTime.now();
        if (date.day == now.day &&
            date.month == now.month &&
            date.year == now.year) {
          formattedDate = 'Today';
        } else if (date.day == now.day - 1 &&
            date.month == now.month &&
            date.year == now.year) {
          formattedDate = 'Yesterday';
        } else {
          formattedDate =
              '${_weekdayName(date.weekday)}, ${date.day} ${_monthName(date.month)}';
        }
      } catch (_) {}
    }

    return AttendanceRecord(
      id: map['id']?.toString() ?? '',
      date: formattedDate,
      time: formattedTime,
      status: map['status'] as String? ?? 'unknown',
      location: map['location'] as String?,
      address: map['address'] as String?,
      photoUrl: map['photo_url'] as String?,
      hasCheckedOut: checkOut != null,
      checkOutTime: formattedCheckOutTime,
    );
  }

  static String _weekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  bool get isLate => status.toLowerCase() == 'late';
  bool get isPresent => status.toLowerCase() == 'present';
  bool get isAbsent => status.toLowerCase() == 'absent';
}

class AttendanceViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  final _cacheService = locator<CacheService>();
  final _imagePicker = ImagePicker();
  final _deviceInfo = DeviceInfoPlugin();

  // State
  bool _hasCheckedInToday = false;
  bool _hasCheckedOutToday = false;
  bool _isCapturing = false;
  bool _isVerifyingLocation = false;
  bool _isLocationVerified = false;
  bool _isVerifyingFace = false;
  bool _isFaceVerified = false;
  String? _capturedPhotoPath;
  Position? _currentPosition;
  String? _currentAddress;
  String? _errorMessage;
  String? _statusMessage;
  String? _lateReason;

  List<AttendanceRecord> _recentActivity = [];
  Map<String, dynamic>? _todayAttendance;

  // Getters
  bool get hasCheckedInToday => _hasCheckedInToday;
  bool get hasCheckedOutToday => _hasCheckedOutToday;
  bool get isCapturing => _isCapturing;
  bool get isVerifyingLocation => _isVerifyingLocation;
  bool get isLocationVerified => _isLocationVerified;
  bool get isVerifyingFace => _isVerifyingFace;
  bool get isFaceVerified => _isFaceVerified;
  String? get capturedPhotoPath => _capturedPhotoPath;
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  String? get lateReason => _lateReason;
  List<AttendanceRecord> get recentActivity => _recentActivity;
  Map<String, dynamic>? get todayAttendance => _todayAttendance;

  bool get canCheckIn => !_hasCheckedInToday && !isBusy;
  bool get canCheckOut => _hasCheckedInToday && !_hasCheckedOutToday && !isBusy;
  bool get canCapturePhoto => _isLocationVerified && !_isCapturing;

  /// Returns true if current time is past 9:00 AM (considered late)
  bool get isLateCheckIn {
    final now = DateTime.now();
    return now.hour >= 9;
  }

  /// Returns how many minutes late the check-in would be
  int get minutesLate {
    final now = DateTime.now();
    final deadline = DateTime(now.year, now.month, now.day, 9, 0); // 9:00 AM
    if (now.isAfter(deadline)) {
      return now.difference(deadline).inMinutes;
    }
    return 0;
  }

  void setLateReason(String? reason) {
    _lateReason = reason;
    rebuildUi();
  }

  Future<void> initialize() async {
    setBusy(true);
    try {
      // 1. Load cached data first for instant display
      await _loadCachedData();

      // 2. Fetch fresh data in background
      await _loadTodayStatus();
      await _loadRecentActivity();
    } finally {
      setBusy(false);
    }
  }

  /// Load cached attendance data for instant display
  Future<void> _loadCachedData() async {
    try {
      // Load cached today's attendance
      final cachedToday = await _cacheService.getCachedTodayAttendance();
      if (cachedToday != null) {
        _todayAttendance = cachedToday;
        _hasCheckedInToday = cachedToday['checked_in'] == true;
        _hasCheckedOutToday = cachedToday['checked_out'] == true;
        rebuildUi();
      }

      // Load cached attendance history
      final cachedHistory = await _cacheService.getCachedAttendanceHistory();
      if (cachedHistory != null && cachedHistory.isNotEmpty) {
        _recentActivity = cachedHistory
            .take(5)
            .map((e) => AttendanceRecord.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        rebuildUi();
      }
    } catch (e) {
      print('Error loading cached attendance data: $e');
    }
  }

  Future<void> _loadTodayStatus() async {
    try {
      _todayAttendance = await _backendService.getTodayAttendance();
      if (_todayAttendance != null) {
        _hasCheckedInToday = _todayAttendance!['checked_in'] == true;
        _hasCheckedOutToday = _todayAttendance!['checked_out'] == true;

        // Cache the attendance status
        await _cacheService.cacheTodayAttendance(_todayAttendance);
      }
      rebuildUi();
    } catch (e) {
      print('Error loading today status: $e');
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final history = await _backendService.getAttendanceHistory();
      _recentActivity = history
          .take(5) // Last 5 records
          .map((e) => AttendanceRecord.fromMap(e))
          .toList();

      // Cache the history
      await _cacheService.cacheAttendanceHistory(history);

      rebuildUi();
    } catch (e) {
      print('Error loading recent activity: $e');
    }
  }

  /// Request location permission and get current position
  Future<bool> _getLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. Please enable them.';
        rebuildUi();
        return false;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage =
              'Location permission denied. Please grant location access.';
          rebuildUi();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage =
            'Location permission permanently denied. Please enable in Settings.';
        rebuildUi();
        return false;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Reverse geocode to get address
      try {
        final placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _currentAddress =
              '${place.street}, ${place.locality}, ${place.country}';
        }
      } catch (e) {
        print('Error getting address: $e');
        _currentAddress = 'Location acquired';
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error getting location: $e';
      rebuildUi();
      return false;
    }
  }

  /// Step 1: Verify location FIRST before allowing camera
  /// This must be called before capturePhoto() will work
  Future<bool> verifyLocation() async {
    if (_isLocationVerified) return true;

    _isVerifyingLocation = true;
    _errorMessage = null;
    _statusMessage = 'Verifying your location...';
    rebuildUi();

    try {
      final success = await _getLocation();
      if (success) {
        _isLocationVerified = true;
        _statusMessage = 'Location verified: ${_currentAddress ?? 'Unknown'}';
        print('📍 Location verified: $_currentAddress');
      } else {
        _statusMessage = null;
      }
      _isVerifyingLocation = false;
      rebuildUi();
      return success;
    } catch (e) {
      _isVerifyingLocation = false;
      _errorMessage = 'Failed to verify location: $e';
      _statusMessage = null;
      rebuildUi();
      return false;
    }
  }

  /// Step 2: Capture selfie using camera (only works after location is verified)
  /// Also performs facial recognition to verify a face is present
  Future<bool> capturePhoto() async {
    // Location must be verified first
    if (!_isLocationVerified) {
      _errorMessage = 'Please verify your location first before taking a photo';
      rebuildUi();
      return false;
    }

    _isCapturing = true;
    _errorMessage = null;
    _statusMessage = 'Opening camera...';
    rebuildUi();

    try {
      // Use camera only - no gallery uploads allowed
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera, // Camera ONLY - no gallery
        preferredCameraDevice: CameraDevice.front, // Front camera for selfie
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo == null) {
        _isCapturing = false;
        _errorMessage = 'Photo capture cancelled';
        _statusMessage = null;
        rebuildUi();
        return false;
      }

      _capturedPhotoPath = photo.path;
      _statusMessage = 'Verifying face...';
      rebuildUi();

      // Step 3: Verify face is present in the photo
      final faceVerified = await _verifyFace(photo.path);

      if (!faceVerified) {
        _capturedPhotoPath = null;
        _isCapturing = false;
        _errorMessage =
            'No face detected. Please take a clear selfie showing your face.';
        _statusMessage = null;
        rebuildUi();
        return false;
      }

      _isFaceVerified = true;
      _isCapturing = false;
      _statusMessage = 'Face verified ✓';
      rebuildUi();
      return true;
    } catch (e) {
      _isCapturing = false;
      _capturedPhotoPath = null;
      _errorMessage = 'Error capturing photo: $e';
      _statusMessage = null;
      rebuildUi();
      return false;
    }
  }

  /// Verify that a face is present in the captured photo using ML Kit
  Future<bool> _verifyFace(String imagePath) async {
    _isVerifyingFace = true;
    rebuildUi();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableClassification: true,
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      _isVerifyingFace = false;

      if (faces.isEmpty) {
        print('❌ No face detected in photo');
        return false;
      }

      // Check if at least one face is detected with reasonable confidence
      final mainFace = faces.first;
      print('✅ Face detected! Landmarks: ${mainFace.landmarks.length}');

      // Optional: Check if eyes are open (anti-spoofing)
      if (mainFace.leftEyeOpenProbability != null &&
          mainFace.rightEyeOpenProbability != null) {
        final leftEyeOpen = mainFace.leftEyeOpenProbability! > 0.3;
        final rightEyeOpen = mainFace.rightEyeOpenProbability! > 0.3;

        if (!leftEyeOpen || !rightEyeOpen) {
          print('⚠️ Eyes appear closed, but allowing...');
          // We still allow this but could be stricter
        }
      }

      return true;
    } catch (e) {
      print('Error during face detection: $e');
      _isVerifyingFace = false;
      // If face detection fails, still allow check-in but log the issue
      // This prevents blocking users if ML Kit has issues
      return true;
    }
  }

  /// Full check-in flow: location verified -> camera with face detection -> submit
  /// verifyLocation() and capturePhoto() must be called before this
  /// If checking in late (after 9 AM), lateReason should be provided
  Future<bool> performCheckIn({String? lateReason}) async {
    if (_hasCheckedInToday) {
      _errorMessage = 'Already checked in today';
      rebuildUi();
      return false;
    }

    // Ensure location is verified
    if (!_isLocationVerified) {
      _errorMessage = 'Please verify your location first';
      rebuildUi();
      return false;
    }

    // Ensure face is verified
    if (!_isFaceVerified || _capturedPhotoPath == null) {
      _errorMessage = 'Please take a selfie first';
      rebuildUi();
      return false;
    }

    // If late check-in and no reason provided, require it
    if (isLateCheckIn && (lateReason == null || lateReason.isEmpty)) {
      // Store that we need a reason - the UI will handle prompting
      _errorMessage = 'Please provide a reason for checking in late';
      rebuildUi();
      return false;
    }

    setBusy(true);
    _errorMessage = null;
    _statusMessage = 'Submitting check-in...';
    rebuildUi();

    try {
      // Step 1: Get device info
      String deviceInfo = '';
      try {
        if (Platform.isAndroid) {
          final info = await _deviceInfo.androidInfo;
          deviceInfo =
              '${info.manufacturer} ${info.model} (Android ${info.version.release})';
        } else if (Platform.isIOS) {
          final info = await _deviceInfo.iosInfo;
          deviceInfo = '${info.name} (iOS ${info.systemVersion})';
        }
      } catch (_) {
        deviceInfo = 'Unknown device';
      }

      // Step 2: Upload photo to storage service
      String? photoUrl;
      if (_capturedPhotoPath != null) {
        _statusMessage = 'Uploading photo...';
        rebuildUi();

        try {
          // Check if storage is available
          final storageAvailable = await _backendService.isStorageAvailable();
          if (storageAvailable) {
            final uploadResult =
                await _backendService.uploadCheckInPhoto(_capturedPhotoPath!);
            photoUrl = uploadResult['url'] as String?;
            print('📸 Photo uploaded: $photoUrl');
          } else {
            print('⚠️ Storage not available, continuing without photo');
          }
        } catch (e) {
          print('⚠️ Photo upload failed: $e (continuing without photo)');
        }
      }

      // Build note with late reason if applicable
      String? note;
      if (isLateCheckIn && lateReason != null) {
        note = 'Late check-in (${minutesLate}min): $lateReason';
        print('📝 Late check-in note: $note');
      }

      // Step 3: Submit check-in
      _statusMessage = 'Completing check-in...';
      rebuildUi();

      final result = await _backendService.checkIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracy: _currentPosition!.accuracy,
        address: _currentAddress,
        photoUrl: photoUrl,
        deviceInfo: deviceInfo,
        note: note,
      );

      if (result != null) {
        _hasCheckedInToday = true;
        _todayAttendance = result;
        _capturedPhotoPath = null;
        _lateReason = null;
        _statusMessage = isLateCheckIn
            ? 'Check-in successful (${minutesLate}min late)'
            : 'Check-in successful! ✓';

        // Cache the attendance status
        await _cacheService.cacheTodayAttendance(result);

        await _loadRecentActivity();
        setBusy(false);

        // Reset verification state for tomorrow
        _isLocationVerified = false;
        _isFaceVerified = false;

        rebuildUi();
        return true;
      } else {
        _errorMessage = 'Check-in failed. Please try again.';
        _statusMessage = null;
        setBusy(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during check-in: $e';
      _statusMessage = null;
      setBusy(false);
      return false;
    }
  }

  /// Reset the check-in flow to start over
  void resetCheckInFlow() {
    _isLocationVerified = false;
    _isFaceVerified = false;
    _capturedPhotoPath = null;
    _currentPosition = null;
    _currentAddress = null;
    _errorMessage = null;
    _statusMessage = null;
    _lateReason = null;
    rebuildUi();
  }

  /// Remote check-in flow: simplified without camera (for remote days)
  /// Still gets location for tracking but doesn't require being at office
  Future<bool> performRemoteCheckIn() async {
    if (_hasCheckedInToday) {
      _errorMessage = 'Already checked in today';
      rebuildUi();
      return false;
    }

    setBusy(true);
    _errorMessage = null;

    try {
      // Step 1: Get location (optional for remote, but good for tracking)
      double latitude = 0;
      double longitude = 0;
      double accuracy = 0;
      String address = 'Remote Work';

      try {
        // Try to get location, but don't fail if we can't
        final locationOk = await _getLocation();
        if (locationOk && _currentPosition != null) {
          latitude = _currentPosition!.latitude;
          longitude = _currentPosition!.longitude;
          accuracy = _currentPosition!.accuracy;
          address = _currentAddress ?? 'Remote Work';
        }
      } catch (e) {
        print('Location not available for remote check-in: $e');
        // Continue without location - it's optional for remote
      }

      // Step 2: Get device info
      String deviceInfo = '';
      try {
        if (Platform.isAndroid) {
          final info = await _deviceInfo.androidInfo;
          deviceInfo =
              '${info.manufacturer} ${info.model} (Android ${info.version.release})';
        } else if (Platform.isIOS) {
          final info = await _deviceInfo.iosInfo;
          deviceInfo = '${info.name} (iOS ${info.systemVersion})';
        }
      } catch (_) {
        deviceInfo = 'Unknown device';
      }

      // Step 3: Submit remote check-in
      final result = await _backendService.checkIn(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        address: address,
        photoUrl: null, // No photo for remote
        deviceInfo: deviceInfo,
        isRemote: true,
      );

      if (result != null) {
        _hasCheckedInToday = true;
        _todayAttendance = result;

        // Cache the attendance status
        await _cacheService.cacheTodayAttendance(result);

        await _loadRecentActivity();
        setBusy(false);
        return true;
      } else {
        _errorMessage = 'Remote check-in failed. Please try again.';
        setBusy(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during remote check-in: $e';
      setBusy(false);
      return false;
    }
  }

  /// Check out (simpler flow, no photo)
  Future<bool> performCheckOut() async {
    if (!_hasCheckedInToday) {
      _errorMessage = 'You need to check in first';
      rebuildUi();
      return false;
    }

    if (_hasCheckedOutToday) {
      _errorMessage = 'Already checked out today';
      rebuildUi();
      return false;
    }

    setBusy(true);
    _errorMessage = null;

    try {
      final result = await _backendService.checkOut();
      if (result != null) {
        _hasCheckedOutToday = true;
        await _loadRecentActivity();
        setBusy(false);
        return true;
      } else {
        _errorMessage = 'Check-out failed. Please try again.';
        setBusy(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during check-out: $e';
      setBusy(false);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    rebuildUi();
  }

  void clearCapturedPhoto() {
    _capturedPhotoPath = null;
    rebuildUi();
  }
}
