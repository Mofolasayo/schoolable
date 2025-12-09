import 'package:flutter_test/flutter_test.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/ui/views/home/home_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  HomeViewModel getModel() => HomeViewModel();

  group('HomeViewModel Tests -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    group('Construction -', () {
      test('When constructing, should initialize with empty announcements', () {
        final model = getModel();
        expect(model.announcements, isEmpty);
      });
    });
  });
}
