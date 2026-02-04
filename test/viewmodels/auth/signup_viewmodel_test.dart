import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/auth/signup/signup_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SignupViewModel Tests -', () {
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

    test('shows validation error for invalid email', () async {
      final model = SignupViewModel();
      model.fullNameController.text = 'Test User';
      model.emailController.text = 'invalid-email';
      model.passwordController.text = 'password123';
      model.confirmPasswordController.text = 'password123';

      await model.signUp();

      verify(
        dialogService.showDialog(
          title: 'Error',
          description: 'Please enter a valid email address',
        ),
      ).called(1);
      model.dispose();
    });

    test('navigates to VerifyOtpView on successful sign up', () async {
      when(
        backend.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fullName: anyNamed('fullName'),
        ),
      ).thenAnswer((_) async => {'ok': true});

      final model = SignupViewModel();
      model.fullNameController.text = 'Test User';
      model.emailController.text = 'user@schoolable.com';
      model.passwordController.text = 'password123';
      model.confirmPasswordController.text = 'password123';

      await model.signUp();

      verify(
        dialogService.showDialog(
          title: 'Verify Your Email',
          description: anyNamed('description'),
          buttonTitle: anyNamed('buttonTitle'),
        ),
      ).called(1);

      final captured = verify(
        navigationService.replaceWith<dynamic>(
          Routes.verifyOtpView,
          arguments: captureAnyNamed('arguments'),
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).captured;

      final args = captured.single as VerifyOtpViewArguments;
      expect(args.email, 'user@schoolable.com');
      expect(args.isPasswordReset, isFalse);
      model.dispose();
    });

    test('shows dialog when sign up fails', () async {
      when(
        backend.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          fullName: anyNamed('fullName'),
        ),
      ).thenThrow(Exception('signup failed'));

      final model = SignupViewModel();
      model.fullNameController.text = 'Test User';
      model.emailController.text = 'user@schoolable.com';
      model.passwordController.text = 'password123';
      model.confirmPasswordController.text = 'password123';

      await model.signUp();

      verify(
        dialogService.showDialog(
          title: 'Signup Failed',
          description: anyNamed('description'),
        ),
      ).called(1);
      model.dispose();
    });
  });
}
