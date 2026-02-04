import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/startup/startup_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/firebase_test_helpers.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(setupFirebaseCoreMocks);

  group('StartupViewModel Tests -', () {
    late MockNavigationService navigationService;
    late MockBackendApiService backend;

    setUp(() {
      registerServices();
      navigationService = locator<NavigationService>() as MockNavigationService;
      backend = locator<BackendApiService>() as MockBackendApiService;
    });

    tearDown(() => locator.reset());

    test('navigates to login when no session exists', () async {
      when(backend.hasSession()).thenAnswer((_) async => false);

      final model = StartupViewModel();
      await model.runStartupLogic();

      verify(
        navigationService.replaceWith<dynamic>(
          Routes.loginView,
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).called(1);
    });

    test('navigates to complete profile when profile is incomplete', () async {
      when(backend.hasSession()).thenAnswer((_) async => true);
      when(backend.checkProfileComplete()).thenAnswer(
        (_) async => {
          'is_complete': false,
          'email': 'user@schoolable.com',
          'full_name': 'Test User',
        },
      );

      final model = StartupViewModel();
      await model.runStartupLogic();

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
    });

    test('navigates to home when profile is complete', () async {
      when(backend.hasSession()).thenAnswer((_) async => true);
      when(backend.checkProfileComplete()).thenAnswer(
        (_) async => {
          'is_complete': true,
          'email': 'user@schoolable.com',
          'full_name': 'Test User',
        },
      );

      final model = StartupViewModel();
      await model.runStartupLogic();

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
    });

    test('clears session and navigates to login on validation failure', () async {
      when(backend.hasSession()).thenAnswer((_) async => true);
      when(backend.checkProfileComplete())
          .thenThrow(Exception('expired token'));
      when(backend.clearSession()).thenAnswer((_) async {});

      final model = StartupViewModel();
      await model.runStartupLogic();

      verify(backend.clearSession()).called(1);
      verify(
        navigationService.replaceWith<dynamic>(
          Routes.loginView,
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).called(1);
    });
  });
}
