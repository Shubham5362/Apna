import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_input_field.dart';
import '../widgets/phone_input_field.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginView({super.key, required this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final authController = context.read<AuthController>();
    _phoneController = TextEditingController(text: authController.mobileNumber);
    _passwordController = TextEditingController(text: authController.password);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Log In',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Welcome back! Please enter your details',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.subtextColor),
        ),
        const SizedBox(height: 24),

        if (controller.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.errorRed.withOpacity(0.2)),
            ),
            child: Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Toggle Switch: Password vs OTP Mode
        Center(
          child: Container(
            width: 260,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.setLoginMode(LoginTypeMode.password),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: controller.loginMode == LoginTypeMode.password
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow:
                            controller.loginMode == LoginTypeMode.password
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: controller.loginMode == LoginTypeMode.password
                              ? AppColors.primaryGreen
                              : AppColors.subtextColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setLoginMode(LoginTypeMode.otp),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: controller.loginMode == LoginTypeMode.otp
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: controller.loginMode == LoginTypeMode.otp
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'OTP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: controller.loginMode == LoginTypeMode.otp
                              ? AppColors.primaryGreen
                              : AppColors.subtextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Phone Input Field
        PhoneInputField(
          controller: _phoneController,
          onChanged: (val) => controller.setMobileNumber(val),
          suffixWidget:
              controller.loginMode == LoginTypeMode.otp && !controller.otpSent
              ? TextButton(
                  onPressed: controller.mobileNumber.length == 10
                      ? () => controller.handleSendOtp()
                      : null,
                  style: TextButton.styleFrom(
                    backgroundColor: controller.mobileNumber.length == 10
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Get OTP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: controller.mobileNumber.length == 10
                          ? AppColors.primaryGreen
                          : Colors.grey,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Password Input OR OTP View
        if (controller.loginMode == LoginTypeMode.password) ...[
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.subtextColor,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !controller.showPassword,
                    onChanged: (val) => controller.setPassword(val),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter Password',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    controller.showPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.subtextColor,
                  ),
                  onPressed: () => controller.toggleShowPassword(),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => controller.setView(AuthViewMode.forgotPassword),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ] else ...[
          // OTP Mode Digit Fields
          OtpInputField(onCompleted: (val) => controller.setOtp(val)),
          if (controller.otpSent) ...[
            const SizedBox(height: 12),
            Center(
              child: controller.resendTimer > 0
                  ? Text(
                      'Resend OTP in ${controller.resendTimer}s',
                      style: const TextStyle(
                        color: AppColors.subtextColor,
                        fontSize: 14,
                      ),
                    )
                  : TextButton(
                      onPressed: () => controller.handleSendOtp(),
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ],
        ],

        const SizedBox(height: 24),

        // Action Button
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : () async {
                    final success = await controller.handleLogin();
                    if (success) {
                      widget.onLoginSuccess();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: controller.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    controller.loginMode == LoginTypeMode.password
                        ? 'Log In'
                        : 'Verify & Log In',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 28),

        // Sign Up Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(color: AppColors.subtextColor, fontSize: 16),
            ),
            GestureDetector(
              onTap: () => controller.setView(AuthViewMode.signup),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: AppColors.brandOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
