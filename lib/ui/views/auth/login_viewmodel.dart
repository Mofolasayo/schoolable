import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

class LoginViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();

  bool obscurePassword = true;
  bool rememberMe = true;

  void togglePassword() {
    obscurePassword = !obscurePassword;
    rebuildUi();
  }

  void toggleRememberMe(bool value) {
    rememberMe = value;
    rebuildUi();
  }

  void signIn() {
    _nav.replaceWithHomeView();
  }
}
