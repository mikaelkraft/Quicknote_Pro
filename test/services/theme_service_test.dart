import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/services/theme/theme_service.dart';
import 'package:quicknote_pro/theme/app_theme.dart';

void main() {
  group('ThemeService', () {
    late ThemeService service;

    setUp(() async {
      // Clear any existing SharedPreferences
      SharedPreferences.setMockInitialValues({});
      service = ThemeService();
      await service.initialize();
    });

    test('should start with default light theme', () {
      expect(service.selectedTheme, 'default_light');
      expect(service.themeMode, ThemeMode.system);
      expect(service.accentColor, null);
    });

    test('should update selected theme', () async {
      await service.setSelectedTheme('futuristic');
      expect(service.selectedTheme, 'futuristic');
    });

    test('should get correct theme data by ID', () {
      final lightTheme = AppTheme.getThemeById('default_light');
      final darkTheme = AppTheme.getThemeById('default_dark');
      final futuristicTheme = AppTheme.getThemeById('futuristic');
      
      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
      expect(futuristicTheme, isNotNull);
      
      // Verify theme brightness
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      expect(futuristicTheme.brightness, Brightness.dark);
    });

    test('should return available themes correctly', () {
      final allThemes = service.getAvailableThemes(includeProThemes: true);
      final freeThemes = service.getAvailableThemes(includeProThemes: false);
      
      expect(allThemes.length, 5); // 2 free + 3 pro themes
      expect(freeThemes.length, 2); // Only free themes
      
      expect(allThemes.containsKey('futuristic'), true);
      expect(freeThemes.containsKey('futuristic'), false);
    });

    test('should persist theme settings', () async {
      await service.setSelectedTheme('neon');
      await service.setThemeMode(ThemeMode.dark);
      
      // Create new service instance to simulate app restart
      final newService = ThemeService();
      await newService.initialize();
      
      expect(newService.selectedTheme, 'neon');
      expect(newService.themeMode, ThemeMode.dark);
    });

    test('should reset to defaults', () async {
      await service.setSelectedTheme('floral');
      await service.setThemeMode(ThemeMode.dark);
      
      await service.resetToDefaults();
      
      expect(service.selectedTheme, 'default_light');
      expect(service.themeMode, ThemeMode.system);
      expect(service.accentColor, null);
    });

    test('should handle invalid theme ID gracefully', () {
      final fallbackTheme = AppTheme.getThemeById('invalid_theme');
      expect(fallbackTheme, AppTheme.lightTheme);
    });
  });

  group('AppTheme', () {
    test('should have correct theme definitions', () {
      final themes = AppTheme.availableThemes;
      
      expect(themes.length, 5);
      expect(themes['default_light']?.isPro, false);
      expect(themes['default_dark']?.isPro, false);
      expect(themes['futuristic']?.isPro, true);
      expect(themes['neon']?.isPro, true);
      expect(themes['floral']?.isPro, true);
    });

    test('should generate Pro themes with correct colors', () {
      final futuristicTheme = AppTheme.getThemeById('futuristic');
      final neonTheme = AppTheme.getThemeById('neon');
      final floralTheme = AppTheme.getThemeById('floral');
      
      // Verify primary colors match our Pro theme definitions
      expect(futuristicTheme.colorScheme.primary, AppTheme.futuristicPrimary);
      expect(neonTheme.colorScheme.primary, AppTheme.neonPrimary);
      expect(floralTheme.colorScheme.primary, AppTheme.floralPrimary);
      
      // Verify surface colors
      expect(futuristicTheme.colorScheme.surface, AppTheme.futuristicSurface);
      expect(neonTheme.colorScheme.surface, AppTheme.neonSurface);
      expect(floralTheme.colorScheme.surface, AppTheme.floralSurface);
    });

    test('should have preview colors for all themes', () {
      final themes = AppTheme.availableThemes;
      
      for (final theme in themes.values) {
        expect(theme.previewColors.isNotEmpty, true);
        expect(theme.previewColors.length, greaterThanOrEqualTo(3));
      }
    });
  });
}