import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/auth/verify_otp/verify_otp_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/test_helpers.dart';

void main() {
  void fillCode(VerifyOtpViewModel model, String code) {
    for (var i = 0; i < model.pinControllers.length; i++) {
      model.pinControllers[i].text = code[i];
    }
  }

  group('VerifyOtpViewModel Tests -', () {
    late MockNavigationService navigationService;
    late MockBackendApiService backend;
    late MockDialogService dialogService;

    setUp(() {
      registerServices();
      navigationService = locator<NavigationService>() as MockNavigationService;
      backend = locator<BackendApiService>() as MockBackendApiService;
      dialogService = locator<DialogService>() as MockDialogService;
    });

    tearDown(() => locator.reset());

    test('shows dialog when code is empty', () async {
      final model = VerifyOtpViewModel(email: 'user@schoolable.com');

      await model.verifyOTP();

      verify(
        dialogService.showDialog(
          title: 'Error',
          description: 'Please enter the verification code',
        ),
      ).called(1);
      model.dispose();
    });

    test('verifies email and navigates to login', () async {
      when(backend.verifyEmail(any)).thenAnswer((_) async => {'ok': true});

      final model = VerifyOtpViewModel(email: 'user@schoolable.com');
      fillCode(model, '123456');

      await model.verifyOTP();

      verify(backend.verifyEmail('123456')).called(1);
      verify(
        navigationService.clearStackAndShow<dynamic>(
          Routes.loginView,
          arguments: anyNamed('arguments'),
          id: anyNamed('id'),
          parameters: anyNamed('parameters'),
        ),
      ).called(1);
      model.dispose();
    });

    test('password reset code navigates to reset password view', () async {
      when(backend.verifyResetCode(any)).thenAnswer((_) async => true);

      final model = VerifyOtpViewModel(
        email: 'user@schoolable.com',
        isPasswordReset: true,
      );
      fillCode(model, '654321');

      await model.verifyOTP();

      final captured = verify(
        navigationService.navigateTo<dynamic>(
          Routes.resetPasswordView,
          arguments: captureAnyNamed('arguments'),
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).captured;

      final args = captured.single as ResetPasswordViewArguments;
      expect(args.code, '654321');
      model.dispose();
    });

    test('resendOTP triggers resendVerification for email flow', () async {
      when(backend.resendVerification(any)).thenAnswer((_) async => {'ok': true});

      final model = VerifyOtpViewModel(email: 'user@schoolable.com');

      await model.resendOTP();

      verify(backend.resendVerification('user@schoolable.com')).called(1);
      verify(
        dialogService.showDialog(
          title: 'Code Sent',
          description: anyNamed('description'),
        ),
      ).called(1);
      model.dispose();
    });
  });
}
