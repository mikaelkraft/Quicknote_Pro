import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Service to manage theme state with persistence and reactive updates.
/// 
/// Provides centralized theme management that persists across app restarts
/// and notifies listeners when theme changes occur. Enhanced with additional
/// theme variants as requested.
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _themeVariantKey = 'theme_variant';

  ThemeMode _themeMode = ThemeMode.system;
  Color? _accentColor;
  String _themeVariant = 'Light';
  SharedPreferences? _prefs;

  /// Current theme mode (system, light, or dark)
  ThemeMode get themeMode => _themeMode;

  /// Current accent color (null for default)
  Color? get accentColor => _accentColor;

  /// Current theme variant (Light, Dark, Futuristic, Neon, Floral)
  String get themeVariant => _themeVariant;

  /// Get the current theme data based on variant
  ThemeData get currentThemeData => AppTheme.getThemeByName(_themeVariant);

  /// Get all available theme variants
  List<String> get availableThemes => AppTheme.getAvailableThemes();

  /// Initialize the theme service and load saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemeSettings();
  }

  /// Load theme settings from shared preferences
  Future<void> _loadThemeSettings() async {
    if (_prefs == null) return;

    // Load theme mode
    final themeModeString = _prefs!.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }

    // Load theme variant
    _themeVariant = _prefs!.getString(_themeVariantKey) ?? 'Light';

    // Load accent color
    final accentColorValue = _prefs!.getInt(_accentColorKey);
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }

    notifyListeners();
  }

  /// Update theme mode and persist the change
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    
    if (_prefs != null) {
      await _prefs!.setString(_themeModeKey, mode.toString());
    }
    
    notifyListeners();
  }

  /// Set theme variant and persist the change
  Future<void> setThemeVariant(String variant) async {
    if (_themeVariant == variant) return;
    if (!AppTheme.getAvailableThemes().contains(variant)) return;

    _themeVariant = variant;
    
    if (_prefs != null) {
      await _prefs!.setString(_themeVariantKey, variant);
    }
    
    notifyListeners();
  }

  /// Update accent color and persist the change
  Future<void> setAccentColor(Color? color) async {
    if (_accentColor == color) return;

    _accentColor = color;
    
    if (_prefs != null) {
      if (color != null) {
        await _prefs!.setInt(_accentColorKey, color.value);
      } else {
        await _prefs!.remove(_accentColorKey);
      }
    }
    
    notifyListeners();
  }

  /// Get display name for theme mode
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  /// Get description for theme variant
  String getThemeDescription(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'light':
        return 'Clean and minimal design with excellent readability';
      case 'dark':
        return 'Easy on the eyes with sophisticated dark colors';
      case 'futuristic':
        return 'High-tech aesthetic with neon accents and enhanced contrasts';
      case 'neon':
        return 'Vibrant glowing colors with maximum visual impact';
      case 'floral':
        return 'Warm and natural colors inspired by botanical elements';
      default:
        return 'Custom theme variant';
    }
  }

  /// Get all available theme modes
  List<ThemeMode> get availableThemeModes => ThemeMode.values;

  /// Check if current theme is dark (considering system theme)
  bool isDarkMode(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
    }
  }

  /// Check if current theme variant is dark-based
  bool get isDarkTheme {
    return ['Dark', 'Futuristic', 'Neon'].contains(_themeVariant);
  }

  /// Get theme preview colors for theme selector UI
  Map<String, Color> getThemePreviewColors(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'light':
        return {
          'primary': AppTheme.primaryLight,
          'surface': AppTheme.surfaceLight,
          'background': AppTheme.backgroundLight,
        };
      case 'dark':
        return {
          'primary': AppTheme.primaryDark,
          'surface': AppTheme.surfaceDark,
          'background': AppTheme.backgroundDark,
        };
      case 'futuristic':
        return {
          'primary': AppTheme.futuristicPrimary,
          'surface': AppTheme.futuristicSurface,
          'background': AppTheme.futuristicBackground,
        };
      case 'neon':
        return {
          'primary': AppTheme.neonPrimary,
          'surface': AppTheme.neonSurface,
          'background': AppTheme.neonBackground,
        };
      case 'floral':
        return {
          'primary': AppTheme.floralPrimary,
          'surface': AppTheme.floralSurface,
          'background': AppTheme.floralBackground,
        };
      default:
        return {
          'primary': AppTheme.primaryLight,
          'surface': AppTheme.surfaceLight,
          'background': AppTheme.backgroundLight,
        };
    }
  }

  /// Reset to default theme settings
  Future<void> resetToDefaults() async {
    await setThemeMode(ThemeMode.system);
    await setThemeVariant('Light');
    await setAccentColor(null);
  }
}