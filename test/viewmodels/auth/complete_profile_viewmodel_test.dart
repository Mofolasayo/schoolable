import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/ui/views/auth/complete_profile/complete_profile_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CompleteProfileViewModel Tests -', () {
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

    test('loadReferenceData populates departments and job levels', () async {
      when(backend.getDepartments()).thenAnswer(
        (_) async => ['Engineering', 'HR'],
      );
      when(backend.getJobLevels()).thenAnswer(
        (_) async => [
          {'levelNumber': 3},
          {'levelNumber': 1},
        ],
      );
      when(backend.getReferenceData()).thenAnswer(
        (_) async => {
          'genders': ['Male', 'Female'],
        },
      );

      final model = CompleteProfileViewModel(
        email: 'user@schoolable.com',
        fullName: 'Test User',
      );

      await model.loadReferenceData();

      expect(model.departments, ['Engineering', 'HR']);
      expect(model.employeeLevels, [1, 3]);
      expect(model.genders, ['Male', 'Female']);
      expect(model.isLoadingReferenceData, isFalse);
      model.dispose();
    });

    test('completeProfile navigates to HomeView on success', () async {
      when(
        backend.completeProfile(
          employeeId: anyNamed('employeeId'),
          phone: anyNamed('phone'),
          department: anyNamed('department'),
          role: anyNamed('role'),
          dateJoined: anyNamed('dateJoined'),
          gender: anyNamed('gender'),
          dateOfBirth: anyNamed('dateOfBirth'),
          address: anyNamed('address'),
          city: anyNamed('city'),
          state: anyNamed('state'),
          isTeamLead: anyNamed('isTeamLead'),
          employeeLevel: anyNamed('employeeLevel'),
        ),
      ).thenAnswer((_) async {});

      final model = CompleteProfileViewModel(
        email: 'user@schoolable.com',
        fullName: 'Test User',
      );

      model.employeeIdController.text = 'EMP-1';
      model.phoneController.text = '1234567890';
      model.roleController.text = 'Engineer';
      model.selectedDepartment = 'Engineering';
      model.selectedEmployeeLevel = 2;
      model.dateJoined = DateTime(2024, 1, 1);

      await model.completeProfile();

      verify(
        navigationService.clearStackAndShow<dynamic>(
          Routes.homeView,
          arguments: anyNamed('arguments'),
          id: anyNamed('id'),
          parameters: anyNamed('parameters'),
        ),
      ).called(1);
      verifyNever(
        dialogService.showDialog(
          title: 'Save Failed',
          description: anyNamed('description'),
          buttonTitle: anyNamed('buttonTitle'),
        ),
      );
      model.dispose();
    });
  });
}
