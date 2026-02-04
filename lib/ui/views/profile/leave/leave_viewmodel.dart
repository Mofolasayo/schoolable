import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/services/backend_api_service.dart';

class LeaveRequest {
  final String id;
  final String type;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime? createdAt;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.status,
    this.startDate,
    this.endDate,
    this.notes,
    this.createdAt,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return LeaveRequest(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Leave',
      status: map['status']?.toString() ?? 'pending',
      startDate: parseDate(map['startDate']?.toString()),
      endDate: parseDate(map['endDate']?.toString()),
      notes: map['notes']?.toString(),
      createdAt: parseDate(map['createdAt']?.toString()),
    );
  }
}

class LeaveViewModel extends BaseViewModel {
  final _backendService = locator<BackendApiService>();

  final TextEditingController typeController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;

  List<LeaveRequest> _requests = [];
  bool _isSubmitting = false;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get errorMessage => _errorMessage;
  List<LeaveRequest> get requests => _requests;
  bool get isSubmitting => _isSubmitting;

  LeaveViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    setBusy(true);
    await fetchRequests();
    setBusy(false);
  }

  Future<void> fetchRequests() async {
    try {
      final data = await _backendService.getLeaveRequests();
      _requests = data.map(LeaveRequest.fromMap).toList();
    } catch (e) {
      _requests = [];
      _errorMessage = 'Unable to load leave requests.';
    }
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    if (_endDate != null && _endDate!.isBefore(date)) {
      _endDate = date;
    }
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
      _startDate = date;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> submitRequest() async {
    clearError();
    if (_startDate == null || _endDate == null) {
      _errorMessage = 'Select a start and end date.';
      notifyListeners();
      return;
    }

    final type = typeController.text.trim().isEmpty
        ? 'Leave'
        : typeController.text.trim();

    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _backendService.submitLeaveRequest(
        startDate: _startDate!,
        endDate: _endDate!,
        type: type,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (result == null) {
        _errorMessage = 'Unable to submit leave request.';
      } else {
        _startDate = null;
        _endDate = null;
        typeController.clear();
        notesController.clear();
        await fetchRequests();
      }
    } catch (e) {
      _errorMessage = 'Unable to submit leave request.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    typeController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
