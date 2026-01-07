import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/notification_service.dart';

class LoginViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();

  final _backend = locator<BackendApiService>();
  final _dialogService = locator<DialogService>();
  final _notificationService = NotificationService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool rememberMe = true;

  void togglePassword() {
    obscurePassword = !obscurePassword;
    rebuildUi();
  }

  void toggleRememberMe(bool value) {
    rememberMe = value;
    rebuildUi();
  }

  void goToSignup() {
    _nav.navigateToSignupView();
  }

  void goToForgotPassword() {
    _nav.navigateToForgotPasswordView();
  }

  Future<void> signIn() async {
    setBusy(true);
    try {
      print('🔐 Attempting login for: ${emailController.text.trim()}');

      await _backend.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      print('✅ Login successful, token saved');

      // Debug: Verify token was saved
      await _backend.debugAuthState();

      // Use the dedicated endpoint to check profile completion status from database
      print('📋 Checking profile completion status...');
      final completionStatus = await _backend.checkProfileComplete();
      print('📋 Completion status response: $completionStatus');

      final bool isComplete = completionStatus['is_complete'] == true;
      final email = completionStatus['email'] ?? emailController.text;
      final fullName = completionStatus['full_name'] ?? '';

      if (!isComplete) {
        // Redirect to Complete Profile
        print('⚠️ Profile not complete. Redirecting to CompleteProfileView.');
        _nav.replaceWithCompleteProfileView(
          email: email,
          fullName: fullName,
        );
      } else {
        // Profile is complete, go Home
        print(
            '✅ Profile complete (completed at: ${completionStatus['profile_completed_at']}). Going to HomeView.');
        await _notificationService.initialize();
        _nav.replaceWithHomeView();
      }
    } catch (e) {
      print('❌ Login Logic Error: $e');
      await _dialogService.showDialog(
        title: 'Login Failed',
        description: e.toString(),
      );
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
