import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/theme_type.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeType', () {
    test('should identify premium themes correctly', () {
      expect(ThemeType.light.isPremium, false);
      expect(ThemeType.dark.isPremium, false);
      expect(ThemeType.futuristic.isPremium, true);
      expect(ThemeType.neon.isPremium, true);
      expect(ThemeType.floral.isPremium, true);
    });

    test('should provide correct display names', () {
      expect(ThemeType.light.displayName, 'Light');
      expect(ThemeType.dark.displayName, 'Dark');
      expect(ThemeType.futuristic.displayName, 'Futuristic');
      expect(ThemeType.neon.displayName, 'Neon');
      expect(ThemeType.floral.displayName, 'Floral');
    });

    test('should provide correct descriptions', () {
      expect(ThemeType.light.description, 'Clean and bright interface');
      expect(ThemeType.dark.description, 'Easy on the eyes in low light');
      expect(ThemeType.futuristic.description, 'Sleek tech-inspired design');
      expect(ThemeType.neon.description, 'Vibrant cyberpunk aesthetic');
      expect(ThemeType.floral.description, 'Nature-inspired colors');
    });

    test('should provide appropriate icons', () {
      expect(ThemeType.light.icon, Icons.light_mode);
      expect(ThemeType.dark.icon, Icons.dark_mode);
      expect(ThemeType.futuristic.icon, Icons.auto_awesome);
      expect(ThemeType.neon.icon, Icons.electric_bolt);
      expect(ThemeType.floral.icon, Icons.local_florist);
    });

    test('should show lock icon for premium themes only', () {
      expect(ThemeType.light.showLockIcon, false);
      expect(ThemeType.dark.showLockIcon, false);
      expect(ThemeType.futuristic.showLockIcon, true);
      expect(ThemeType.neon.showLockIcon, true);
      expect(ThemeType.floral.showLockIcon, true);
    });

    test('should convert to and from string correctly', () {
      for (final theme in ThemeType.values) {
        final stringValue = theme.toStringValue();
        final convertedBack = ThemeType.fromString(stringValue);
        expect(convertedBack, theme);
      }
    });

    test('should handle invalid string conversion gracefully', () {
      final result = ThemeType.fromString('invalid_theme');
      expect(result, ThemeType.dark); // Should fallback to dark
    });

    test('should provide correct theme collections', () {
      expect(ThemeTypeExtension.freeThemes, [ThemeType.light, ThemeType.dark]);
      expect(ThemeTypeExtension.premiumThemes, [
        ThemeType.futuristic,
        ThemeType.neon,
        ThemeType.floral,
      ]);
      expect(ThemeTypeExtension.allThemes, ThemeType.values);
    });

    test('should provide distinct preview colors', () {
      final colors = ThemeType.values.map((theme) => theme.previewColor).toSet();
      expect(colors.length, ThemeType.values.length); // All colors should be unique
    });
  });
}