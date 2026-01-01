// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i13;
import 'package:flutter/material.dart';
import 'package:schoolable/ui/views/auth/complete_profile/complete_profile_view.dart'
    as _i6;
import 'package:schoolable/ui/views/auth/forgot_password/forgot_password_view.dart'
    as _i7;
import 'package:schoolable/ui/views/auth/login_view.dart' as _i4;
import 'package:schoolable/ui/views/auth/reset_password/reset_password_view.dart'
    as _i8;
import 'package:schoolable/ui/views/auth/signup/signup_view.dart' as _i5;
import 'package:schoolable/ui/views/auth/verify_otp/verify_otp_view.dart'
    as _i10;
import 'package:schoolable/ui/views/home/home_view.dart' as _i2;
import 'package:schoolable/ui/views/onboarding/onboarding_view.dart' as _i9;
import 'package:schoolable/ui/views/profile/growth_view.dart' as _i11;
import 'package:schoolable/ui/views/profile/security_view.dart' as _i12;
import 'package:schoolable/ui/views/startup/startup_view.dart' as _i3;
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i14;

class Routes {
  static const homeView = '/home-view';

  static const startupView = '/startup-view';

  static const loginView = '/login-view';

  static const signupView = '/signup-view';

  static const completeProfileView = '/complete-profile-view';

  static const forgotPasswordView = '/forgot-password-view';

  static const resetPasswordView = '/reset-password-view';

  static const onboardingView = '/onboarding-view';

  static const verifyOtpView = '/verify-otp-view';

  static const growthView = '/growth-view';

  static const securityView = '/security-view';

  static const all = <String>{
    homeView,
    startupView,
    loginView,
    signupView,
    completeProfileView,
    forgotPasswordView,
    resetPasswordView,
    onboardingView,
    verifyOtpView,
    growthView,
    securityView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.homeView,
      page: _i2.HomeView,
    ),
    _i1.RouteDef(
      Routes.startupView,
      page: _i3.StartupView,
    ),
    _i1.RouteDef(
      Routes.loginView,
      page: _i4.LoginView,
    ),
    _i1.RouteDef(
      Routes.signupView,
      page: _i5.SignupView,
    ),
    _i1.RouteDef(
      Routes.completeProfileView,
      page: _i6.CompleteProfileView,
    ),
    _i1.RouteDef(
      Routes.forgotPasswordView,
      page: _i7.ForgotPasswordView,
    ),
    _i1.RouteDef(
      Routes.resetPasswordView,
      page: _i8.ResetPasswordView,
    ),
    _i1.RouteDef(
      Routes.onboardingView,
      page: _i9.OnboardingView,
    ),
    _i1.RouteDef(
      Routes.verifyOtpView,
      page: _i10.VerifyOtpView,
    ),
    _i1.RouteDef(
      Routes.growthView,
      page: _i11.GrowthView,
    ),
    _i1.RouteDef(
      Routes.securityView,
      page: _i12.SecurityView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.HomeView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i2.HomeView(),
        settings: data,
      );
    },
    _i3.StartupView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i3.StartupView(),
        settings: data,
      );
    },
    _i4.LoginView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i4.LoginView(),
        settings: data,
      );
    },
    _i5.SignupView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i5.SignupView(),
        settings: data,
      );
    },
    _i6.CompleteProfileView: (data) {
      final args = data.getArgs<CompleteProfileViewArguments>(nullOk: false);
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => _i6.CompleteProfileView(
            key: args.key, email: args.email, fullName: args.fullName),
        settings: data,
      );
    },
    _i7.ForgotPasswordView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i7.ForgotPasswordView(),
        settings: data,
      );
    },
    _i8.ResetPasswordView: (data) {
      final args = data.getArgs<ResetPasswordViewArguments>(nullOk: false);
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i8.ResetPasswordView(key: args.key, code: args.code),
        settings: data,
      );
    },
    _i9.OnboardingView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i9.OnboardingView(),
        settings: data,
      );
    },
    _i10.VerifyOtpView: (data) {
      final args = data.getArgs<VerifyOtpViewArguments>(nullOk: false);
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => _i10.VerifyOtpView(
            key: args.key,
            email: args.email,
            isPasswordReset: args.isPasswordReset),
        settings: data,
      );
    },
    _i11.GrowthView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i11.GrowthView(),
        settings: data,
      );
    },
    _i12.SecurityView: (data) {
      return _i13.MaterialPageRoute<dynamic>(
        builder: (context) => const _i12.SecurityView(),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class CompleteProfileViewArguments {
  const CompleteProfileViewArguments({
    this.key,
    required this.email,
    required this.fullName,
  });

  final _i13.Key? key;

  final String email;

  final String fullName;

  @override
  String toString() {
    return '{"key": "$key", "email": "$email", "fullName": "$fullName"}';
  }

  @override
  bool operator ==(covariant CompleteProfileViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.email == email &&
        other.fullName == fullName;
  }

  @override
  int get hashCode {
    return key.hashCode ^ email.hashCode ^ fullName.hashCode;
  }
}

class ResetPasswordViewArguments {
  const ResetPasswordViewArguments({
    this.key,
    required this.code,
  });

  final _i13.Key? key;

  final String code;

  @override
  String toString() {
    return '{"key": "$key", "code": "$code"}';
  }

  @override
  bool operator ==(covariant ResetPasswordViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.code == code;
  }

  @override
  int get hashCode {
    return key.hashCode ^ code.hashCode;
  }
}

class VerifyOtpViewArguments {
  const VerifyOtpViewArguments({
    this.key,
    required this.email,
    this.isPasswordReset = false,
  });

  final _i13.Key? key;

  final String email;

  final bool isPasswordReset;

  @override
  String toString() {
    return '{"key": "$key", "email": "$email", "isPasswordReset": "$isPasswordReset"}';
  }

  @override
  bool operator ==(covariant VerifyOtpViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.email == email &&
        other.isPasswordReset == isPasswordReset;
  }

  @override
  int get hashCode {
    return key.hashCode ^ email.hashCode ^ isPasswordReset.hashCode;
  }
}

extension NavigatorStateExtension on _i14.NavigationService {
  Future<dynamic> navigateToHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.homeView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToLoginView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.loginView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSignupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.signupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToCompleteProfileView({
    _i13.Key? key,
    required String email,
    required String fullName,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.completeProfileView,
        arguments: CompleteProfileViewArguments(
            key: key, email: email, fullName: fullName),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToForgotPasswordView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.forgotPasswordView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToResetPasswordView({
    _i13.Key? key,
    required String code,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.resetPasswordView,
        arguments: ResetPasswordViewArguments(key: key, code: code),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToOnboardingView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.onboardingView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVerifyOtpView({
    _i13.Key? key,
    required String email,
    bool isPasswordReset = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.verifyOtpView,
        arguments: VerifyOtpViewArguments(
            key: key, email: email, isPasswordReset: isPasswordReset),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToGrowthView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.growthView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSecurityView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.securityView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.homeView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithLoginView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.loginView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSignupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.signupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithCompleteProfileView({
    _i13.Key? key,
    required String email,
    required String fullName,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.completeProfileView,
        arguments: CompleteProfileViewArguments(
            key: key, email: email, fullName: fullName),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithForgotPasswordView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.forgotPasswordView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithResetPasswordView({
    _i13.Key? key,
    required String code,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.resetPasswordView,
        arguments: ResetPasswordViewArguments(key: key, code: code),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithOnboardingView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.onboardingView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVerifyOtpView({
    _i13.Key? key,
    required String email,
    bool isPasswordReset = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.verifyOtpView,
        arguments: VerifyOtpViewArguments(
            key: key, email: email, isPasswordReset: isPasswordReset),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithGrowthView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.growthView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSecurityView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.securityView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
