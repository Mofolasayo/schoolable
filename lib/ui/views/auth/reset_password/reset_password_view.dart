import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'reset_password_viewmodel.dart';

class ResetPasswordView extends StackedView<ResetPasswordViewModel> {
  final String code;

  const ResetPasswordView({
    Key? key,
    required this.code,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, ResetPasswordViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/worksight_logo.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Create New Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your new password must be different from previously used passwords.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: kcTextMutedColor,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: viewModel.passwordController,
                  obscureText: !viewModel.showPassword,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: kcTextMutedColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        viewModel.showPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: kcTextMutedColor,
                        size: 20,
                      ),
                      onPressed: viewModel.togglePasswordVisibility,
                    ),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: viewModel.confirmPasswordController,
                  obscureText: !viewModel.showConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle:
                        const TextStyle(color: kcTextMutedColor, fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: kcTextMutedColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        viewModel.showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: kcTextMutedColor,
                        size: 20,
                      ),
                      onPressed: viewModel.toggleConfirmPasswordVisibility,
                    ),
                    filled: true,
                    fillColor: kcBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kcPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        viewModel.isBusy ? null : viewModel.resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kcPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: viewModel.isBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kcPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: viewModel.hasMinLength
                                ? kcPrimaryColor
                                : kcTextMutedColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'At least 8 characters',
                            style: TextStyle(
                              fontSize: 13,
                              color: viewModel.hasMinLength
                                  ? kcPrimaryColor
                                  : kcTextMutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: viewModel.passwordsMatch
                                ? kcPrimaryColor
                                : kcTextMutedColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Passwords match',
                            style: TextStyle(
                              fontSize: 13,
                              color: viewModel.passwordsMatch
                                  ? kcPrimaryColor
                                  : kcTextMutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  ResetPasswordViewModel viewModelBuilder(BuildContext context) =>
      ResetPasswordViewModel(code: code);
}
