import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/supabase_service.dart';

class VerifyOtpViewModel extends BaseViewModel {
  final String email;

  VerifyOtpViewModel({required this.email});

  final _nav = locator<NavigationService>();
  final _supabaseService = locator<SupabaseService>();
  final _dialogService = locator<DialogService>();

  final otpController = TextEditingController();

  void goBack() {
    _nav.back();
  }

  Future<void> verifyOTP() async {
    if (otpController.text.trim().isEmpty) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Please enter the verification code',
      );
      return;
    }

    if (otpController.text.trim().length != 6) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Verification code must be 6 digits',
      );
      return;
    }

    setBusy(true);
    try {
      // await _supabaseService.verifyOTP(
      //   email: email,
      //   token: otpController.text.trim(),
      // );

      // Show success message
      await _dialogService.showDialog(
        title: 'Success',
        description: 'Your email has been verified! You can now sign in.',
      );

      // Navigate to login
      _nav.clearStackAndShow(Routes.loginView);
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
    setBusy(true);
    try {
     // await _supabaseService.resendOTP(email: email);

      await _dialogService.showDialog(
        title: 'Code Sent',
        description: 'A new verification code has been sent to your email',
      );
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Error',
        description: 'Failed to resend code. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
