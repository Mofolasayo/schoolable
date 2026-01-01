import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geocoding/geocoding.dart';

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
  final _imagePicker = ImagePicker();
  final _deviceInfo = DeviceInfoPlugin();

  // State
  bool _hasCheckedInToday = false;
  bool _hasCheckedOutToday = false;
  bool _isCapturing = false;
  String? _capturedPhotoPath;
  Position? _currentPosition;
  String? _currentAddress;
  String? _errorMessage;

  List<AttendanceRecord> _recentActivity = [];
  Map<String, dynamic>? _todayAttendance;

  // Getters
  bool get hasCheckedInToday => _hasCheckedInToday;
  bool get hasCheckedOutToday => _hasCheckedOutToday;
  bool get isCapturing => _isCapturing;
  String? get capturedPhotoPath => _capturedPhotoPath;
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get errorMessage => _errorMessage;
  List<AttendanceRecord> get recentActivity => _recentActivity;
  Map<String, dynamic>? get todayAttendance => _todayAttendance;

  bool get canCheckIn => !_hasCheckedInToday && !isBusy;
  bool get canCheckOut => _hasCheckedInToday && !_hasCheckedOutToday && !isBusy;

  Future<void> initialize() async {
    await _loadTodayStatus();
    await _loadRecentActivity();
  }

  Future<void> _loadTodayStatus() async {
    try {
      _todayAttendance = await _backendService.getTodayAttendance();
      if (_todayAttendance != null) {
        _hasCheckedInToday = _todayAttendance!['checked_in'] == true;
        _hasCheckedOutToday = _todayAttendance!['checked_out'] == true;
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

  /// Capture selfie using camera
  Future<bool> capturePhoto() async {
    _isCapturing = true;
    _errorMessage = null;
    rebuildUi();

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo == null) {
        _isCapturing = false;
        _errorMessage = 'Photo capture cancelled';
        rebuildUi();
        return false;
      }

      _capturedPhotoPath = photo.path;
      _isCapturing = false;
      rebuildUi();
      return true;
    } catch (e) {
      _isCapturing = false;
      _errorMessage = 'Error capturing photo: $e';
      rebuildUi();
      return false;
    }
  }

  /// Full check-in flow: camera -> location -> upload photo -> submit
  Future<bool> performCheckIn() async {
    if (_hasCheckedInToday) {
      _errorMessage = 'Already checked in today';
      rebuildUi();
      return false;
    }

    setBusy(true);
    _errorMessage = null;

    try {
      // Step 1: Capture photo
      final photoOk = await capturePhoto();
      if (!photoOk) {
        setBusy(false);
        return false;
      }

      // Step 2: Get location
      final locationOk = await _getLocation();
      if (!locationOk) {
        setBusy(false);
        return false;
      }

      // Step 3: Get device info
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

      // Step 4: Upload photo to storage service
      String? photoUrl;
      if (_capturedPhotoPath != null) {
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

      // Step 5: Submit check-in
      final result = await _backendService.checkIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracy: _currentPosition!.accuracy,
        address: _currentAddress,
        photoUrl: photoUrl,
        deviceInfo: deviceInfo,
      );

      if (result != null) {
        _hasCheckedInToday = true;
        _capturedPhotoPath = null;
        await _loadRecentActivity();
        setBusy(false);
        return true;
      } else {
        _errorMessage = 'Check-in failed. Please try again.';
        setBusy(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during check-in: $e';
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
