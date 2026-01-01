import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:stacked_services/stacked_services.dart';

class SecurityViewModel extends BaseViewModel {
  final _backendApi = locator<BackendApiService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  /// Show confirmation dialog and delete account if confirmed
  Future<void> confirmDeleteAccount() async {
    final response = await _dialogService.showConfirmationDialog(
      title: 'Delete Account',
      description:
          'Are you sure you want to permanently delete your account? This action cannot be undone and you will lose all your data.',
      confirmationTitle: 'Delete',
      cancelTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response?.confirmed == true) {
      await deleteAccount();
    }
  }

  /// Delete the user's account
  Future<void> deleteAccount() async {
    _isDeleting = true;
    notifyListeners();

    try {
      await _backendApi.deleteMyAccount();

      // Show success message
      await _dialogService.showDialog(
        title: 'Account Deleted',
        description:
            'Your account has been successfully deleted. You will now be logged out.',
      );

      // Navigate to login screen
      _navigationService.clearStackAndShow(Routes.loginView);
    } catch (e) {
      await _dialogService.showDialog(
        title: 'Error',
        description: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Navigate back
  void goBack() {
    _navigationService.back();
  }
}
