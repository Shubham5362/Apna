// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../core/providers.dart';
import '../core/theme.dart';
import 'widgets/reusable_widgets.dart';

// ----------------------------------------------------
// ASHOKA CHAKRA PAINTER
// ----------------------------------------------------
class AshokaChakraPainter extends CustomPainter {
  final Color color;

  AshokaChakraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw outer circle
    canvas.drawCircle(center, radius, paint);

    // Draw inner small circle
    canvas.drawCircle(center, radius * 0.15, paint..style = PaintingStyle.fill);

    // Draw middle circle
    final middlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.9, middlePaint);

    // Draw 24 spokes
    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final outerX = center.dx + radius * 0.9 * math.cos(angle);
      final outerY = center.dy + radius * 0.9 * math.sin(angle);
      canvas.drawLine(center, Offset(outerX, outerY), spokePaint);

      // Draw small semi-circular structures (spoke heads)
      final headAngle = angle + (math.pi / 24);
      final headX = center.dx + radius * 0.93 * math.cos(headAngle);
      final headY = center.dy + radius * 0.93 * math.sin(headAngle);
      canvas.drawCircle(
        Offset(headX, headY),
        radius * 0.02,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// MODERN APNA MANDLA LOGO PAINTER (NO INDIAN FLAG)
// ----------------------------------------------------
class ApnaMandlaLogoPainter extends CustomPainter {
  final Color color;

  ApnaMandlaLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw mandala outer intricate circles
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius * 0.95, paint);

    final dashedPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer concentric circle
    canvas.drawCircle(center, radius * 0.8, dashedPaint);

    // Intricate inner mandala petal paths
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8;
      final x1 = center.dx + radius * 0.5 * math.cos(angle);
      final y1 = center.dy + radius * 0.5 * math.sin(angle);

      final nextAngle = ((i + 1) * 2 * math.pi) / 8;
      final x2 = center.dx + radius * 0.5 * math.cos(nextAngle);
      final y2 = center.dy + radius * 0.5 * math.sin(nextAngle);

      final cpAngle = angle + (math.pi / 8);
      final cpx = center.dx + radius * 0.75 * math.cos(cpAngle);
      final cpy = center.dy + radius * 0.75 * math.sin(cpAngle);

      path.moveTo(x1, y1);
      path.quadraticBezierTo(cpx, cpy, x2, y2);
    }
    canvas.drawPath(path, paint);

    // Central marketplace seed icon (Shopping bag + leaves)
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.3, fillPaint);

    // Glowing dot in center
    canvas.drawCircle(center, radius * 0.08, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// PREMIUM LOGIN SCREEN
// ----------------------------------------------------
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _transitionController;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _otpCompletedController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _fullNameFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  bool _isFocused = false;
  bool _isRegistering = false;
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen to focus changes
    _phoneFocusNode.addListener(_handleFocusChange);
    _fullNameFocusNode.addListener(_handleFocusChange);
    _otpFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _transitionController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _otpCompletedController.dispose();
    _phoneFocusNode.removeListener(_handleFocusChange);
    _fullNameFocusNode.removeListener(_handleFocusChange);
    _otpFocusNode.removeListener(_handleFocusChange);
    _phoneFocusNode.dispose();
    _fullNameFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus =
        _phoneFocusNode.hasFocus ||
        _fullNameFocusNode.hasFocus ||
        _otpFocusNode.hasFocus;
    if (hasFocus != _isFocused) {
      setState(() {
        _isFocused = hasFocus;
      });
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      AppSnackbar.show(
        context,
        message: 'कृपया वैध मोबाइल नंबर दर्ज करें (Invalid phone)',
        isError: true,
      );
      return;
    }

    if (_isRegistering && fullName.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'कृपया पूरा नाम दर्ज करें (Full name is required)',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      if (_isRegistering) {
        await apiClient.register(phone, fullName);
      } else {
        await apiClient.loginInit(phone);
      }

      setState(() {
        _otpSent = true;
      });
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'ओटीपी सफलतापूर्वक भेजा गया! (OTP sent successfully!)',
        );
      }
    } on DioException catch (e) {
      String errMsg = 'त्रुटि हुई (An error occurred)';
      if (e.response != null && e.response!.data is Map) {
        final data = e.response!.data;
        if (data['error'] != null && data['error']['message'] != null) {
          errMsg = data['error']['message'];
        } else if (data['detail'] != null) {
          errMsg = data['detail'].toString();
        }
      } else if (e.message != null) {
        errMsg = e.message!;
      }
      if (mounted) {
        AppSnackbar.show(context, message: errMsg, isError: true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: e.toString(), isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyAndLogin() async {
    final phone = _phoneController.text.trim();
    final otp = _otpCompletedController.text.trim();

    if (otp.length < 6) {
      AppSnackbar.show(
        context,
        message: 'कृपया 6-अंकीय ओटीपी पूरा करें (OTP must be 6 digits)',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.verifyOtp(phone, otp);
      final token = res['access_token'];
      ref.read(authTokenProvider.notifier).state = token;

      if (mounted) {
        _showSuccessAnimation();
      }
    } on DioException catch (e) {
      String errMsg = 'अमान्य ओटीपी (Invalid OTP)';
      if (e.response != null && e.response!.data is Map) {
        final data = e.response!.data;
        if (data['error'] != null && data['error']['message'] != null) {
          errMsg = data['error']['message'];
        } else if (data['detail'] != null) {
          errMsg = data['detail'].toString();
        }
      } else if (e.message != null) {
        errMsg = e.message!;
      }
      if (mounted) {
        AppSnackbar.show(context, message: errMsg, isError: true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: e.toString(), isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessAnimation() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: SuccessScreen(
              message:
                  'अपना मांडला में आपका स्वागत है! (Welcome to Apna Mandla!)',
              onButtonPressed: () {
                context.go('/dashboard');
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define alignment of Ashoka Chakra dynamically based on active focus
    final chakraAlignment = _isFocused
        ? Alignment.center
        : (isMobile ? Alignment.bottomCenter : Alignment.centerRight);

    // Smooth animated properties
    final double chakraSize = isMobile ? 350 : 500;
    final double cardWidth = isMobile ? double.infinity : 420;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // ----------------------------------------------------
            // SLOW CONTINUOUS ROTATING BACKGROUND ASHOKA CHAKRA
            // ----------------------------------------------------
            AnimatedAlign(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutCubic,
              alignment: chakraAlignment,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Opacity(
                      opacity: isDark ? 0.04 : 0.06,
                      child: Container(
                        width: chakraSize,
                        height: chakraSize,
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: CustomPaint(
                          painter: AshokaChakraPainter(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ----------------------------------------------------
            // MAIN SCROLLABLE CONTENT
            // ----------------------------------------------------
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Logo Section
                    Hero(
                      tag: 'apna_mandla_logo',
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CustomPaint(
                          painter: ApnaMandlaLogoPainter(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // APNA MANDLA
                    Text(
                      'APNA MANDLA',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Hindi Tagline
                    Text(
                      '"अपने शहर के अपने लोग, अपना डिजिटल बाज़ार"',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ----------------------------------------------------
                    // GLASSMORPHISM LOGIN CARD
                    // ----------------------------------------------------
                    Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.xxl,
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.white.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 24,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.xxl,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          child: Form(
                            key: _formKey,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _buildOtpLoginForm(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpLoginForm() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('otp_form'),
      children: [
        Text(
          _isRegistering ? 'नया खाता बनाएँ (Register)' : 'लॉगिन करें (Login)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        if (_isRegistering && !_otpSent) ...[
          AppTextField(
            labelText: 'पूरा नाम (Full Name)',
            hintText: 'John Doe',
            prefixIcon: Icons.person_outline_rounded,
            controller: _fullNameController,
            focusNode: _fullNameFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'कृपया पूरा नाम दर्ज करें (Full name is required)';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.m),
        ],
        AppTextField(
          labelText: 'मोबाइल नंबर (Mobile Number)',
          hintText: '9876543210',
          prefixIcon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'कृपया मोबाइल नंबर दर्ज करें (Phone is required)';
            }
            if (value.length < 10) {
              return 'अमान्य मोबाइल नंबर (Must be 10 digits)';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.l),
        if (!_otpSent) ...[
          PrimaryButton(
            text: _isRegistering
                ? 'रजिस्टर करें और ओटीपी भेजें (Register & Send OTP)'
                : 'ओटीपी भेजें (Send OTP)',
            isLoading: _isLoading,
            onPressed: _sendOtp,
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: () {
              setState(() {
                _isRegistering = !_isRegistering;
              });
            },
            child: Text(
              _isRegistering
                  ? 'पहले से ही खाता है? लॉगिन करें (Have an account? Login)'
                  : 'नया खाता बनाएँ (Don\'t have an account? Register)',
            ),
          ),
        ] else ...[
          Text(
            'हमने आपके नंबर पर ओटीपी भेजा है। (We sent an OTP to your phone.)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          OtpInput(
            length: 6,
            onCompleted: (otp) {
              _otpCompletedController.text = otp;
              _verifyAndLogin();
            },
          ),
          const SizedBox(height: AppSpacing.l),
          PrimaryButton(
            text: 'सत्यापित करें और लॉगिन (Verify & Login)',
            isLoading: _isLoading,
            onPressed: _verifyAndLogin,
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: () {
              setState(() {
                _otpSent = false;
              });
            },
            child: const Text('दूसरा नंबर उपयोग करें (Use different number)'),
          ),
        ],
      ],
    );
  }
}
