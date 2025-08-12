import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Service to manage theme state with persistence and reactive updates.
/// 
/// Provides centralized theme management that persists across app restarts
/// and notifies listeners when theme changes occur. Supports Pro themes.
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _selectedThemeKey = 'selected_theme';

  ThemeMode _themeMode = ThemeMode.system;
  Color? _accentColor;
  String _selectedTheme = 'default_light';
  SharedPreferences? _prefs;

  /// Current theme mode (system, light, or dark)
  ThemeMode get themeMode => _themeMode;

  /// Current accent color (null for default)
  Color? get accentColor => _accentColor;

  /// Current selected theme ID
  String get selectedTheme => _selectedTheme;

  /// Get the current theme data based on selected theme
  ThemeData get currentTheme => AppTheme.getThemeById(_selectedTheme);

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

    // Load accent color
    final accentColorValue = _prefs!.getInt(_accentColorKey);
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }

    // Load selected theme
    _selectedTheme = _prefs!.getString(_selectedThemeKey) ?? 'default_light';

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

  /// Update selected theme and persist the change
  Future<void> setSelectedTheme(String themeId) async {
    if (_selectedTheme == themeId) return;

    _selectedTheme = themeId;
    
    if (_prefs != null) {
      await _prefs!.setString(_selectedThemeKey, themeId);
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

  /// Reset to default theme settings
  Future<void> resetToDefaults() async {
    await setThemeMode(ThemeMode.system);
    await setAccentColor(null);
    await setSelectedTheme('default_light');
  }

  /// Get available themes (filtered by Pro access if needed)
  Map<String, ThemeDefinition> getAvailableThemes({bool includeProThemes = true}) {
    if (includeProThemes) {
      return AppTheme.availableThemes;
    } else {
      return Map.fromEntries(
        AppTheme.availableThemes.entries.where((entry) => !entry.value.isPro),
      );
    }
  }
}