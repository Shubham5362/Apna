import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color? warmCreamBackground;
  final Color? glassmorphismBorder;
  final Color? glassmorphismBackground;
  final List<BoxShadow>? softShadows;

  const AppThemeExtension({
    required this.warmCreamBackground,
    required this.glassmorphismBorder,
    required this.glassmorphismBackground,
    required this.softShadows,
  });

  @override
  AppThemeExtension copyWith({
    Color? warmCreamBackground,
    Color? glassmorphismBorder,
    Color? glassmorphismBackground,
    List<BoxShadow>? softShadows,
  }) {
    return AppThemeExtension(
      warmCreamBackground: warmCreamBackground ?? this.warmCreamBackground,
      glassmorphismBorder: glassmorphismBorder ?? this.glassmorphismBorder,
      glassmorphismBackground:
          glassmorphismBackground ?? this.glassmorphismBackground,
      softShadows: softShadows ?? this.softShadows,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      warmCreamBackground: Color.lerp(
        warmCreamBackground,
        other.warmCreamBackground,
        t,
      ),
      glassmorphismBorder: Color.lerp(
        glassmorphismBorder,
        other.glassmorphismBorder,
        t,
      ),
      glassmorphismBackground: Color.lerp(
        glassmorphismBackground,
        other.glassmorphismBackground,
        t,
      ),
      softShadows: other.softShadows, // Simple replace
    );
  }
}
