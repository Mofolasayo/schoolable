import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/auth/login_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/firebase_test_helpers.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupFirebaseCoreMocks);

  group('LoginViewModel Tests -', () {
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

    test('navigates to CompleteProfileView when profile incomplete', () async {
      when(
        backend.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer(
        (_) async => {
          'token': 'token',
          'profile': {'id': 'user-1'},
        },
      );
      when(backend.checkProfileComplete()).thenAnswer(
        (_) async => {
          'is_complete': false,
          'email': 'user@schoolable.com',
          'full_name': 'Test User',
        },
      );

      final model = LoginViewModel();
      model.emailController.text = 'user@schoolable.com';
      model.passwordController.text = 'password123';

      await model.signIn();

      final captured = verify(
        navigationService.replaceWith<dynamic>(
          Routes.completeProfileView,
          arguments: captureAnyNamed('arguments'),
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).captured;

      final args = captured.single as CompleteProfileViewArguments;
      expect(args.email, 'user@schoolable.com');
      expect(args.fullName, 'Test User');
      model.dispose();
    });

    test('navigates to HomeView when profile complete', () async {
      when(
        backend.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer(
        (_) async => {
          'token': 'token',
          'profile': {'id': 'user-1'},
        },
      );
      when(backend.checkProfileComplete()).thenAnswer(
        (_) async => {
          'is_complete': true,
          'email': 'user@schoolable.com',
          'full_name': 'Test User',
          'profile_completed_at': '2024-01-01',
        },
      );

      final model = LoginViewModel();
      model.emailController.text = 'user@schoolable.com';
      model.passwordController.text = 'password123';

      await model.signIn();

      verify(
        navigationService.replaceWith<dynamic>(
          Routes.homeView,
          arguments: anyNamed('arguments'),
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).called(1);
      model.dispose();
    });

    test('shows dialog when signIn fails', () async {
      when(
        backend.signIn(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(Exception('bad credentials'));

      final model = LoginViewModel();
      model.emailController.text = 'user@schoolable.com';
      model.passwordController.text = 'bad-password';

      await model.signIn();

      verify(
        dialogService.showDialog(
          title: 'Login Failed',
          description: anyNamed('description'),
        ),
      ).called(1);
      model.dispose();
    });
  });
}
