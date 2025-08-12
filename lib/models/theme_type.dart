import 'package:flutter/material.dart';

/// Enum representing different theme types in the application
enum ThemeType {
  /// Standard light theme - available to all users
  light,
  
  /// Standard dark theme - available to all users  
  dark,
  
  /// Futuristic theme with blue/tech aesthetic - Pro only
  futuristic,
  
  /// Neon theme with vibrant colors - Pro only
  neon,
  
  /// Floral theme with nature-inspired colors - Pro only
  floral,
}

/// Extension to provide additional functionality for ThemeType
extension ThemeTypeExtension on ThemeType {
  /// Check if this theme requires Pro subscription
  bool get isPremium {
    switch (this) {
      case ThemeType.light:
      case ThemeType.dark:
        return false;
      case ThemeType.futuristic:
      case ThemeType.neon:
      case ThemeType.floral:
        return true;
    }
  }

  /// Get display name for the theme
  String get displayName {
    switch (this) {
      case ThemeType.light:
        return 'Light';
      case ThemeType.dark:
        return 'Dark';
      case ThemeType.futuristic:
        return 'Futuristic';
      case ThemeType.neon:
        return 'Neon';
      case ThemeType.floral:
        return 'Floral';
    }
  }

  /// Get description for the theme
  String get description {
    switch (this) {
      case ThemeType.light:
        return 'Clean and bright interface';
      case ThemeType.dark:
        return 'Easy on the eyes in low light';
      case ThemeType.futuristic:
        return 'Sleek tech-inspired design';
      case ThemeType.neon:
        return 'Vibrant cyberpunk aesthetic';
      case ThemeType.floral:
        return 'Nature-inspired colors';
    }
  }

  /// Get icon for the theme
  IconData get icon {
    switch (this) {
      case ThemeType.light:
        return Icons.light_mode;
      case ThemeType.dark:
        return Icons.dark_mode;
      case ThemeType.futuristic:
        return Icons.auto_awesome;
      case ThemeType.neon:
        return Icons.electric_bolt;
      case ThemeType.floral:
        return Icons.local_florist;
    }
  }

  /// Get primary color preview for the theme
  Color get previewColor {
    switch (this) {
      case ThemeType.light:
        return const Color(0xFF2563EB); // Blue
      case ThemeType.dark:
        return const Color(0xFF3B82F6); // Lighter blue
      case ThemeType.futuristic:
        return const Color(0xFF06B6D4); // Cyan
      case ThemeType.neon:
        return const Color(0xFFEC4899); // Pink
      case ThemeType.floral:
        return const Color(0xFF10B981); // Green
    }
  }

  /// Get the lock icon status for Pro themes
  bool get showLockIcon => isPremium;

  /// Convert to string for persistence
  String toStringValue() => toString().split('.').last;

  /// Create ThemeType from string
  static ThemeType fromString(String value) {
    return ThemeType.values.firstWhere(
      (type) => type.toStringValue() == value,
      orElse: () => ThemeType.dark, // Default fallback
    );
  }

  /// Get all free themes
  static List<ThemeType> get freeThemes => [
    ThemeType.light,
    ThemeType.dark,
  ];

  /// Get all premium themes
  static List<ThemeType> get premiumThemes => [
    ThemeType.futuristic,
    ThemeType.neon,
    ThemeType.floral,
  ];

  /// Get all themes
  static List<ThemeType> get allThemes => ThemeType.values;
}