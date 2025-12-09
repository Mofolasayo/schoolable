import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/supabase_service.dart';

class SignupViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();
  final _supabaseService = locator<SupabaseService>();
  final _dialogService = locator<DialogService>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  void togglePassword() {
    obscurePassword = !obscurePassword;
    rebuildUi();
  }

  void toggleConfirmPassword() {
    obscureConfirmPassword = !obscureConfirmPassword;
    rebuildUi();
  }

  void goBack() {
    _nav.back();
  }

  Future<void> signUp() async {
    // Validation
    if (fullNameController.text.trim().isEmpty) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Please enter your full name',
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Please enter your email address',
      );
      return;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Please enter a valid email address',
      );
      return;
    }

    if (passwordController.text.isEmpty) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Please enter a password',
      );
      return;
    }

    if (passwordController.text.length < 8) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Password must be at least 8 characters',
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Passwords do not match',
      );
      return;
    }

    setBusy(true);
    try {
      // 1. Create the account (Simple Signup)
      // The database trigger will create the basic profile row
      await _supabaseService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );

      setBusy(false);

      // 2. Show Verification Dialog
      await _dialogService.showDialog(
        title: 'Verify Your Email',
        description: 'Account created successfully!\n\n'
            'We have sent a verification link to ${emailController.text.trim()}.\n\n'
            'Please verify your email, then login to complete your profile.',
        buttonTitle: 'Go to Login',
      );

      // 3. Navigate to Login
      _nav.back(); // Back to Login (since we came from there)
    } catch (e) {
      setBusy(false);
      await _dialogService.showDialog(
        title: 'Signup Failed',
        description: e.toString(),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
