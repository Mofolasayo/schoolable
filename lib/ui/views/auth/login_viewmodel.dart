import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/supabase_service.dart';

class LoginViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();

  final _supabaseService = locator<SupabaseService>();
  final _dialogService = locator<DialogService>();

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
      // 1. Sign In
      await _supabaseService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );

      // 2. Check Profile Status
      final profile = await _supabaseService.getUserProfile();
      print('🔍 User Profile Check: $profile');

      // Check if profile is missing critical info
      final bool isProfileIncomplete = profile == null ||
          _isNullOrEmpty(profile['role']) ||
          _isNullOrEmpty(profile['employee_id']) ||
          _isNullOrEmpty(profile['department']) ||
          _isNullOrEmpty(profile['phone']) ||
          _isNullOrEmpty(profile['date_joined']) ||
          _isNullOrEmpty(profile['address']) ||
          _isNullOrEmpty(profile['date_of_birth']);

      if (isProfileIncomplete) {
        // Redirect to Complete Profile
        print(
            '⚠️ Profile incomplete (Missing fields). Redirecting to CompleteProfileView.');

        _nav.replaceWithCompleteProfileView(
          email: profile?['email'] ?? emailController.text,
          fullName: profile?['full_name'] ?? '',
        );
      } else {
        // Profile is complete, go Home
        print('✅ Profile complete. Going to HomeView.');
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

  bool _isNullOrEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    return false;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
