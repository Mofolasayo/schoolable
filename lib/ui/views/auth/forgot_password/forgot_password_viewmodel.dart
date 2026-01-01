import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';

class ForgotPasswordViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();
  final _backendService = locator<BackendApiService>();
  final _dialogService = locator<DialogService>();

  final emailController = TextEditingController();

  void goBack() {
    _nav.back();
  }

  Future<void> sendResetLink() async {
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
      final success = await _backendService.resetPasswordForEmail(
        email: emailController.text.trim(),
      );

      if (success) {
        // Navigate to OTP verification screen with password reset mode
        _nav.navigateTo(
          Routes.verifyOtpView,
          arguments: VerifyOtpViewArguments(
            email: emailController.text.trim(),
            isPasswordReset: true,
          ),
        );
      } else {
        await _dialogService.showDialog(
          title: 'Error',
          description: 'Failed to send reset link. Please try again.',
        );
      }
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
