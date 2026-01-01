import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';

class ResetPasswordViewModel extends BaseViewModel {
  final String code;

  ResetPasswordViewModel({required this.code}) {
    passwordController.addListener(_updateValidation);
    confirmPasswordController.addListener(_updateValidation);
  }

  final _nav = locator<NavigationService>();
  final _backend = locator<BackendApiService>();
  final _dialogService = locator<DialogService>();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool get showPassword => _showPassword;
  bool get showConfirmPassword => _showConfirmPassword;

  bool get hasMinLength => passwordController.text.length >= 8;
  bool get passwordsMatch =>
      passwordController.text.isNotEmpty &&
      passwordController.text == confirmPasswordController.text;

  void _updateValidation() {
    rebuildUi();
  }

  void togglePasswordVisibility() {
    _showPassword = !_showPassword;
    rebuildUi();
  }

  void toggleConfirmPasswordVisibility() {
    _showConfirmPassword = !_showConfirmPassword;
    rebuildUi();
  }

  Future<void> resetPassword() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Please enter a new password',
      );
      return;
    }

    if (password.length < 8) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Password must be at least 8 characters',
      );
      return;
    }

    if (password != confirmPassword) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Passwords do not match',
      );
      return;
    }

    setBusy(true);
    try {
      final success = await _backend.completePasswordReset(
        code: code,
        newPassword: password,
      );

      if (success) {
        await _dialogService.showDialog(
          title: 'Password Reset',
          description:
              'Your password has been reset successfully. You can now sign in with your new password.',
          buttonTitle: 'Sign In',
        );
        _nav.clearStackAndShow(Routes.loginView);
      } else {
        await _dialogService.showDialog(
          title: 'Error',
          description: 'Failed to reset password. Please try again.',
        );
      }
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Failed to reset password. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    passwordController.removeListener(_updateValidation);
    confirmPasswordController.removeListener(_updateValidation);
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
