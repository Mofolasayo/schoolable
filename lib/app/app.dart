import 'package:schoolable/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:schoolable/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:schoolable/ui/views/home/home_view.dart';
import 'package:schoolable/ui/views/startup/startup_view.dart';
import 'package:schoolable/ui/views/auth/login_view.dart';
import 'package:schoolable/ui/views/auth/signup/signup_view.dart';
import 'package:schoolable/ui/views/auth/complete_profile/complete_profile_view.dart';
import 'package:schoolable/ui/views/auth/forgot_password/forgot_password_view.dart';
import 'package:schoolable/ui/views/onboarding/onboarding_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/supabase_service.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: SignupView),
    MaterialRoute(page: CompleteProfileView),
    MaterialRoute(page: ForgotPasswordView),
    MaterialRoute(page: OnboardingView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: SupabaseService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
