import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Stitch design tokens
  static const background = Color(0xFF0A0C10);
  static const surface = Color(0xFF111318);
  static const surfaceContainer = Color(0xFF1E2024);
  static const surfaceContainerLow = Color(0xFF1A1C20);
  static const surfaceContainerHigh = Color(0xFF282A2E);
  static const surfaceContainerHighest = Color(0xFF333539);
  static const surfaceContainerLowest = Color(0xFF0C0E12);
  static const surfaceVariant = Color(0xFF333539);

  static const primary = Color(0xFFE1DFFF);
  static const primaryContainer = Color(0xFFC0C1FF);
  static const onPrimary = Color(0xFF292B5E);
  static const onPrimaryContainer = Color(0xFF4B4D83);

  static const secondary = Color(0xFF4CD7F6);
  static const secondaryContainer = Color(0xFF03B5D4);
  static const onSecondary = Color(0xFF003640);

  static const tertiary = Color(0xFFFFDCC5);
  static const tertiaryContainer = Color(0xFFFFB783);
  static const onTertiary = Color(0xFF4F2500);

  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const onError = Color(0xFF690005);

  static const onSurface = Color(0xFFE2E2E8);
  static const onSurfaceVariant = Color(0xFFC7C5D0);
  static const outline = Color(0xFF918F9A);
  static const outlineVariant = Color(0xFF46464F);
  static const inversePrimary = Color(0xFF585990);

  // Semantic aliases for backward compatibility
  static const accentBlue = primary;
  static const accentCyan = secondary;
  static const accentViolet = Color(0xFF8B5CF6);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const textPrimary = onSurface;
  static const textSecondary = onSurfaceVariant;
  static const textMuted = outline;
  static const card = surfaceContainerLow;
  static const cardBorder = outlineVariant;
  static const divider = outlineVariant;

  // Glass card decoration helpers
  static const glassBackground = Color(0xEB16171A);
  static const glassBorder = Color(0x14FFFFFF);

  static BoxDecoration glassCard({double radius = 16, Color? borderColor}) {
    return BoxDecoration(
      color: glassBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? glassBorder, width: 1),
    );
  }

  static const logoGradient = LinearGradient(
    colors: [inversePrimary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outlineVariant, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        indicatorColor: primary.withOpacity(0.15),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: outline, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                color: primary, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.inter(color: outline, fontSize: 11);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: outline, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        labelStyle: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12),
        side: const BorderSide(color: outlineVariant),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: outlineVariant, space: 1),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: outlineVariant,
        overlayColor: primary.withOpacity(0.12),
        valueIndicatorColor: primaryContainer,
        valueIndicatorTextStyle: GoogleFonts.inter(
            color: onPrimaryContainer, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceContainerHigh,
        contentTextStyle: GoogleFonts.inter(color: onSurface, fontSize: 13),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outlineVariant),
        ),
        titleTextStyle: GoogleFonts.inter(
            color: onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        contentTextStyle:
            GoogleFonts.inter(color: onSurfaceVariant, fontSize: 13),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge
            ?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
        displayMedium: textTheme.displayMedium
            ?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
        headlineLarge: textTheme.headlineLarge?.copyWith(
            color: onSurface, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: textTheme.headlineMedium?.copyWith(
            color: onSurface, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: textTheme.headlineSmall?.copyWith(
            color: onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: textTheme.titleLarge?.copyWith(
            color: onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: textTheme.titleMedium?.copyWith(
            color: onSurface, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: textTheme.titleSmall?.copyWith(
            color: onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500),
        bodyLarge:
            textTheme.bodyLarge?.copyWith(color: onSurface, fontSize: 14),
        bodyMedium: textTheme.bodyMedium
            ?.copyWith(color: onSurfaceVariant, fontSize: 13),
        bodySmall:
            textTheme.bodySmall?.copyWith(color: outline, fontSize: 12),
        labelLarge: textTheme.labelLarge?.copyWith(
            color: onSurface, fontSize: 13, fontWeight: FontWeight.w600),
        labelMedium: textTheme.labelMedium
            ?.copyWith(color: onSurfaceVariant, fontSize: 12),
        labelSmall:
            textTheme.labelSmall?.copyWith(color: outline, fontSize: 11),
      ),
    );
  }
}
