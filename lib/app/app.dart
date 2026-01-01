import 'package:schoolable/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:schoolable/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:schoolable/ui/views/home/home_view.dart';
import 'package:schoolable/ui/views/startup/startup_view.dart';
import 'package:schoolable/ui/views/auth/login_view.dart';
import 'package:schoolable/ui/views/auth/signup/signup_view.dart';
import 'package:schoolable/ui/views/auth/complete_profile/complete_profile_view.dart';
import 'package:schoolable/ui/views/auth/forgot_password/forgot_password_view.dart';
import 'package:schoolable/ui/views/auth/reset_password/reset_password_view.dart';
import 'package:schoolable/ui/views/onboarding/onboarding_view.dart';
import 'package:schoolable/ui/views/auth/verify_otp/verify_otp_view.dart';
import 'package:schoolable/ui/views/profile/growth_view.dart';
import 'package:schoolable/ui/views/profile/security_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:schoolable/services/backend_api_service.dart';
import 'package:schoolable/services/cache_service.dart';
import 'package:schoolable/services/websocket_service.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: SignupView),
    MaterialRoute(page: CompleteProfileView),
    MaterialRoute(page: ForgotPasswordView),
    MaterialRoute(page: ResetPasswordView),
    MaterialRoute(page: OnboardingView),
    MaterialRoute(page: VerifyOtpView),
    MaterialRoute(page: GrowthView),
    MaterialRoute(page: SecurityView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: BackendApiService),
    LazySingleton(classType: CacheService),
    LazySingleton(classType: WebSocketService),
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
