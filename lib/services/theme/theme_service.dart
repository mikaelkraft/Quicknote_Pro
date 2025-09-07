import 'package:flutter/foundation.dart';
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
  bool _isInitialized = false;
  
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
    if (_isInitialized) return;
    
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      await _loadSettings();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize theme service: $e');
      // Ensure we still mark as initialized to prevent infinite retry
      _isInitialized = true;
    }
  }
  
  /// Load theme settings from storage
  Future<void> _loadSettings() async {
    if (!_isInitialized) return;
    
    try {
      // Load theme mode
      final themeModeIndex = _box.get(_themeModeKey, defaultValue: ThemeMode.system.index);
      if (themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeModeIndex];
      }
      
      // Load accent color
      final accentColorValue = _box.get(_accentColorKey);
      if (accentColorValue != null && accentColorValue is int) {
        _accentColor = Color(accentColorValue);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme settings: $e');
      // If loading fails, use defaults
      _themeMode = ThemeMode.system;
      _accentColor = null;
      notifyListeners();
    }
  }
  
  /// Set the theme mode and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    if (!_isInitialized || _themeMode == mode) return;
    
    try {
      _themeMode = mode;
      await _box.put(_themeModeKey, mode.index);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
      // Revert on failure
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  /// Set the accent color and persist it
  Future<void> setAccentColor(Color? color) async {
    if (!_isInitialized || _accentColor == color) return;
    
    try {
      _accentColor = color;
      if (color != null) {
        await _box.put(_accentColorKey, color.value);
      } else {
        await _box.delete(_accentColorKey);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save accent color: $e');
      // Revert on failure
      _accentColor = null;
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
    try {
      if (_isInitialized) {
        _box.close();
      }
    } catch (e) {
      debugPrint('Error closing theme service box: $e');
    }
    super.dispose();
  }
}