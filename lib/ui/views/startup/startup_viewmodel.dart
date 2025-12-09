import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/supabase_service.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _supabaseService = locator<SupabaseService>();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    await Future.delayed(const Duration(seconds: 3));

    // This is where you can make decisions on where your app should navigate when
    // you have custom startup logic

    // Check if user is logged in
    if (_supabaseService.currentUser != null) {
      _navigationService.replaceWithHomeView();
    } else {
      // Not logged in
      _navigationService.replaceWithLoginView();
    }
  }
}
