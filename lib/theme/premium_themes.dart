import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/theme_type.dart';

/// Premium theme configurations for Pro subscribers
/// 
/// Defines Futuristic, Neon, and Floral themes with unique color palettes
/// and styling that provides premium visual experience.
class PremiumThemes {
  PremiumThemes._();

  // Futuristic Theme Colors - Tech/Sci-fi inspired
  static const Color futuristicPrimary = Color(0xFF06B6D4); // Cyan
  static const Color futuristicSecondary = Color(0xFF0F172A); // Deep slate
  static const Color futuristicAccent = Color(0xFF8B5CF6); // Purple
  static const Color futuristicBackground = Color(0xFF020617); // Almost black
  static const Color futuristicSurface = Color(0xFF0F172A); // Dark slate
  static const Color futuristicText = Color(0xFF0CF9FF); // Bright cyan
  static const Color futuristicTextSecondary = Color(0xFF64748B); // Muted gray

  // Neon Theme Colors - Vibrant cyberpunk aesthetic
  static const Color neonPrimary = Color(0xFFEC4899); // Hot pink
  static const Color neonSecondary = Color(0xFF8B5CF6); // Purple
  static const Color neonAccent = Color(0xFF06FFA5); // Neon green
  static const Color neonBackground = Color(0xFF0A0A0A); // Almost black
  static const Color neonSurface = Color(0xFF1A1A2E); // Dark purple
  static const Color neonText = Color(0xFFFFFFFF); // White
  static const Color neonTextSecondary = Color(0xFFE879F9); // Light pink

  // Floral Theme Colors - Nature-inspired palette
  static const Color floralPrimary = Color(0xFF10B981); // Emerald green
  static const Color floralSecondary = Color(0xFFF59E0B); // Warm amber
  static const Color floralAccent = Color(0xFFEC4899); // Pink
  static const Color floralBackground = Color(0xFFFAFDF2); // Very light green
  static const Color floralSurface = Color(0xFFFFFFFF); // White
  static const Color floralText = Color(0xFF064E3B); // Dark green
  static const Color floralTextSecondary = Color(0xFF6B7280); // Gray

  /// Get theme data for a specific premium theme type
  static ThemeData getThemeData(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.futuristic:
        return _buildFuturisticTheme();
      case ThemeType.neon:
        return _buildNeonTheme();
      case ThemeType.floral:
        return _buildFloralTheme();
      default:
        throw ArgumentError('$themeType is not a premium theme');
    }
  }

  /// Build Futuristic theme - Tech/Sci-fi aesthetic
  static ThemeData _buildFuturisticTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: futuristicPrimary,
        onPrimary: Colors.black,
        primaryContainer: futuristicPrimary.withAlpha(51),
        onPrimaryContainer: futuristicPrimary,
        secondary: futuristicSecondary,
        onSecondary: futuristicText,
        secondaryContainer: futuristicSecondary.withAlpha(153),
        onSecondaryContainer: futuristicText,
        tertiary: futuristicAccent,
        onTertiary: Colors.white,
        tertiaryContainer: futuristicAccent.withAlpha(51),
        onTertiaryContainer: futuristicAccent,
        error: const Color(0xFFFF5555),
        onError: Colors.black,
        surface: futuristicSurface,
        onSurface: futuristicText,
        onSurfaceVariant: futuristicTextSecondary,
        outline: futuristicPrimary.withAlpha(77),
        outlineVariant: futuristicPrimary.withAlpha(51),
        shadow: Colors.black.withAlpha(128),
        scrim: Colors.black87,
        inverseSurface: futuristicText,
        onInverseSurface: futuristicBackground,
        inversePrimary: futuristicBackground,
      ),
      scaffoldBackgroundColor: futuristicBackground,
      cardColor: futuristicSurface,
      dividerColor: futuristicPrimary.withAlpha(77),
      
      appBarTheme: AppBarTheme(
        backgroundColor: futuristicSurface,
        foregroundColor: futuristicText,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: futuristicPrimary.withAlpha(128),
        surfaceTintColor: futuristicPrimary.withAlpha(26),
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: futuristicText,
        ),
      ),
      
      textTheme: _buildFuturisticTextTheme(),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: futuristicPrimary,
          elevation: 8,
          shadowColor: futuristicPrimary.withAlpha(128),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: futuristicPrimary, width: 1),
          ),
        ),
      ),
      
      cardTheme: CardTheme(
        color: futuristicSurface,
        elevation: 8,
        shadowColor: futuristicPrimary.withAlpha(77),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: futuristicPrimary.withAlpha(77), width: 1),
        ),
      ),
    );
  }

  /// Build Neon theme - Vibrant cyberpunk aesthetic
  static ThemeData _buildNeonTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: neonPrimary,
        onPrimary: Colors.white,
        primaryContainer: neonPrimary.withAlpha(51),
        onPrimaryContainer: neonPrimary,
        secondary: neonSecondary,
        onSecondary: Colors.white,
        secondaryContainer: neonSecondary.withAlpha(51),
        onSecondaryContainer: neonSecondary,
        tertiary: neonAccent,
        onTertiary: Colors.black,
        tertiaryContainer: neonAccent.withAlpha(51),
        onTertiaryContainer: neonAccent,
        error: const Color(0xFFFF3366),
        onError: Colors.white,
        surface: neonSurface,
        onSurface: neonText,
        onSurfaceVariant: neonTextSecondary,
        outline: neonPrimary.withAlpha(128),
        outlineVariant: neonPrimary.withAlpha(77),
        shadow: neonPrimary.withAlpha(77),
        scrim: Colors.black87,
        inverseSurface: neonText,
        onInverseSurface: neonBackground,
        inversePrimary: neonBackground,
      ),
      scaffoldBackgroundColor: neonBackground,
      cardColor: neonSurface,
      dividerColor: neonPrimary.withAlpha(128),
      
      appBarTheme: AppBarTheme(
        backgroundColor: neonSurface,
        foregroundColor: neonText,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: neonPrimary.withAlpha(128),
        surfaceTintColor: neonPrimary.withAlpha(26),
        titleTextStyle: GoogleFonts.audiowide(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: neonText,
        ),
      ),
      
      textTheme: _buildNeonTextTheme(),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: neonPrimary,
          elevation: 8,
          shadowColor: neonPrimary.withAlpha(128),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: neonAccent, width: 2),
          ),
        ),
      ),
      
      cardTheme: CardTheme(
        color: neonSurface,
        elevation: 8,
        shadowColor: neonPrimary.withAlpha(77),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neonPrimary.withAlpha(128), width: 1),
        ),
      ),
    );
  }

  /// Build Floral theme - Nature-inspired aesthetic
  static ThemeData _buildFloralTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: floralPrimary,
        onPrimary: Colors.white,
        primaryContainer: floralPrimary.withAlpha(26),
        onPrimaryContainer: floralPrimary,
        secondary: floralSecondary,
        onSecondary: Colors.white,
        secondaryContainer: floralSecondary.withAlpha(26),
        onSecondaryContainer: floralSecondary,
        tertiary: floralAccent,
        onTertiary: Colors.white,
        tertiaryContainer: floralAccent.withAlpha(26),
        onTertiaryContainer: floralAccent,
        error: const Color(0xFFDC2626),
        onError: Colors.white,
        surface: floralSurface,
        onSurface: floralText,
        onSurfaceVariant: floralTextSecondary,
        outline: floralPrimary.withAlpha(77),
        outlineVariant: floralPrimary.withAlpha(51),
        shadow: Colors.black.withAlpha(26),
        scrim: Colors.black54,
        inverseSurface: floralText,
        onInverseSurface: floralBackground,
        inversePrimary: floralBackground,
      ),
      scaffoldBackgroundColor: floralBackground,
      cardColor: floralSurface,
      dividerColor: floralPrimary.withAlpha(77),
      
      appBarTheme: AppBarTheme(
        backgroundColor: floralSurface,
        foregroundColor: floralText,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: floralPrimary.withAlpha(77),
        surfaceTintColor: floralPrimary.withAlpha(26),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: floralText,
        ),
      ),
      
      textTheme: _buildFloralTextTheme(),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: floralPrimary,
          elevation: 4,
          shadowColor: floralPrimary.withAlpha(77),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      
      cardTheme: CardTheme(
        color: floralSurface,
        elevation: 4,
        shadowColor: floralPrimary.withAlpha(51),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Build text theme for Futuristic theme
  static TextTheme _buildFuturisticTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.orbitron(fontSize: 57, fontWeight: FontWeight.w700, color: futuristicText),
      displayMedium: GoogleFonts.orbitron(fontSize: 45, fontWeight: FontWeight.w700, color: futuristicText),
      displaySmall: GoogleFonts.orbitron(fontSize: 36, fontWeight: FontWeight.w600, color: futuristicText),
      headlineLarge: GoogleFonts.orbitron(fontSize: 32, fontWeight: FontWeight.w600, color: futuristicText),
      headlineMedium: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.w600, color: futuristicText),
      headlineSmall: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.w600, color: futuristicText),
      titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500, color: futuristicText),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: futuristicText),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: futuristicText),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: futuristicText),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: futuristicText),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: futuristicTextSecondary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: futuristicText),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: futuristicTextSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: futuristicTextSecondary),
    );
  }

  /// Build text theme for Neon theme
  static TextTheme _buildNeonTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.audiowide(fontSize: 57, fontWeight: FontWeight.w700, color: neonText),
      displayMedium: GoogleFonts.audiowide(fontSize: 45, fontWeight: FontWeight.w700, color: neonText),
      displaySmall: GoogleFonts.audiowide(fontSize: 36, fontWeight: FontWeight.w600, color: neonText),
      headlineLarge: GoogleFonts.audiowide(fontSize: 32, fontWeight: FontWeight.w600, color: neonText),
      headlineMedium: GoogleFonts.audiowide(fontSize: 28, fontWeight: FontWeight.w600, color: neonText),
      headlineSmall: GoogleFonts.audiowide(fontSize: 24, fontWeight: FontWeight.w600, color: neonText),
      titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500, color: neonText),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: neonText),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: neonText),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: neonText),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: neonText),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: neonTextSecondary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: neonText),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: neonTextSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: neonTextSecondary),
    );
  }

  /// Build text theme for Floral theme
  static TextTheme _buildFloralTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.w700, color: floralText),
      displayMedium: GoogleFonts.playfairDisplay(fontSize: 45, fontWeight: FontWeight.w700, color: floralText),
      displaySmall: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w600, color: floralText),
      headlineLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w600, color: floralText),
      headlineMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w600, color: floralText),
      headlineSmall: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600, color: floralText),
      titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500, color: floralText),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: floralText),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: floralText),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: floralText),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: floralText),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: floralTextSecondary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: floralText),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: floralTextSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: floralTextSecondary),
    );
  }
}