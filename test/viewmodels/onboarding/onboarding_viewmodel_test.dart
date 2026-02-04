import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/ui/views/onboarding/onboarding_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('OnboardingViewModel Tests -', () {
    late MockNavigationService navigationService;

    setUp(() {
      registerServices();
      navigationService = locator<NavigationService>() as MockNavigationService;
    });

    tearDown(() => locator.reset());

    test('tracks page changes and last page state', () {
      final model = OnboardingViewModel();

      expect(model.currentPage, 0);
      expect(model.isLastPage, isFalse);

      model.updatePage(model.slides.length - 1);

      expect(model.isLastPage, isTrue);
      model.controller.dispose();
    });

    test('next on last page navigates to login', () {
      final model = OnboardingViewModel();
      model.updatePage(model.slides.length - 1);

      model.next();

      verify(
        navigationService.replaceWith<dynamic>(
          Routes.loginView,
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).called(1);
      model.controller.dispose();
    });

    test('skip navigates to login', () {
      final model = OnboardingViewModel();

      model.skip();

      verify(
        navigationService.replaceWith<dynamic>(
          Routes.loginView,
          id: anyNamed('id'),
          preventDuplicates: anyNamed('preventDuplicates'),
          parameters: anyNamed('parameters'),
          transition: anyNamed('transition'),
        ),
      ).called(1);
      model.controller.dispose();
    });
  });
}
