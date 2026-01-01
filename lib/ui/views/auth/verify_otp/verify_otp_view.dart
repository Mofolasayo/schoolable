import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'verify_otp_viewmodel.dart';

class VerifyOtpView extends StackedView<VerifyOtpViewModel> {
  final String email;
  final bool isPasswordReset;

  const VerifyOtpView({
    Key? key,
    required this.email,
    this.isPasswordReset = false,
  }) : super(key: key);

  @override
  Widget builder(
      BuildContext context, VerifyOtpViewModel viewModel, Widget? child) {
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
                    'assets/images/schoolable_logo.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  isPasswordReset ? 'Reset Password' : 'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: kcTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPasswordReset
                      ? 'Enter the 6-digit code sent to'
                      : 'We sent a verification code to',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: kcTextMutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: kcPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 48),
                _buildPinCodeField(viewModel),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.isBusy || !viewModel.isCodeComplete
                        ? null
                        : viewModel.verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kcPrimaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kcPrimaryColor.withOpacity(0.5),
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
                        : Text(
                            isPasswordReset ? 'Continue' : 'Verify Email',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Didn\'t receive the code?',
                      style: TextStyle(
                        color: kcTextMutedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          viewModel.isResending ? null : viewModel.resendOTP,
                      child: viewModel.isResending
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CupertinoActivityIndicator(),
                            )
                          : const Text(
                              'Resend',
                              style: TextStyle(
                                color: kcPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isPasswordReset
                          ? 'Remember your password?'
                          : 'Wrong email?',
                      style: const TextStyle(
                        color: kcTextMutedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: viewModel.goToSignup,
                      child: Text(
                        isPasswordReset ? 'Sign In' : 'Go back',
                        style: const TextStyle(
                          color: kcPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kcPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kcPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: kcPrimaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Check your spam folder if you don\'t see the email',
                          style: TextStyle(
                            fontSize: 13,
                            color: kcPrimaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _buildPinCodeField(VerifyOtpViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: viewModel.pinControllers[index],
            focusNode: viewModel.focusNodes[index],
            maxLength: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kcTextColor,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: viewModel.pinControllers[index].text.isNotEmpty
                  ? kcPrimaryColor.withOpacity(0.05)
                  : kcBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: viewModel.pinControllers[index].text.isNotEmpty
                      ? kcPrimaryColor.withOpacity(0.5)
                      : kcBorderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcPrimaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                viewModel.focusNodes[index + 1].requestFocus();
              }
              viewModel.updateCode();
            },
            onTap: () {
              viewModel.pinControllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: viewModel.pinControllers[index].text.length,
              );
            },
          ),
        );
      }),
    );
  }

  @override
  VerifyOtpViewModel viewModelBuilder(BuildContext context) =>
      VerifyOtpViewModel(email: email, isPasswordReset: isPasswordReset);
}
