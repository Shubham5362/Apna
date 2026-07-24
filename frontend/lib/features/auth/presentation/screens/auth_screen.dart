import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/rotating_chakra_bg.dart';
import 'login_view.dart';

class AuthScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: Stack(
        children: [
          // Background Rotating Ashok Chakra
          const Positioned(
            bottom: -150,
            left: -100,
            right: -100,
            child: Center(child: RotatingChakraBg(size: 600)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 56,
                                height: 56,
                                color: AppColors.primaryGreen,
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'APNA ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'MANDLA',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    const Text(
                      'अपने शहर के अपने लोग, अपना डिजिटल बाज़ार।',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Auth Form Card Container
                    Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Consumer<AuthController>(
                        builder: (context, controller, child) {
                          switch (controller.currentView) {
                            case AuthViewMode.login:
                              return LoginView(onLoginSuccess: onLoginSuccess);
                            case AuthViewMode.signup:
                              return _SignUpViewPlaceholder();
                            case AuthViewMode.forgotPassword:
                              return _ForgotPasswordViewPlaceholder();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpViewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<AuthController>();
    return Column(
      children: [
        const Text(
          'Create Account',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Register with Apna Mandla as Customer, Shop, or Rider.'),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => controller.setView(AuthViewMode.login),
          child: const Text('Back to Log In'),
        ),
      ],
    );
  }
}

class _ForgotPasswordViewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<AuthController>();
    return Column(
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Enter your registered mobile number to receive OTP.'),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => controller.setView(AuthViewMode.login),
          child: const Text('Back to Log In'),
        ),
      ],
    );
  }
}
