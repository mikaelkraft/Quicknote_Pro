import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Enhanced theme picker widget with Pro theme support
/// 
/// Displays all available themes with lock icons for premium themes.
/// Shows upsell prompts for Pro-only themes when accessed by free users.
class ThemePickerWidget extends StatefulWidget {
  const ThemePickerWidget({Key? key}) : super(key: key);

  @override
  State<ThemePickerWidget> createState() => _ThemePickerWidgetState();
}

class _ThemePickerWidgetState extends State<ThemePickerWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  DateTime? _pickerOpenTime;

  @override
  void initState() {
    super.initState();
    _pickerOpenTime = DateTime.now();
    _initializeAnimations();
    _trackPickerOpened();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  void _trackPickerOpened() {
    final themeService = context.read<ThemeService>();
    final entitlementService = context.read<EntitlementService>();

    AnalyticsService.instance.trackThemePickerOpened(
      currentTheme: themeService.currentThemeType.displayName,
      hasProAccess: entitlementService.hasProAccess,
    );
  }

  void _trackPickerClosed({required bool themeChanged}) {
    if (_pickerOpenTime != null) {
      final timeSpent = DateTime.now().difference(_pickerOpenTime!).inSeconds;
      final themeService = context.read<ThemeService>();

      AnalyticsService.instance.trackThemePickerClosed(
        currentTheme: themeService.currentThemeType.displayName,
        themeChanged: themeChanged,
        timeSpentSeconds: timeSpent,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final entitlementService = context.watch<EntitlementService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Choose Theme',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      if (entitlementService.hasProAccess)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PRO',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Free Themes Section
                  _buildThemeSection(
                    title: 'Free Themes',
                    themes: ThemeType.freeThemes,
                    themeService: themeService,
                    entitlementService: entitlementService,
                  ),

                  SizedBox(height: 2.h),

                  // Pro Themes Section
                  _buildThemeSection(
                    title: 'Pro Themes',
                    subtitle: entitlementService.isFreeUser
                        ? 'One-time purchase, no subscription'
                        : null,
                    themes: ThemeType.premiumThemes,
                    themeService: themeService,
                    entitlementService: entitlementService,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSection({
    required String title,
    String? subtitle,
    required List<ThemeType> themes,
    required ThemeService themeService,
    required EntitlementService entitlementService,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (title == 'Pro Themes' && entitlementService.isFreeUser) ...[
              SizedBox(width: 1.w),
              Icon(
                Icons.star,
                color: AppTheme.getWarningColor(Theme.of(context).brightness == Brightness.light),
                size: 16,
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getWarningColor(Theme.of(context).brightness == Brightness.light),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
        SizedBox(height: 1.5.h),
        Wrap(
          spacing: 3.w,
          runSpacing: 2.h,
          children: themes.map((themeType) {
            return _buildThemeCard(
              themeType: themeType,
              themeService: themeService,
              entitlementService: entitlementService,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required ThemeType themeType,
    required ThemeService themeService,
    required EntitlementService entitlementService,
  }) {
    final isSelected = themeService.currentThemeType == themeType;
    final isLocked = themeType.isPremium && entitlementService.isFreeUser;
    final canAccess = themeService.canAccessTheme(themeType);

    return GestureDetector(
      onTap: () => _onThemeCardTapped(themeType, themeService, entitlementService),
      child: Container(
        width: 25.w,
        height: 12.h,
        decoration: BoxDecoration(
          color: themeType.previewColor.withAlpha(isSelected ? 255 : 77),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Theme preview content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    themeType.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    themeType.displayName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Lock overlay for premium themes
            if (isLocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'PRO',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            // Selected indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onThemeCardTapped(
    ThemeType themeType,
    ThemeService themeService,
    EntitlementService entitlementService,
  ) async {
    // Track theme viewed
    AnalyticsService.instance.trackThemeViewed(
      themeName: themeType.displayName,
      isPremium: themeType.isPremium,
      hasProAccess: entitlementService.hasProAccess,
    );

    final previousTheme = themeService.currentThemeType;
    final success = await themeService.setThemeType(themeType);

    if (!success && themeType.isPremium) {
      // Show paywall for premium theme
      await _showProUpgradeDialog(themeType, entitlementService);
    } else if (success) {
      // Theme changed successfully
      _trackPickerClosed(themeChanged: previousTheme != themeType);
    }
  }

  Future<void> _showProUpgradeDialog(
    ThemeType themeType,
    EntitlementService entitlementService,
  ) async {
    // Track paywall shown
    AnalyticsService.instance.trackPaywallShownFromTheme(
      triggerTheme: themeType.displayName,
      paywallType: 'theme_upgrade',
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ProUpgradeDialog(
        themeName: themeType.displayName,
        themeColor: themeType.previewColor,
        onUpgrade: () async {
          Navigator.of(context).pop(true);
          // Navigate to premium upgrade screen
          await Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
        },
        onDismiss: () {
          AnalyticsService.instance.trackProUpsellDismissed(
            triggerTheme: themeType.displayName,
            dismissalMethod: 'close_button',
          );
          Navigator.of(context).pop(false);
        },
      ),
    );

    if (result != true) {
      AnalyticsService.instance.trackProUpsellDismissed(
        triggerTheme: themeType.displayName,
        dismissalMethod: 'outside_tap',
      );
    }
  }
}

class _ProUpgradeDialog extends StatelessWidget {
  final String themeName;
  final Color themeColor;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const _ProUpgradeDialog({
    required this.themeName,
    required this.themeColor,
    required this.onUpgrade,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 12.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock $themeName Theme',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Pro feature',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.getWarningColor(
                                  Theme.of(context).brightness == Brightness.light),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Description
            Text(
              'Get access to premium themes and all Pro features with a one-time purchase. No subscription required!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    child: Text('Maybe Later'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onUpgrade,
                    child: Text('Upgrade to Pro'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}