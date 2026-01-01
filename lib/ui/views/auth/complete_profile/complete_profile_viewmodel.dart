import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/common/app_colors.dart';

class CompleteProfileViewModel extends BaseViewModel {
  final String email;
  final String fullName;

  CompleteProfileViewModel({
    required this.email,
    required this.fullName,
  }) {
    // Debug: Check auth state when view is created
    _debugCheckAuth();
  }

  final _nav = locator<NavigationService>();
  final _backend = locator<BackendApiService>();
  final _dialogService = locator<DialogService>();

  Future<void> _debugCheckAuth() async {
    print('🔍 CompleteProfileViewModel initialized');
    print('📧 Email: $email');
    print('👤 Full Name: $fullName');
    await _backend.debugAuthState();
  }

  Future<void> goToLogin() async {
    // Clear the session and go back to login
    await _backend.signOut();
    _nav.clearStackAndShow(Routes.loginView);
  }

  final employeeIdController = TextEditingController();
  final phoneController = TextEditingController();
  final roleController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  // Department options based on UPDATED requirements
  final List<String> departments = [
    'Operations',
    'Customer Support',
    'Development',
    'Sales',
    'HR',
    'Finance',
    'Executive office',
    'Pos operations',
    'Growth',
    'Admin',
  ];

  // Gender options - restricted
  final List<String> genders = [
    'Male',
    'Female',
  ];

  // Employee Levels
  final List<int> employeeLevels = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  String? selectedDepartment;
  String? selectedGender;
  int? selectedEmployeeLevel;
  bool isTeamLead = false;

  DateTime? dateJoined;
  DateTime? dateOfBirth;

  void setDepartment(String? value) {
    selectedDepartment = value;
    rebuildUi();
  }

  void setGender(String? value) {
    selectedGender = value;
    rebuildUi();
  }

  void setEmployeeLevel(int? value) {
    selectedEmployeeLevel = value;
    rebuildUi();
  }

  void toggleTeamLead(bool value) {
    isTeamLead = value;
    rebuildUi();
  }

  Future<void> selectDateJoined(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kcPrimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: kcTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dateJoined = picked;
      rebuildUi();
    }
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // ~18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kcPrimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: kcTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dateOfBirth = picked;
      rebuildUi();
    }
  }

  String formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> completeProfile() async {
    // Validation
    if (employeeIdController.text.trim().isEmpty) {
      await _dialogService.showDialog(
        title: 'Required Field',
        description: 'Please enter your Employee ID',
      );
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      await _dialogService.showDialog(
        title: 'Required Field',
        description: 'Please enter your phone number',
      );
      return;
    }

    if (!_isValidPhone(phoneController.text.trim())) {
      await _dialogService.showDialog(
        title: 'Invalid Phone',
        description: 'Please enter a valid phone number',
      );
      return;
    }

    if (selectedDepartment == null) {
      await _dialogService.showDialog(
        title: 'Required Field',
        description: 'Please select your department',
      );
      return;
    }

    if (roleController.text.trim().isEmpty) {
      await _dialogService.showDialog(
        title: 'Required Field',
        description:
            'Please enter your job title (e.g., Product Manager, Developer)',
      );
      return;
    }

    if (dateJoined == null) {
      await _dialogService.showDialog(
        title: 'Required Field',
        description: 'Please select the date you joined the company',
      );
      return;
    }

    if (selectedEmployeeLevel == null) {
      await _dialogService.showDialog(
        title: 'Required Field',
        description: 'Please select your employee grade level',
      );
      return;
    }

    setBusy(true);
    try {
      // 1. Update Profile (User is already logged in from LoginView)
      await _backend.completeProfile(
        employeeId: employeeIdController.text.trim(),
        phone: phoneController.text.trim(),
        department: selectedDepartment!,
        role: roleController.text.trim(),
        dateJoined: dateJoined!,
        gender: selectedGender,
        dateOfBirth: dateOfBirth,
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        city: cityController.text.trim().isEmpty
            ? null
            : cityController.text.trim(),
        state: stateController.text.trim().isEmpty
            ? null
            : stateController.text.trim(),
        isTeamLead: isTeamLead,
        employeeLevel: selectedEmployeeLevel,
      );

      setBusy(false);

      // 3. Navigate to Home
      _nav.clearStackAndShow(Routes.homeView);
    } catch (e) {
      setBusy(false);
      print('❌ Error completing profile: $e');

      await _dialogService.showDialog(
        title: 'Save Failed',
        description: 'Error: $e',
        buttonTitle: 'OK',
      );
    }
  }

  Future<void> _openEmailApp() async {
    try {
      // Try to open default email app
      // This is a best-effort attempt
      // Different platforms may handle this differently

      // For now, we'll just show a message
      // In a production app, you'd use url_launcher package
      await _dialogService.showDialog(
        title: 'Check Your Email',
        description:
            'Please open your email app and look for the verification email from Schoolable.',
        buttonTitle: 'Got it',
      );
    } catch (e) {
      // Silently fail - not critical
    }
  }

  bool _isValidPhone(String phone) {
    // Basic phone validation - at least 10 digits
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10;
  }

  @override
  void dispose() {
    employeeIdController.dispose();
    phoneController.dispose();
    roleController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    super.dispose();
  }
}
