import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Definition of a theme with metadata for the theme picker
class ThemeDefinition {
  final String id;
  final String name;
  final String description;
  final bool isPro;
  final List<Color> previewColors;

  const ThemeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.isPro,
    required this.previewColors,
  });
}

/// A class that contains all theme configurations for the note-taking application.
/// Implements Contemporary Productivity Minimalism with Adaptive Professional Palette.
/// Includes Pro-only themes for premium users.
class AppTheme {
  AppTheme._();

  /// Available theme types including Pro themes
  static const Map<String, ThemeDefinition> availableThemes = {
    'default_light': ThemeDefinition(
      id: 'default_light',
      name: 'Classic Light',
      description: 'Clean and minimal light theme for productivity',
      isPro: false,
      previewColors: [primaryLight, surfaceLight, backgroundLight],
    ),
    'default_dark': ThemeDefinition(
      id: 'default_dark', 
      name: 'Classic Dark',
      description: 'Comfortable dark theme for low-light environments',
      isPro: false,
      previewColors: [primaryDark, surfaceDark, backgroundDark],
    ),
    'futuristic': ThemeDefinition(
      id: 'futuristic',
      name: 'Futuristic Pro',
      description: 'Sleek cyberpunk-inspired theme with neon accents',
      isPro: true,
      previewColors: [Color(0xFF00FFFF), Color(0xFF1A1A2E), Color(0xFF16213E)],
    ),
    'neon': ThemeDefinition(
      id: 'neon',
      name: 'Neon Pro', 
      description: 'Vibrant neon colors for creative inspiration',
      isPro: true,
      previewColors: [Color(0xFFFF006E), Color(0xFF8338EC), Color(0xFF3A86FF)],
    ),
    'floral': ThemeDefinition(
      id: 'floral',
      name: 'Floral Pro',
      description: 'Nature-inspired theme with soft botanical colors',
      isPro: true,
      previewColors: [Color(0xFF7209B7), Color(0xFFF72585), Color(0xFF4CC9F0)],
    ),
  };

  // Adaptive Professional Palette - Color Specifications
  static const Color primaryLight =
      Color(0xFF2563EB); // Deep blue for primary actions
  static const Color primaryDark =
      Color(0xFF3B82F6); // Lighter blue for dark mode
  static const Color secondaryLight =
      Color(0xFF64748B); // Neutral slate for secondary elements
  static const Color secondaryDark =
      Color(0xFF94A3B8); // Lighter slate for dark mode

  static const Color successLight =
      Color(0xFF059669); // Forest green for positive feedback
  static const Color successDark =
      Color(0xFF10B981); // Brighter green for dark mode
  static const Color warningLight =
      Color(0xFFD97706); // Warm amber for premium prompts
  static const Color warningDark =
      Color(0xFFF59E0B); // Brighter amber for dark mode
  static const Color errorLight =
      Color(0xFFDC2626); // Clear red for error states
  static const Color errorDark =
      Color(0xFFEF4444); // Brighter red for dark mode

  static const Color surfaceLight =
      Color(0xFFFFFFFF); // Pure white for content backgrounds
  static const Color surfaceDark =
      Color(0xFF0F172A); // Deep slate for dark mode surfaces
  static const Color backgroundLight =
      Color(0xFFFAFAFA); // Subtle off-white for app background
  static const Color backgroundDark =
      Color(0xFF020617); // Deeper slate for dark background

  static const Color textPrimaryLight =
      Color(0xFF1E293B); // Near-black for primary text
  static const Color textPrimaryDark =
      Color(0xFFF1F5F9); // Near-white for dark mode
  static const Color textSecondaryLight =
      Color(0xFF64748B); // Medium gray for supporting text
  static const Color textSecondaryDark =
      Color(0xFF94A3B8); // Lighter gray for dark mode

  static const Color accentLight =
      Color(0xFF8B5CF6); // Subtle purple for creative tools
  static const Color accentDark =
      Color(0xFFA78BFA); // Brighter purple for dark mode

  // Card and dialog colors with subtle elevation
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color dialogLight = Color(0xFFFFFFFF);
  static const Color dialogDark = Color(0xFF1E293B);

  // Shadow colors for subtle elevation system (2-4dp shadows with 0.1 opacity)
  static const Color shadowLight =
      Color(0x1A000000); // 0.1 opacity for gentle depth
  static const Color shadowDark =
      Color(0x1AFFFFFF); // 0.1 opacity for dark mode

  // Divider colors - minimal 1px borders with secondary color at 0.2 opacity
  static const Color dividerLight =
      Color(0x3364748B); // Secondary color at 0.2 opacity
  static const Color dividerDark =
      Color(0x3394A3B8); // Secondary color at 0.2 opacity

  // Pro Theme Colors - Futuristic
  static const Color futuristicPrimary = Color(0xFF00FFFF); // Bright cyan
  static const Color futuristicSecondary = Color(0xFF7C3AED); // Electric purple
  static const Color futuristicAccent = Color(0xFFFF0080); // Hot pink
  static const Color futuristicSurface = Color(0xFF1A1A2E); // Dark navy
  static const Color futuristicBackground = Color(0xFF16213E); // Darker navy
  static const Color futuristicTextPrimary = Color(0xFFE0E6ED); // Light gray
  static const Color futuristicTextSecondary = Color(0xFF94A9C9); // Muted blue-gray

  // Pro Theme Colors - Neon  
  static const Color neonPrimary = Color(0xFFFF006E); // Hot pink
  static const Color neonSecondary = Color(0xFF8338EC); // Purple
  static const Color neonAccent = Color(0xFF3A86FF); // Bright blue
  static const Color neonSurface = Color(0xFF0F0F23); // Very dark purple
  static const Color neonBackground = Color(0xFF06061B); // Almost black purple
  static const Color neonTextPrimary = Color(0xFFF7F7FF); // Almost white
  static const Color neonTextSecondary = Color(0xFFB8B8CC); // Light purple-gray

  // Pro Theme Colors - Floral
  static const Color floralPrimary = Color(0xFF7209B7); // Deep purple
  static const Color floralSecondary = Color(0xFFF72585); // Bright pink  
  static const Color floralAccent = Color(0xFF4CC9F0); // Sky blue
  static const Color floralSurface = Color(0xFFFDF2F8); // Very light pink
  static const Color floralBackground = Color(0xFFFEF7FF); // Very light purple
  static const Color floralTextPrimary = Color(0xFF1F1019); // Dark purple
  static const Color floralTextSecondary = Color(0xFF6B4C7B); // Medium purple

  /// Light theme with Contemporary Productivity Minimalism
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: primaryLight.withAlpha(26),
      onPrimaryContainer: primaryLight,
      secondary: secondaryLight,
      onSecondary: Colors.white,
      secondaryContainer: secondaryLight.withAlpha(26),
      onSecondaryContainer: secondaryLight,
      tertiary: accentLight,
      onTertiary: Colors.white,
      tertiaryContainer: accentLight.withAlpha(26),
      onTertiaryContainer: accentLight,
      error: errorLight,
      onError: Colors.white,
      surface: surfaceLight,
      onSurface: textPrimaryLight,
      onSurfaceVariant: textSecondaryLight,
      outline: dividerLight,
      outlineVariant: dividerLight.withAlpha(128),
      shadow: shadowLight,
      scrim: Colors.black54,
      inverseSurface: surfaceDark,
      onInverseSurface: textPrimaryDark,
      inversePrimary: primaryDark,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: dividerLight,

    // AppBar with edge-to-edge content approach
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: textPrimaryLight,
      elevation: 0, // Flat design for contemporary feel
      scrolledUnderElevation: 2,
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
      ),
    ),

    // Card theme with subtle elevation
    cardTheme: CardTheme(
      color: cardLight,
      elevation: 2.0, // 2dp shadow for card separation
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded for modern feel
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Bottom navigation for contextual navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLight,
      unselectedItemColor: textSecondaryLight,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // FAB for primary actions
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),

    // Button themes with contemporary styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryLight,
        elevation: 2,
        shadowColor: shadowLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: primaryLight, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Typography with Inter font family
    textTheme: _buildTextTheme(isLight: true),

    // Input decoration with focused states and clear boundaries
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceLight,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textSecondaryLight.withAlpha(153),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: textSecondaryLight,
      suffixIconColor: textSecondaryLight,
    ),

    // Switch theme for settings
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return Colors.grey[300];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight.withAlpha(77);
        }
        return Colors.grey[200];
      }),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: dividerLight, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return textSecondaryLight;
      }),
    ),

    // Progress indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryLight,
      linearTrackColor: primaryLight.withAlpha(51),
      circularTrackColor: primaryLight.withAlpha(51),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryLight,
      thumbColor: primaryLight,
      overlayColor: primaryLight.withAlpha(51),
      inactiveTrackColor: primaryLight.withAlpha(77),
      trackHeight: 4,
    ),

    // Tab bar theme
    tabBarTheme: TabBarTheme(
      labelColor: primaryLight,
      unselectedLabelColor: textSecondaryLight,
      indicatorColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryLight.withAlpha(230),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(
        color: surfaceLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // SnackBar theme for feedback
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryLight,
      contentTextStyle: GoogleFonts.inter(
        color: surfaceLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: primaryLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
    ),

    // Bottom sheet theme for contextual action sheets
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceLight,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
    ), dialogTheme: DialogThemeData(backgroundColor: dialogLight),
  );

  /// Dark theme with Contemporary Productivity Minimalism
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: Colors.black,
      primaryContainer: primaryDark.withAlpha(51),
      onPrimaryContainer: primaryDark,
      secondary: secondaryDark,
      onSecondary: Colors.black,
      secondaryContainer: secondaryDark.withAlpha(51),
      onSecondaryContainer: secondaryDark,
      tertiary: accentDark,
      onTertiary: Colors.black,
      tertiaryContainer: accentDark.withAlpha(51),
      onTertiaryContainer: accentDark,
      error: errorDark,
      onError: Colors.black,
      surface: surfaceDark,
      onSurface: textPrimaryDark,
      onSurfaceVariant: textSecondaryDark,
      outline: dividerDark,
      outlineVariant: dividerDark.withAlpha(128),
      shadow: shadowDark,
      scrim: Colors.black87,
      inverseSurface: surfaceLight,
      onInverseSurface: textPrimaryLight,
      inversePrimary: primaryLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,

    // AppBar with edge-to-edge content approach
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
      ),
    ),

    // Card theme with subtle elevation
    cardTheme: CardTheme(
      color: cardDark,
      elevation: 2.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Bottom navigation for contextual navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryDark,
      unselectedItemColor: textSecondaryDark,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // FAB for primary actions
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryDark,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),

    // Button themes with contemporary styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: primaryDark,
        elevation: 2,
        shadowColor: shadowDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: primaryDark, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Typography with Inter font family
    textTheme: _buildTextTheme(isLight: false),

    // Input decoration with focused states and clear boundaries
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorDark),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorDark, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textSecondaryDark.withAlpha(153),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIconColor: textSecondaryDark,
      suffixIconColor: textSecondaryDark,
    ),

    // Switch theme for settings
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return Colors.grey[600];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark.withAlpha(77);
        }
        return Colors.grey[700];
      }),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: BorderSide(color: dividerDark, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return textSecondaryDark;
      }),
    ),

    // Progress indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryDark,
      linearTrackColor: primaryDark.withAlpha(51),
      circularTrackColor: primaryDark.withAlpha(51),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryDark,
      thumbColor: primaryDark,
      overlayColor: primaryDark.withAlpha(51),
      inactiveTrackColor: primaryDark.withAlpha(77),
      trackHeight: 4,
    ),

    // Tab bar theme
    tabBarTheme: TabBarTheme(
      labelColor: primaryDark,
      unselectedLabelColor: textSecondaryDark,
      indicatorColor: primaryDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Tooltip theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryDark.withAlpha(230),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(
        color: surfaceDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // SnackBar theme for feedback
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryDark,
      contentTextStyle: GoogleFonts.inter(
        color: surfaceDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
    ),

    // Bottom sheet theme for contextual action sheets
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceDark,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
    ), dialogTheme: DialogThemeData(backgroundColor: dialogDark),
  );

  /// Helper method to build text theme with Inter font family
  /// Implements typography standards for headings, body, captions, and data
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textPrimary = isLight ? textPrimaryLight : textPrimaryDark;
    final Color textSecondary =
        isLight ? textSecondaryLight : textSecondaryDark;

    return TextTheme(
      // Display styles - Inter with geometric clarity
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Headline styles - Inter for headings with excellent readability
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Title styles - Inter for consistent visual harmony
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),

      // Body styles - Inter for exceptional legibility during extended reading
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.4,
      ),

      // Label styles - Inter for consistency across UI elements
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Helper method to get monospace text style for data display
  /// JetBrains Mono for timestamps, file sizes, and technical information
  static TextStyle getMonospaceStyle({
    required bool isLight,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final Color textColor = isLight ? textSecondaryLight : textSecondaryDark;
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textColor,
      letterSpacing: 0,
    );
  }

  /// Helper method to get accent color for creative tools
  static Color getAccentColor(bool isLight) {
    return isLight ? accentLight : accentDark;
  }

  /// Helper method to get success color for positive feedback
  static Color getSuccessColor(bool isLight) {
    return isLight ? successLight : successDark;
  }

  /// Helper method to get warning color for premium prompts
  static Color getWarningColor(bool isLight) {
    return isLight ? warningLight : warningDark;
  }

  /// Get theme data for a specific theme ID
  static ThemeData getThemeById(String themeId) {
    switch (themeId) {
      case 'default_light':
        return lightTheme;
      case 'default_dark':
        return darkTheme;
      case 'futuristic':
        return _buildFuturisticTheme();
      case 'neon':
        return _buildNeonTheme();
      case 'floral':
        return _buildFloralTheme();
      default:
        return lightTheme; // Fallback to light theme
    }
  }

  /// Build Futuristic Pro theme
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
        onSecondary: Colors.white,
        secondaryContainer: futuristicSecondary.withAlpha(51),
        onSecondaryContainer: futuristicSecondary,
        tertiary: futuristicAccent,
        onTertiary: Colors.white,
        tertiaryContainer: futuristicAccent.withAlpha(51),
        onTertiaryContainer: futuristicAccent,
        error: errorDark,
        onError: Colors.black,
        surface: futuristicSurface,
        onSurface: futuristicTextPrimary,
        onSurfaceVariant: futuristicTextSecondary,
        outline: futuristicTextSecondary.withAlpha(128),
        outlineVariant: futuristicTextSecondary.withAlpha(64),
        shadow: shadowDark,
        scrim: Colors.black87,
        inverseSurface: surfaceLight,
        onInverseSurface: textPrimaryLight,
        inversePrimary: primaryLight,
      ),
      scaffoldBackgroundColor: futuristicBackground,
      cardColor: futuristicSurface,
      dividerColor: futuristicTextSecondary.withAlpha(128),
      textTheme: _buildTextTheme(isLight: false),
      // Use similar theme configurations as dark theme but with futuristic colors
      appBarTheme: AppBarTheme(
        backgroundColor: futuristicSurface,
        foregroundColor: futuristicTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: shadowDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: futuristicTextPrimary,
        ),
      ),
      // Add other theme properties as needed...
    );
  }

  /// Build Neon Pro theme  
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
        onTertiary: Colors.white,
        tertiaryContainer: neonAccent.withAlpha(51),
        onTertiaryContainer: neonAccent,
        error: errorDark,
        onError: Colors.black,
        surface: neonSurface,
        onSurface: neonTextPrimary,
        onSurfaceVariant: neonTextSecondary,
        outline: neonTextSecondary.withAlpha(128),
        outlineVariant: neonTextSecondary.withAlpha(64),
        shadow: shadowDark,
        scrim: Colors.black87,
        inverseSurface: surfaceLight,
        onInverseSurface: textPrimaryLight,
        inversePrimary: primaryLight,
      ),
      scaffoldBackgroundColor: neonBackground,
      cardColor: neonSurface,
      dividerColor: neonTextSecondary.withAlpha(128),
      textTheme: _buildTextTheme(isLight: false),
      appBarTheme: AppBarTheme(
        backgroundColor: neonSurface,
        foregroundColor: neonTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: shadowDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neonTextPrimary,
        ),
      ),
      // Add other theme properties as needed...
    );
  }

  /// Build Floral Pro theme
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
        error: errorLight,
        onError: Colors.white,
        surface: floralSurface,
        onSurface: floralTextPrimary,
        onSurfaceVariant: floralTextSecondary,
        outline: floralTextSecondary.withAlpha(128),
        outlineVariant: floralTextSecondary.withAlpha(64),
        shadow: shadowLight,
        scrim: Colors.black54,
        inverseSurface: surfaceDark,
        onInverseSurface: textPrimaryDark,
        inversePrimary: primaryDark,
      ),
      scaffoldBackgroundColor: floralBackground,
      cardColor: floralSurface,
      dividerColor: floralTextSecondary.withAlpha(128),
      textTheme: _buildTextTheme(isLight: true),
      appBarTheme: AppBarTheme(
        backgroundColor: floralSurface,
        foregroundColor: floralTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: shadowLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: floralTextPrimary,
        ),
      ),
      // Add other theme properties as needed...
    );
  }
}
