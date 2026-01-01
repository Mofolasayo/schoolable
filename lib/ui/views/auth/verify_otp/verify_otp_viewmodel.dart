import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';

class VerifyOtpViewModel extends BaseViewModel {
  final String email;
  final bool isPasswordReset;

  VerifyOtpViewModel({required this.email, this.isPasswordReset = false});

  final _nav = locator<NavigationService>();
  final _backend = locator<BackendApiService>();
  final _dialogService = locator<DialogService>();

  // 6 individual controllers for PIN boxes
  final List<TextEditingController> pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  bool _isResending = false;
  bool get isResending => _isResending;

  bool get isCodeComplete => pinControllers.every((c) => c.text.isNotEmpty);

  String get fullCode => pinControllers.map((c) => c.text).join();

  void updateCode() {
    rebuildUi();
  }

  void goBack() {
    _nav.back();
  }

  void goToSignup() {
    _nav.clearStackAndShow(Routes.signupView);
  }

  void goToLogin() {
    _nav.clearStackAndShow(Routes.loginView);
  }

  Future<void> verifyOTP() async {
    final code = fullCode;

    if (code.isEmpty) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Please enter the verification code',
      );
      return;
    }

    if (code.length != 6) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Verification code must be 6 digits',
      );
      return;
    }

    setBusy(true);
    try {
      if (isPasswordReset) {
        // Verify reset code first
        final valid = await _backend.verifyResetCode(code);
        if (valid) {
          // Navigate to new password screen
          _nav.navigateTo(
            Routes.resetPasswordView,
            arguments: ResetPasswordViewArguments(code: code),
          );
        } else {
          await _dialogService.showDialog(
            title: 'Invalid Code',
            description:
                'The code is invalid or has expired. Please try again.',
          );
        }
      } else {
        // Email verification
        await _backend.verifyEmail(code);

        await _dialogService.showDialog(
          title: 'Success',
          description: 'Your email has been verified! You can now sign in.',
        );

        _nav.clearStackAndShow(Routes.loginView);
      }
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Verification Failed',
        description: 'Invalid or expired code. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> resendOTP() async {
    _isResending = true;
    rebuildUi();

    try {
      if (isPasswordReset) {
        await _backend.resetPasswordForEmail(email: email);
        await _dialogService.showDialog(
          title: 'Code Sent',
          description: 'A new reset code has been sent to $email',
        );
      } else {
        await _backend.resendVerification(email);
        await _dialogService.showDialog(
          title: 'Code Sent',
          description: 'A new verification code has been sent to $email',
        );
      }
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Failed to resend code. Please try again.',
      );
    } finally {
      _isResending = false;
      rebuildUi();
    }
  }

  @override
  void dispose() {
    for (var controller in pinControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
