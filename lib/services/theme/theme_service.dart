import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/theme_type.dart';
import '../../models/entitlement_status.dart';
import '../../theme/app_theme.dart';
import '../../theme/premium_themes.dart';
import '../analytics/analytics_service.dart';
import '../entitlement/entitlement_service.dart';

/// Service to manage theme state with persistence and reactive updates.
/// 
/// Provides centralized theme management that persists across app restarts
/// and notifies listeners when theme changes occur. Handles premium theme
/// access control and automatic fallback for expired subscriptions.
class ThemeService extends ChangeNotifier {
  static const String _themeTypeKey = 'selected_theme_type';
  static const String _accentColorKey = 'accent_color';
  static const String _lastProThemeKey = 'last_pro_theme';

  ThemeType _currentThemeType = ThemeType.dark;
  Color? _accentColor;
  SharedPreferences? _prefs;
  EntitlementService? _entitlementService;
  ThemeType? _lastProTheme; // Track last used Pro theme for fallback scenarios

  /// Current theme type
  ThemeType get currentThemeType => _currentThemeType;

  /// Legacy support - get theme mode based on current theme type
  ThemeMode get themeMode {
    switch (_currentThemeType) {
      case ThemeType.light:
        return ThemeMode.light;
      case ThemeType.dark:
      case ThemeType.futuristic:
      case ThemeType.neon:
        return ThemeMode.dark;
      case ThemeType.floral:
        return ThemeMode.light;
    }
  }

  /// Current accent color (null for default)
  Color? get accentColor => _accentColor;

  /// Get the actual theme data for the current theme type
  ThemeData get currentTheme => getThemeData(_currentThemeType);

  /// Get the actual dark theme data for the current theme type
  ThemeData get currentDarkTheme => getThemeData(_currentThemeType, forceDark: true);

  /// Whether current theme is a premium theme
  bool get isCurrentThemePremium => _currentThemeType.isPremium;

  /// Last used Pro theme (for fallback scenarios)
  ThemeType? get lastProTheme => _lastProTheme;

  /// Initialize the theme service and load saved preferences
  Future<void> initialize({EntitlementService? entitlementService}) async {
    _prefs = await SharedPreferences.getInstance();
    _entitlementService = entitlementService;
    await _loadThemeSettings();
    
    // Listen to entitlement changes for automatic fallback
    _entitlementService?.addListener(_onEntitlementChanged);
  }

  /// Load theme settings from shared preferences
  Future<void> _loadThemeSettings() async {
    if (_prefs == null) return;

    // Load theme type (new system)
    final themeTypeString = _prefs!.getString(_themeTypeKey);
    if (themeTypeString != null) {
      _currentThemeType = ThemeType.fromString(themeTypeString);
    } else {
      // Migration: Check for old theme mode setting
      final themeModeString = _prefs!.getString('theme_mode');
      if (themeModeString != null) {
        if (themeModeString.contains('light')) {
          _currentThemeType = ThemeType.light;
        } else if (themeModeString.contains('dark')) {
          _currentThemeType = ThemeType.dark;
        }
        // Migrate to new system
        await _saveThemeSettings();
      }
    }

    // Validate theme access - fallback if premium theme but no pro access
    if (_currentThemeType.isPremium && (_entitlementService?.isFreeUser ?? true)) {
      await _performThemeFallback(
        fromTheme: _currentThemeType,
        reason: 'subscription_expired',
      );
    }

    // Load accent color
    final accentColorValue = _prefs!.getInt(_accentColorKey);
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }

    // Load last Pro theme
    final lastProThemeString = _prefs!.getString(_lastProThemeKey);
    if (lastProThemeString != null) {
      _lastProTheme = ThemeType.fromString(lastProThemeString);
    }

    notifyListeners();
  }

  /// Save theme settings to shared preferences
  Future<void> _saveThemeSettings() async {
    if (_prefs == null) return;

    await _prefs!.setString(_themeTypeKey, _currentThemeType.toStringValue());
    
    if (_lastProTheme != null) {
      await _prefs!.setString(_lastProThemeKey, _lastProTheme!.toStringValue());
    }
  }

  /// Handle entitlement status changes
  void _onEntitlementChanged() {
    // If user lost Pro access and is using a premium theme, fallback
    if (_currentThemeType.isPremium && (_entitlementService?.isFreeUser ?? true)) {
      _performThemeFallback(
        fromTheme: _currentThemeType,
        reason: 'subscription_expired',
      );
    }
  }

  /// Perform automatic theme fallback when subscription expires
  Future<void> _performThemeFallback({
    required ThemeType fromTheme,
    required String reason,
  }) async {
    final previousTheme = _currentThemeType;
    _currentThemeType = ThemeType.dark; // Default fallback
    
    await _saveThemeSettings();
    notifyListeners();

    // Track analytics
    AnalyticsService.instance.trackThemeFallback(
      fromTheme: previousTheme.displayName,
      toTheme: _currentThemeType.displayName,
      reason: reason,
    );
  }

  /// Set theme type with entitlement validation
  Future<bool> setThemeType(ThemeType themeType) async {
    if (_currentThemeType == themeType) return true;

    final previousTheme = _currentThemeType;

    // Check if user can access premium theme
    if (themeType.isPremium && (_entitlementService?.isFreeUser ?? true)) {
      // Track attempted access to locked theme
      AnalyticsService.instance.trackThemeSelectAttemptLocked(
        themeName: themeType.displayName,
        userType: _entitlementService?.currentStatus.subscriptionType.displayName ?? 'free',
      );
      return false; // Access denied
    }

    _currentThemeType = themeType;

    // Remember Pro theme for potential fallback
    if (themeType.isPremium) {
      _lastProTheme = themeType;
    }

    await _saveThemeSettings();
    notifyListeners();

    // Track successful theme selection
    AnalyticsService.instance.trackThemeSelected(
      themeName: themeType.displayName,
      isPremium: themeType.isPremium,
      userType: _entitlementService?.currentStatus.subscriptionType.displayName ?? 'free',
      previousTheme: previousTheme.displayName,
    );

    return true; // Success
  }

  /// Legacy support - set theme mode (maps to theme types)
  Future<void> setThemeMode(ThemeMode mode) async {
    ThemeType themeType;
    switch (mode) {
      case ThemeMode.light:
        themeType = ThemeType.light;
        break;
      case ThemeMode.dark:
        themeType = ThemeType.dark;
        break;
      case ThemeMode.system:
        // Use current system brightness to determine theme
        themeType = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
            ? ThemeType.dark
            : ThemeType.light;
        break;
    }
    await setThemeType(themeType);
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

  /// Get theme data for a specific theme type
  ThemeData getThemeData(ThemeType themeType, {bool forceDark = false}) {
    switch (themeType) {
      case ThemeType.light:
        return _getAppThemeLight();
      case ThemeType.dark:
        return _getAppThemeDark();
      case ThemeType.futuristic:
      case ThemeType.neon:
      case ThemeType.floral:
        return PremiumThemes.getThemeData(themeType);
    }
  }

  /// Get light theme from AppTheme
  ThemeData _getAppThemeLight() {
    return AppTheme.lightTheme;
  }

  /// Get dark theme from AppTheme
  ThemeData _getAppThemeDark() {
    return AppTheme.darkTheme;
  }

  /// Check if user can access a specific theme
  bool canAccessTheme(ThemeType themeType) {
    if (!themeType.isPremium) return true;
    return _entitlementService?.hasProAccess ?? false;
  }

  /// Get available themes for current user
  List<ThemeType> getAvailableThemes() {
    final hasProAccess = _entitlementService?.hasProAccess ?? false;
    if (hasProAccess) {
      return ThemeType.allThemes;
    } else {
      return ThemeType.freeThemes;
    }
  }

  /// Get locked themes for current user
  List<ThemeType> getLockedThemes() {
    final hasProAccess = _entitlementService?.hasProAccess ?? false;
    if (hasProAccess) {
      return [];
    } else {
      return ThemeType.premiumThemes;
    }
  }

  /// Legacy support - get display name for theme mode
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

  /// Legacy support - get all available theme modes
  List<ThemeMode> get availableThemeModes => ThemeMode.values;

  /// Check if current theme is dark (considering current theme type)
  bool isDarkMode(BuildContext context) {
    switch (_currentThemeType) {
      case ThemeType.light:
      case ThemeType.floral:
        return false;
      case ThemeType.dark:
      case ThemeType.futuristic:
      case ThemeType.neon:
        return true;
    }
  }

  /// Reset to default theme settings
  Future<void> resetToDefaults() async {
    await setThemeType(ThemeType.dark);
    await setAccentColor(null);
  }

  /// Handle Pro upgrade - unlock premium themes
  void onProUpgrade() {
    // If user had a Pro theme before losing access, restore it
    if (_lastProTheme != null && _lastProTheme!.isPremium) {
      setThemeType(_lastProTheme!);
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _entitlementService?.removeListener(_onEntitlementChanged);
    super.dispose();
  }
}