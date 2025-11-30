import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/ui/common/app_colors.dart';
import 'login_viewmodel.dart';

class LoginView extends StackedView<LoginViewModel> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget builder(
      BuildContext context, LoginViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: kcBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kcBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/schoolable_logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: kcTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to keep tracking tasks, attendance, and updates.',
                style: TextStyle(
                  fontSize: 14,
                  color: kcTextMutedColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kcBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                       hintStyle: const TextStyle(color: kcTextMutedColor),
                        hintText: 'name@company.com',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: kcTextMutedColor),
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
                          borderSide: const BorderSide(
                            color: kcPrimaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: kcSurfaceColor,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: viewModel.obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                       hintStyle: const TextStyle(color: kcTextMutedColor),

                        prefixIcon: const Icon(Icons.lock_outline,
                            color: kcTextMutedColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            viewModel.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: kcTextMutedColor,
                          ),
                          onPressed: viewModel.togglePassword,
                        ),
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
                          borderSide: const BorderSide(
                            color: kcPrimaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: kcSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Row(
                    //   children: [
                    //     Switch(
                    //       value: viewModel.rememberMe,
                    //       activeColor: kcPrimaryColor,
                    //       onChanged: viewModel.toggleRememberMe,
                    //     ),
                    //     const SizedBox(width: 4),
                    //     const Text(
                    //       'Keep me signed in',
                    //       style: TextStyle(
                    //         color: kcTextColor,
                    //         fontWeight: FontWeight.w600,
                    //         fontSize: 13,
                    //       ),
                    //     ),
                    //     const Spacer(),
                    //     TextButton(
                    //       onPressed: () {},
                    //       child: const Text(
                    //         'Forgot password?',
                    //         style: TextStyle(
                    //           color: kcPrimaryColor,
                    //           fontWeight: FontWeight.w700,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: viewModel.signIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // OutlinedButton(
                    //   onPressed: viewModel.signIn,
                    //   style: OutlinedButton.styleFrom(
                    //     foregroundColor: kcPrimaryColor,
                    //     side: const BorderSide(color: kcPrimaryColor),
                    //     padding: const EdgeInsets.symmetric(vertical: 16),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //   ),
                    //   child: const Text(
                    //     'Continue as guest',
                    //     style: TextStyle(
                    //       fontSize: 15,
                    //       fontWeight: FontWeight.w700,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New to Schoolable?',
                    style: TextStyle(
                      color: kcTextMutedColor,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        color: kcPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();
}
