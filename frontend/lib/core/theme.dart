import 'package:flutter/material.dart';
import 'theme_extension.dart';

// GLOBAL COLOR PALETTE
class AppColors {
  // Light Mode Colors
  static const Color primary = Color(0xFF4CAF50); // Indian Green accent
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color secondary = Color(0xFF388E3C);
  static const Color secondaryContainer = Color(0xFFE8F5E9);
  static const Color warmCream = Color(
    0xFFFAF5EF,
  ); // Modern Warm Cream background
  static const Color cardCream = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E2B); // Dark elegant green-gray
  static const Color textSecondary = Color(0xFF556B54);

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF81C784);
  static const Color primaryContainerDark = Color(0xFF2E7D32);
  static const Color secondaryDark = Color(0xFFA5D6A7);
  static const Color secondaryContainerDark = Color(0xFF1B5E20);
  static const Color darkBackground = Color(0xFF121411);
  static const Color cardDark = Color(0xFF1E221C);
  static const Color textPrimaryDark = Color(0xFFE2E3DF);
  static const Color textSecondaryDark = Color(0xFFA4A7A1);

  // Common Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1976D2);
  static const Color border = Color(0xFFD1DCD0);
}

// SPACING SYSTEM
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

// BORDER RADIUS SYSTEM
class AppBorderRadius {
  static const double s = 4.0;
  static const double m = 8.0;
  static const double l = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double circular = 999.0;

  static BorderRadius get radiusSmall => BorderRadius.circular(s);
  static BorderRadius get radiusMedium => BorderRadius.circular(m);
  static BorderRadius get radiusLarge => BorderRadius.circular(l);
  static BorderRadius get radiusExtraLarge => BorderRadius.circular(xl);
  static BorderRadius get radiusCircular => BorderRadius.circular(circular);
}

// ELEVATION SYSTEM (Box Shadows)
class AppElevation {
  static List<BoxShadow> get low => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get high => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

// RESPONSIVE LAYOUT UTILITIES
class ResponsiveLayout {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= mobileBreakpoint) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

// TYPOGRAPHY SYSTEM
class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );
}

// APP THEMES (Material 3)
class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondary,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.cardCream,
        onSurface: AppColors.textPrimary,
        // Deprecated surfaceVariant / onSurfaceVariant replacement in schema
      ),
      scaffoldBackgroundColor: AppColors.warmCream,
      cardColor: AppColors.cardCream,
      dividerColor: AppColors.border,
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusLarge,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      extensions: [
        AppThemeExtension(
          warmCreamBackground: AppColors.warmCream,
          glassmorphismBorder: Colors.white.withOpacity(0.3),
          glassmorphismBackground: Colors.white.withOpacity(0.2),
          softShadows: AppElevation.medium,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        onPrimary: Colors.black,
        primaryContainer: AppColors.primaryContainerDark,
        onPrimaryContainer: AppColors.textPrimaryDark,
        secondary: AppColors.secondaryDark,
        onSecondary: Colors.black,
        secondaryContainer: AppColors.secondaryContainerDark,
        onSecondaryContainer: AppColors.secondaryDark,
        error: AppColors.error,
        onError: Colors.black,
        surface: AppColors.cardDark,
        onSurface: AppColors.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.cardDark,
      dividerColor: Colors.white10,
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radiusLarge,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black12,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.radiusLarge,
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      extensions: [
        AppThemeExtension(
          warmCreamBackground: AppColors.darkBackground,
          glassmorphismBorder: Colors.white.withOpacity(0.1),
          glassmorphismBackground: Colors.black.withOpacity(0.3),
          softShadows: const [],
        ),
      ],
    );
  }
}
