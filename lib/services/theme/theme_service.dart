import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service to manage theme settings with persistence
/// Supports system/light/dark theme modes and optional accent colors
class ThemeService extends ChangeNotifier {
  static const String _boxName = 'theme_settings';
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  
  late Box _box;
  ThemeMode _themeMode = ThemeMode.system;
  Color? _accentColor;
  
  // Available accent colors for customization
  static const List<Color> availableAccentColors = [
    Color(0xFF8B5CF6), // Purple (default)
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFFEC4899), // Pink
  ];
  
  ThemeMode get themeMode => _themeMode;
  Color? get accentColor => _accentColor;
  
  /// Initialize the theme service and load saved settings
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    await _loadSettings();
  }
  
  /// Load theme settings from storage
  Future<void> _loadSettings() async {
    try {
      // Load theme mode
      final themeModeIndex = _box.get(_themeModeKey, defaultValue: ThemeMode.system.index);
      _themeMode = ThemeMode.values[themeModeIndex];
      
      // Load accent color
      final accentColorValue = _box.get(_accentColorKey);
      if (accentColorValue != null) {
        _accentColor = Color(accentColorValue);
      }
      
      notifyListeners();
    } catch (e) {
      // If loading fails, use defaults
      _themeMode = ThemeMode.system;
      _accentColor = null;
    }
  }
  
  /// Set the theme mode and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _box.put(_themeModeKey, mode.index);
      notifyListeners();
    }
  }
  
  /// Set the accent color and persist it
  Future<void> setAccentColor(Color? color) async {
    if (_accentColor != color) {
      _accentColor = color;
      if (color != null) {
        await _box.put(_accentColorKey, color.value);
      } else {
        await _box.delete(_accentColorKey);
      }
      notifyListeners();
    }
  }
  
  /// Get theme mode as string for UI display
  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  /// Set theme mode from string
  Future<void> setThemeModeFromString(String modeString) async {
    ThemeMode mode;
    switch (modeString.toLowerCase()) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'system':
      default:
        mode = ThemeMode.system;
        break;
    }
    await setThemeMode(mode);
  }
  
  /// Dispose of resources
  @override
  void dispose() {
    _box.close();
    super.dispose();
  }
}