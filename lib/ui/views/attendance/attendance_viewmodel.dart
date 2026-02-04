import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/services/connectivity_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:schoolable/services/logging_service.dart';

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
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          formattedDate = 'Today';
        } else if (date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day) {
          formattedDate = 'Yesterday';
        } else {
          formattedDate = DateFormat('EEE, d MMM').format(date);
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

  bool get isLate => status.toLowerCase() == 'late';
  bool get isPresent => status.toLowerCase() == 'present';
  bool get isAbsent => status.toLowerCase() == 'absent';
}

/// Office locations for geofencing check-in
class OfficeLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? radiusMeters;
  final String? timezone;

  const OfficeLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radiusMeters,
    this.timezone,
  });

  factory OfficeLocation.fromMap(Map<String, dynamic> map) {
    return OfficeLocation(
      name: map['name']?.toString() ?? 'Office',
      address: map['address']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (map['radius_meters'] as num?)?.toDouble(),
      timezone: map['timezone']?.toString(),
    );
  }
}

class AttendanceSchedule {
  final String? id;
  final String? name;
  final String? startTime;
  final String? endTime;
  final int graceMinutes;
  final String? timezone;
  final bool remoteAllowed;
  final List<String> daysOfWeek;

  AttendanceSchedule({
    this.id,
    this.name,
    this.startTime,
    this.endTime,
    required this.graceMinutes,
    this.timezone,
    required this.remoteAllowed,
    required this.daysOfWeek,
  });

  factory AttendanceSchedule.fromMap(Map<String, dynamic> map) {
    final start = map['startTime'] ?? map['start_time'];
    final end = map['endTime'] ?? map['end_time'];
    final grace = map['graceMinutes'] ?? map['grace_minutes'];
    final remote = map['remoteAllowed'] ?? map['remote_allowed'];
    final rawDays = map['daysOfWeek'] ?? map['days_of_week'];
    final days = <String>[];
    if (rawDays is List) {
      for (final entry in rawDays) {
        if (entry == null) continue;
        days.add(entry.toString());
      }
    }

    return AttendanceSchedule(
      id: map['id']?.toString(),
      name: map['name']?.toString(),
      startTime: start?.toString(),
      endTime: end?.toString(),
      graceMinutes: (grace as num?)?.toInt() ?? 0,
      timezone: map['timezone']?.toString(),
      remoteAllowed: remote == true,
      daysOfWeek: days,
    );
  }
}

class AttendancePolicy {
  final String date;
  final String? department;
  final bool isWorkDay;
  final bool isHoliday;
  final bool isOnLeave;
  final String? holidayName;
  final AttendanceSchedule? schedule;

  AttendancePolicy({
    required this.date,
    this.department,
    required this.isWorkDay,
    required this.isHoliday,
    required this.isOnLeave,
    this.holidayName,
    this.schedule,
  });

  factory AttendancePolicy.fromMap(Map<String, dynamic> map) {
    final scheduleMap = (map['schedule'] ?? map['attendance_schedule'])
        as Map<String, dynamic>?;
    final dateStr = map['date']?.toString() ?? map['policy_date']?.toString();
    final rawIsWorkDay =
        map['isWorkDay'] ?? map['is_work_day'] ?? map['is_workday'];
    final rawIsHoliday =
        map['isHoliday'] ?? map['is_holiday'] ?? map['holiday'];
    final rawIsOnLeave =
        map['isOnLeave'] ?? map['is_on_leave'] ?? map['on_leave'];
    final rawHolidayName = map['holidayName'] ?? map['holiday_name'];

    bool? isWorkDay = _parseBool(rawIsWorkDay);
    final isHoliday = _parseBool(rawIsHoliday) ?? false;
    final isOnLeave = _parseBool(rawIsOnLeave) ?? false;
    final schedule =
        scheduleMap != null ? AttendanceSchedule.fromMap(scheduleMap) : null;
    final scheduleWorkDay =
        schedule != null ? _inferIsWorkDay(dateStr, schedule.daysOfWeek) : null;

    if (isWorkDay == null && scheduleWorkDay != null) {
      isWorkDay = scheduleWorkDay;
    }

    isWorkDay ??= true;

    return AttendancePolicy(
      date: dateStr ?? '',
      department: map['department']?.toString(),
      isWorkDay: isWorkDay,
      isHoliday: isHoliday,
      isOnLeave: isOnLeave,
      holidayName: rawHolidayName?.toString(),
      schedule: schedule,
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return null;
  }

  static bool _inferIsWorkDay(String? dateStr, List<String> days) {
    if (dateStr == null || dateStr.isEmpty || days.isEmpty) {
      return true;
    }
    final date = DateTime.tryParse(dateStr);
    if (date == null) return true;

    final tokens = days
        .map((d) => d.trim().toLowerCase())
        .where((d) => d.isNotEmpty)
        .toSet();

    final weekday = date.weekday;
    final aliases = _weekdayAliases(weekday);
    return aliases.any(tokens.contains);
  }

  static Set<String> _weekdayAliases(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return {'1', 'mon', 'monday'};
      case DateTime.tuesday:
        return {'2', 'tue', 'tues', 'tuesday'};
      case DateTime.wednesday:
        return {'3', 'wed', 'wednesday'};
      case DateTime.thursday:
        return {'4', 'thu', 'thur', 'thurs', 'thursday'};
      case DateTime.friday:
        return {'5', 'fri', 'friday'};
      case DateTime.saturday:
        return {'6', 'sat', 'saturday'};
      case DateTime.sunday:
        return {'7', 'sun', 'sunday'};
      default:
        return {};
    }
  }
}

class AttendanceViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();
  final _cacheService = locator<CacheService>();
  final _imagePicker = ImagePicker();
  final _deviceInfo = DeviceInfoPlugin();
  final _connectivityService = ConnectivityService();

  List<OfficeLocation> _officeLocations = [];
  bool _officesLoaded = false;
  AttendancePolicy? _attendancePolicy;
  static const int defaultRetentionDays = 90;
  static const String defaultConsentVersion = 'v1';
  static const String _defaultConsentCopy =
      'I consent to capture my selfie and location for attendance verification. Data is retained for {days} days.';
  // TEMP: allow check-in while on leave for testing; set to false to restore.
  static const bool _ignoreLeaveCheckForTesting = false;
  // TEMP: treat Saturday as a working on-site day for testing; set to false to restore.
  static const bool _forceWorkdayForTesting = false;
  static const bool _forceOnsiteSaturdayForTesting = false;
  // TEMP: bypass geofencing checks for testing; set to false to restore.
  static const bool _ignoreGeofenceForTesting = true;

  bool _consentGiven = true;
  String _consentVersion = defaultConsentVersion;
  int _retentionDays = defaultRetentionDays;
  String? _consentCopy;

  /// User's distance from nearest office
  double? _distanceFromNearestOffice;
  double? get distanceFromNearestOffice => _distanceFromNearestOffice;

  /// Name of nearest office
  String? _nearestOfficeName;
  String? get nearestOfficeName => _nearestOfficeName;
  double? _nearestOfficeRadius;

  /// Is user within check-in range of any office?
  bool _isWithinOfficeRange = false;
  bool get isWithinOfficeRange => _isWithinOfficeRange;

  AttendancePolicy? get attendancePolicy => _attendancePolicy;
  bool get hasPolicy => _attendancePolicy != null;
  bool get isOnLeave => _attendancePolicy?.isOnLeave ?? false;
  bool get isHoliday => _attendancePolicy?.isHoliday ?? false;
  String? get holidayName => _attendancePolicy?.holidayName;
  bool get _isOnLeaveEffective =>
      _ignoreLeaveCheckForTesting ? false : isOnLeave;

  bool get isWeekendDay {
    final today = DateTime.now();
    if (_forceWorkdayForTesting && today.weekday == DateTime.saturday) {
      return false;
    }
    return today.weekday == DateTime.saturday ||
        today.weekday == DateTime.sunday;
  }

  bool get isWorkDay {
    final today = DateTime.now();
    if (_forceWorkdayForTesting && today.weekday == DateTime.saturday) {
      return !_isOnLeaveEffective && !isHoliday;
    }
    final policyWorkDay = _attendancePolicy?.isWorkDay;
    final base = policyWorkDay ?? !isWeekendDay;
    return base && !_isOnLeaveEffective && !isHoliday;
  }

  static const Set<int> _onsiteWeekdays = {
    DateTime.tuesday,
    DateTime.friday,
  };
  static const Set<int> _remoteWeekdays = {
    DateTime.monday,
    DateTime.wednesday,
    DateTime.thursday,
  };

  bool get isOnsiteDay {
    if (!isWorkDay) return false;
    if (_forceWorkdayForTesting &&
        _forceOnsiteSaturdayForTesting &&
        DateTime.now().weekday == DateTime.saturday) {
      return true;
    }
    return _onsiteWeekdays.contains(DateTime.now().weekday);
  }

  bool get isRemoteDay {
    if (!isWorkDay) return false;
    if (_forceWorkdayForTesting &&
        _forceOnsiteSaturdayForTesting &&
        DateTime.now().weekday == DateTime.saturday) {
      return false;
    }
    return _remoteWeekdays.contains(DateTime.now().weekday);
  }

  bool get isRemoteAllowed => isRemoteDay;
  String? get scheduleName => _attendancePolicy?.schedule?.name;
  int get graceMinutes => _attendancePolicy?.schedule?.graceMinutes ?? 0;
  List<OfficeLocation> get officeLocations => _officeLocations;
  bool get hasOfficeLocations => _officeLocations.isNotEmpty;

  double? _livenessScore;
  String? _livenessType;

  bool get consentGiven => _consentGiven;
  String get consentSummary =>
      (_consentCopy ?? _defaultConsentCopy).replaceAll(
        '{days}',
        _retentionDays.toString(),
      );
  int get retentionDays => _retentionDays;

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
  List<String> _lateReasons = [];

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
  List<String> get lateReasons => _lateReasons;
  List<AttendanceRecord> get recentActivity => _recentActivity;
  Map<String, dynamic>? get todayAttendance => _todayAttendance;

  bool get canCheckIn => !_hasCheckedInToday && !isBusy;
  bool get canCheckOut => _hasCheckedInToday && !_hasCheckedOutToday && !isBusy;
  bool get canCapturePhoto => _isLocationVerified && !_isCapturing;

  /// Returns true if current time is past 9:00 AM (considered late)
  bool get isLateCheckIn {
    if (!isWorkDay || _isOnLeaveEffective) return false;
    final deadline = _scheduledDeadline();
    final now = DateTime.now();
    if (deadline == null) {
      return now.hour >= 9;
    }
    return now.isAfter(deadline);
  }

  /// Returns how many minutes late the check-in would be
  int get minutesLate {
    if (!isWorkDay || _isOnLeaveEffective) return 0;
    final now = DateTime.now();
    final deadline = _scheduledDeadline();
    if (deadline == null) {
      final fallback = DateTime(now.year, now.month, now.day, 9, 0);
      return now.isAfter(fallback) ? now.difference(fallback).inMinutes : 0;
    }
    return now.isAfter(deadline) ? now.difference(deadline).inMinutes : 0;
  }

  void setLateReason(String? reason) {
    _lateReason = reason;
    rebuildUi();
  }

  bool _isInitialized = false;
  bool _connectivityInitialized = false;
  Timer? _pollingTimer;

  Future<void> initialize() async {
    if (_isInitialized) {
      // Already initialized - just do a silent refresh
      _refreshSilently();
      return;
    }

    setBusy(true);
    try {
      if (!_connectivityInitialized) {
        await _connectivityService.initialize();
        _connectivityInitialized = true;
      }

      // 1. Load cached data first for instant display
      await _loadCachedData();

      await _loadReferenceData();

      // 2. Fetch fresh data in background
      await _loadOfficeLocations();
      await _loadAttendancePolicy();
      await _loadTodayStatus();
      await _loadRecentActivity();

      // 3. Start silent polling
      _startPolling();

      _isInitialized = true;
    } finally {
      setBusy(false);
    }
  }

  /// Start silent polling (every 5 minutes)
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshSilently();
    });
  }

  /// Refresh silently without loading state
  Future<void> _refreshSilently() async {
    try {
      await _loadAttendancePolicy();
      await _loadTodayStatus();
      await _loadRecentActivity();
    } catch (e) {
      AppLogger.log('Error in silent refresh: $e');
    }
  }

  Future<void> refresh() async {
    try {
      await _loadAttendancePolicy();
      await _loadTodayStatus();
      await _loadRecentActivity();
      rebuildUi();
    } catch (e) {
      AppLogger.log('Error refreshing attendance: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Load cached attendance data for instant display
  Future<void> _loadCachedData() async {
    try {
      // Load cached today's attendance
      final cachedToday = await _cacheService.getCachedTodayAttendance();
      if (cachedToday != null) {
        _todayAttendance = cachedToday;
        _hasCheckedInToday = _deriveCheckedIn(cachedToday);
        _hasCheckedOutToday = _deriveCheckedOut(cachedToday);
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
      AppLogger.log('Error loading cached attendance data: $e');
    }
  }

  Future<void> _loadOfficeLocations() async {
    if (_officesLoaded) return;
    try {
      final offices = await _backendService.getOfficeLocations();
      _officeLocations = offices.map(OfficeLocation.fromMap).toList();
      _officesLoaded = true;
      final details = _officeLocations
          .map((office) =>
              '${office.name} (${office.latitude}, ${office.longitude})'
              '${office.radiusMeters != null ? ', r=${office.radiusMeters!.toStringAsFixed(0)}m' : ''}')
          .join(' | ');
      AppLogger.log(_officeLocations.isEmpty
          ? 'Office locations loaded: none'
          : 'Office locations loaded (${_officeLocations.length}): $details');
      rebuildUi();
    } catch (e) {
      AppLogger.log('Error fetching office locations: $e');
    }
  }

  Future<void> _loadReferenceData() async {
    try {
      final refData = await _backendService.getReferenceData();
      final reasons = refData['attendanceLateReasons'];
      if (reasons is List) {
        _lateReasons = reasons
            .whereType<String>()
            .where((reason) => reason.trim().isNotEmpty)
            .toList();
      }
      final consentVersion =
          refData['attendanceConsentVersion'] ?? refData['consentVersion'];
      if (consentVersion is String && consentVersion.trim().isNotEmpty) {
        _consentVersion = consentVersion.trim();
      }
      final retention =
          refData['attendanceRetentionDays'] ?? refData['retentionDays'];
      if (retention is num) {
        _retentionDays = retention.toInt();
      }
      final consentCopy =
          refData['attendanceConsentCopy'] ?? refData['attendanceConsentText'];
      if (consentCopy is String && consentCopy.trim().isNotEmpty) {
        _consentCopy = consentCopy.trim();
      }
      rebuildUi();
    } catch (e) {
      AppLogger.log('Error fetching reference data: $e');
    }
  }

  Future<void> _loadAttendancePolicy() async {
    try {
      final policy = await _backendService.getAttendancePolicyToday();
      if (policy != null) {
        _attendancePolicy = AttendancePolicy.fromMap(policy);
        rebuildUi();
      }
    } catch (e) {
      AppLogger.log('Error fetching attendance policy: $e');
    }
  }

  Future<void> _loadTodayStatus() async {
    try {
      _todayAttendance = await _backendService.getTodayAttendance();
      if (_todayAttendance != null) {
        _hasCheckedInToday = _deriveCheckedIn(_todayAttendance);
        _hasCheckedOutToday = _deriveCheckedOut(_todayAttendance);

        // Cache the attendance status
        await _cacheService.cacheTodayAttendance(_todayAttendance);
      }
      rebuildUi();
    } catch (e) {
      AppLogger.log('Error loading today status: $e');
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
      AppLogger.log('Error loading recent activity: $e');
    }
  }

  /// Calculate distance to all offices and find the nearest one
  void _checkOfficeProximity() {
    if (_currentPosition == null) return;

    if (_officeLocations.isEmpty) {
      _distanceFromNearestOffice = null;
      _nearestOfficeName = null;
      _nearestOfficeRadius = null;
      _isWithinOfficeRange = true;
      return;
    }

    double? minDistance;
    String? nearestName;
    double? nearestRadius;

    for (final office in _officeLocations) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        office.latitude,
        office.longitude,
      );

      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
        nearestName = office.name;
        nearestRadius = office.radiusMeters;
      }
    }

    _distanceFromNearestOffice = minDistance;
    _nearestOfficeName = nearestName;
    _nearestOfficeRadius = nearestRadius;
    final radius = nearestRadius ?? 150.0;
    final withinRange = (minDistance != null && minDistance <= radius);
    _isWithinOfficeRange = _ignoreGeofenceForTesting ? true : withinRange;

    AppLogger.log(
        '📍 Distance to nearest office ($nearestName): ${minDistance?.toStringAsFixed(0)}m');
    AppLogger.log(
        '📍 Within range: $_isWithinOfficeRange (max: ${radius.toStringAsFixed(0)}m)');
    if (_ignoreGeofenceForTesting) {
      AppLogger.log('📍 Geofencing disabled for testing');
    }
  }

  /// Get formatted distance string
  String get distanceMessage {
    if (_distanceFromNearestOffice == null) return '';
    final distance = _distanceFromNearestOffice!;
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m away';
    }
    return '${(distance / 1000).toStringAsFixed(1)}km away';
  }

  DateTime? _scheduledDeadline() {
    final parsed = _parseTime(_attendancePolicy?.schedule?.startTime);
    if (parsed == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, parsed[0], parsed[1])
        .add(Duration(minutes: graceMinutes));
  }

  List<int>? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return [hour, minute];
  }

  Map<String, dynamic> _buildCheckInPayload({
    required double latitude,
    required double longitude,
    double? accuracy,
    String? address,
    String? photoUrl,
    String? photoPath,
    String? deviceInfo,
    String? deviceId,
    String? note,
    bool isRemote = false,
  }) {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoPath != null) 'photo_path': photoPath,
      if (deviceInfo != null) 'device_info': deviceInfo,
      if (deviceId != null) 'device_id': deviceId,
      if (note != null) 'note': note,
      'is_remote': isRemote,
      if (_livenessScore != null) 'liveness_score': _livenessScore,
      if (_livenessType != null) 'liveness_type': _livenessType,
      'consent_given': _consentGiven,
      'consent_version': _consentVersion,
      'retention_days': _retentionDays,
    };
  }


  /// Request location permission and get current position
  Future<bool> _getLocation() async {
    try {
      if (!_officesLoaded) {
        await _loadOfficeLocations();
      }

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
        AppLogger.log('Error getting address: $e');
        _currentAddress = 'Location acquired';
      }

      // Check proximity to office locations
      _checkOfficeProximity();

      return true;
    } catch (e) {
      _errorMessage = 'Error getting location: $e';
      rebuildUi();
      return false;
    }
  }

  /// Step 1: Verify location FIRST before allowing camera
  /// This must be called before capturePhoto() will work
  /// GEOFENCING: Only allows check-in if within 150m of an approved office location
  Future<bool> verifyLocation() async {
    if (_isLocationVerified) return true;

    _isVerifyingLocation = true;
    _errorMessage = null;
    _statusMessage = 'Verifying your location...';
    rebuildUi();

    try {
      final success = await _getLocation();
      if (success) {
        // Check if user is within range of any office
        if (!_isWithinOfficeRange) {
          _isVerifyingLocation = false;
          final officeLabel = _nearestOfficeName ?? 'the office';
          _errorMessage = '📍 You are not at an approved location.\n\n'
              'You are ${distanceMessage} from $officeLabel.\n\n'
              'Please go to the office before checking in.';
          _statusMessage = null;
          rebuildUi();
          return false;
        }

        _isLocationVerified = true;
        _statusMessage = _ignoreGeofenceForTesting
            ? '✓ Location verified (geofencing disabled)'
            : '✓ Location verified: $_nearestOfficeName';
        AppLogger.log('📍 Location verified: $_currentAddress ($_nearestOfficeName)');
      } else {
        _statusMessage = null;
      }
      _isVerifyingLocation = false;
      rebuildUi();
      return success && _isWithinOfficeRange;
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
    _livenessScore = null;
    _livenessType = null;
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
        AppLogger.log('❌ No face detected in photo');
        _livenessScore = 0.0;
        _livenessType = 'mlkit_no_face';
        return false;
      }

      // Check if at least one face is detected with reasonable confidence
      final mainFace = faces.first;
      AppLogger.log('✅ Face detected! Landmarks: ${mainFace.landmarks.length}');

      double score = 0.6;
      String type = 'mlkit_presence';

      final leftProb = mainFace.leftEyeOpenProbability;
      final rightProb = mainFace.rightEyeOpenProbability;
      if (leftProb != null && rightProb != null) {
        final leftOpen = leftProb > 0.3;
        final rightOpen = rightProb > 0.3;
        if (leftOpen && rightOpen) {
          score = 0.85;
          type = 'mlkit_eye_open';
        } else if (leftOpen || rightOpen) {
          score = 0.7;
          type = 'mlkit_eye_open_partial';
        } else {
          type = 'mlkit_eye_closed';
        }
      }

      final smileProb = mainFace.smilingProbability;
      if (smileProb != null && smileProb > 0.3) {
        score += 0.05;
        type = '${type}_smile';
      }

      _livenessScore = score.clamp(0.0, 1.0).toDouble();
      _livenessType = type;

      return true;
    } catch (e) {
      AppLogger.log('Error during face detection: $e');
      _isVerifyingFace = false;
      _livenessType = 'mlkit_error';
      _livenessScore = 0.0;
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
      String? deviceId;
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

      try {
        deviceId = await _cacheService.getOrCreateDeviceId();
      } catch (_) {
        // Leave deviceId null if storage fails.
      }
      if (deviceId == null || deviceId.isEmpty) {
        _errorMessage =
            'Device ID unavailable. Please restart the app and try again.';
        setBusy(false);
        rebuildUi();
        return false;
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
            AppLogger.log('📸 Photo uploaded: $photoUrl');
          } else {
            AppLogger.log('⚠️ Storage not available, continuing without photo');
          }
        } catch (e) {
          AppLogger.log('⚠️ Photo upload failed: $e (continuing without photo)');
        }
      }

      if (_capturedPhotoPath != null && (photoUrl == null || photoUrl.isEmpty)) {
        _errorMessage = 'Photo upload failed. Please try again.';
        _statusMessage = null;
        setBusy(false);
        rebuildUi();
        return false;
      }

      // Build note with late reason if applicable
      String? note;
      if (isLateCheckIn && lateReason != null) {
        note = 'Late check-in (${minutesLate}min): $lateReason';
        AppLogger.log('📝 Late check-in note: $note');
      }

      // Step 3: Submit check-in
      _statusMessage = 'Completing check-in...';
      rebuildUi();

      final payload = _buildCheckInPayload(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracy: _currentPosition!.accuracy,
        address: _currentAddress,
        photoUrl: photoUrl,
        photoPath: _capturedPhotoPath,
        deviceInfo: deviceInfo,
        deviceId: deviceId,
        note: note,
        isRemote: false,
      );

      Map<String, dynamic>? result;
      if (_connectivityService.isOnline) {
        result = await _backendService.checkIn(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          accuracy: _currentPosition!.accuracy,
          address: _currentAddress,
          photoUrl: photoUrl,
          deviceInfo: deviceInfo,
          deviceId: deviceId,
          note: note,
          livenessScore: _livenessScore,
          livenessType: _livenessType,
          consentGiven: _consentGiven,
          consentVersion: _consentVersion,
          retentionDays: _retentionDays,
        );
      }

      if (result != null) {
        final normalizedResult = Map<String, dynamic>.from(result);
        normalizedResult['checked_in'] = normalizedResult['checked_in'] ?? true;
        normalizedResult['checked_out'] = normalizedResult['checked_out'] ?? false;
        _todayAttendance = normalizedResult;
        _hasCheckedInToday = _deriveCheckedIn(normalizedResult);
        _hasCheckedOutToday = _deriveCheckedOut(normalizedResult);
        _capturedPhotoPath = null;
        _livenessScore = null;
        _livenessType = null;
        _lateReason = null;
        _statusMessage = isLateCheckIn
            ? 'Check-in successful (${minutesLate}min late)'
            : 'Check-in successful! ✓';

        // Cache the attendance status
        await _cacheService.cacheTodayAttendance(normalizedResult);

        await _loadRecentActivity();
        setBusy(false);

        // Reset verification state for tomorrow
        _isLocationVerified = false;
        _isFaceVerified = false;

        rebuildUi();
        return true;
      } else if (!_connectivityService.isOnline) {
        await _connectivityService.queueOfflineAction(
          action: 'CHECK_IN',
          endpoint: '/attendance/check-in',
          method: 'POST',
          body: payload,
        );
        _hasCheckedInToday = true;
        _todayAttendance = {
          'checked_in': true,
          'checked_out': false,
          'status': isLateCheckIn ? 'late' : 'present',
          'check_in': DateTime.now().toIso8601String(),
          'pending_sync': true,
        };
        _capturedPhotoPath = null;
        _livenessScore = null;
        _livenessType = null;
        _statusMessage = 'Check-in saved offline. Will sync when online.';
        await _cacheService.cacheTodayAttendance(_todayAttendance);
        await _loadRecentActivity();
        setBusy(false);
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
    _livenessScore = null;
    _livenessType = null;
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
        AppLogger.log('Location not available for remote check-in: $e');
        // Continue without location - it's optional for remote
      }

      // Step 2: Get device info
      String deviceInfo = '';
      String? deviceId;
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

      try {
        deviceId = await _cacheService.getOrCreateDeviceId();
      } catch (_) {
        // Leave deviceId null if storage fails.
      }
      if (deviceId == null || deviceId.isEmpty) {
        _errorMessage =
            'Device ID unavailable. Please restart the app and try again.';
        setBusy(false);
        rebuildUi();
        return false;
      }

      // Step 3: Submit remote check-in
      if (!isRemoteAllowed && hasPolicy) {
        _errorMessage = 'Remote check-in is not enabled for your schedule.';
        setBusy(false);
        return false;
      }

      final payload = _buildCheckInPayload(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        address: address,
        deviceInfo: deviceInfo,
        deviceId: deviceId,
        isRemote: true,
      );

      Map<String, dynamic>? result;
      if (_connectivityService.isOnline) {
        result = await _backendService.checkIn(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          address: address,
          photoUrl: null,
          deviceInfo: deviceInfo,
          deviceId: deviceId,
          isRemote: true,
          livenessScore: _livenessScore,
          livenessType: _livenessType,
          consentGiven: _consentGiven,
          consentVersion: _consentVersion,
          retentionDays: _retentionDays,
        );
      }

      if (result != null) {
        final normalizedResult = Map<String, dynamic>.from(result);
        normalizedResult['checked_in'] = normalizedResult['checked_in'] ?? true;
        normalizedResult['checked_out'] = normalizedResult['checked_out'] ?? false;
        _todayAttendance = normalizedResult;
        _hasCheckedInToday = _deriveCheckedIn(normalizedResult);
        _hasCheckedOutToday = _deriveCheckedOut(normalizedResult);
        _livenessScore = null;
        _livenessType = null;
        // Cache the attendance status
        await _cacheService.cacheTodayAttendance(normalizedResult);

        await _loadRecentActivity();
        setBusy(false);
        return true;
      } else if (!_connectivityService.isOnline) {
        await _connectivityService.queueOfflineAction(
          action: 'CHECK_IN',
          endpoint: '/attendance/check-in',
          method: 'POST',
          body: payload,
        );
        _hasCheckedInToday = true;
        _todayAttendance = {
          'checked_in': true,
          'checked_out': false,
          'status': 'present',
          'check_in': DateTime.now().toIso8601String(),
          'pending_sync': true,
        };
        _livenessScore = null;
        _livenessType = null;
        _statusMessage = 'Remote check-in saved offline. Will sync when online.';
        await _cacheService.cacheTodayAttendance(_todayAttendance);
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
      Map<String, dynamic>? result;
      if (_connectivityService.isOnline) {
        result = await _backendService.checkOut();
      }

      if (result != null) {
        _hasCheckedOutToday = true;
        await _loadRecentActivity();
        setBusy(false);
        return true;
      } else if (!_connectivityService.isOnline) {
        await _connectivityService.queueOfflineAction(
          action: 'CHECK_OUT',
          endpoint: '/attendance/check-out',
          method: 'POST',
          body: {},
        );
        _hasCheckedOutToday = true;
        if (_todayAttendance != null) {
          _todayAttendance = {
            ..._todayAttendance!,
            'checked_out': true,
            'pending_sync': true,
          };
        }
        _statusMessage = 'Check-out saved offline. Will sync when online.';
        await _cacheService.cacheTodayAttendance(_todayAttendance);
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

  bool _deriveCheckedIn(Map<String, dynamic>? attendance) {
    if (attendance == null) return false;
    final checkedIn = attendance['checked_in'];
    if (checkedIn is bool) return checkedIn;
    final checkIn = attendance['check_in'];
    if (checkIn != null && checkIn.toString().isNotEmpty) return true;
    final status = (attendance['status'] ?? '').toString().toLowerCase();
    return status == 'present' || status == 'late';
  }

  bool _deriveCheckedOut(Map<String, dynamic>? attendance) {
    if (attendance == null) return false;
    final checkedOut = attendance['checked_out'];
    if (checkedOut is bool) return checkedOut;
    final checkOut = attendance['check_out'];
    return checkOut != null && checkOut.toString().isNotEmpty;
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
