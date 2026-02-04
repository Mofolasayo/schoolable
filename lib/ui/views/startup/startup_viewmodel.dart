import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/notification_service.dart';
import 'package:schoolable/services/logging_service.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _backend = locator<BackendApiService>();
  final _notificationService = NotificationService();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check if user has a stored JWT token
    final hasSession = await _backend.hasSession();

    if (hasSession) {
      try {
        // Use the dedicated endpoint to check profile completion status from database
        AppLogger.log('📋 Checking profile completion status...');
        final completionStatus = await _backend.checkProfileComplete();
        AppLogger.log('📋 Startup completion status: $completionStatus');

        // If we get a valid response (no error), we have a valid session
        if (completionStatus['error'] == null) {
          final bool isComplete = completionStatus['is_complete'] == true;
          final email = completionStatus['email'] ?? '';
          final fullName = completionStatus['full_name'] ?? '';

          if (!isComplete) {
            // Profile incomplete, navigate to complete profile
            AppLogger.log('⚠️ Profile not complete. Going to CompleteProfileView.');
            _navigationService.replaceWithCompleteProfileView(
              email: email,
              fullName: fullName,
            );
          } else {
            // Profile complete, navigate to home
            AppLogger.log('✅ Profile complete. Going to HomeView.');
            await _notificationService.initialize(forceRegister: true);
            _navigationService.replaceWithHomeView();
          }
          return;
        }
      } catch (e) {
        // Token is invalid or expired, clear session and go to login
        AppLogger.log('Session validation failed: $e');
        await _backend.clearSession();
      }
    }

    // No valid session, go to login
    _navigationService.replaceWithLoginView();
  }
}