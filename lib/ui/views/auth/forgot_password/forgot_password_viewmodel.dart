import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/supabase_service.dart';

class ForgotPasswordViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();
  final _supabaseService = locator<SupabaseService>();
  final _dialogService = locator<DialogService>();

  final emailController = TextEditingController();

  void goBack() {
    _nav.back();
  }

  Future<void> sendResetLink() async {
    // Validation
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

    setBusy(true);
    try {
      await _supabaseService.resetPasswordForEmail(
        email: emailController.text.trim(),
      );

      // Show success dialog
      await _dialogService.showDialog(
        title: 'Reset Link Sent',
        description:
            'We\'ve sent a password reset link to ${emailController.text.trim()}.\n\n'
            'Please check your email (including spam folder) and click the link to reset your password.',
        buttonTitle: 'Got it',
      );

      // Navigate back to login
      _nav.back();
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Failed to send reset link. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
