import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/theme/theme_service.dart';
import '../../services/theme/theme_entitlement_service.dart';
import '../../services/theme/paywall_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

/// Widget for selecting themes with Pro theme paywall integration
/// 
/// Shows available themes in a grid with preview cards. Pro themes
/// display a lock icon and trigger paywall when tapped by non-Pro users.
class ThemePickerWidget extends StatefulWidget {
  final String? title;
  final VoidCallback? onClose;

  const ThemePickerWidget({
    Key? key,
    this.title,
    this.onClose,
  }) : super(key: key);

  @override
  State<ThemePickerWidget> createState() => _ThemePickerWidgetState();
}

class _ThemePickerWidgetState extends State<ThemePickerWidget> {
  late ThemeService _themeService;
  late ThemeEntitlementService _entitlementService;

  @override
  void initState() {
    super.initState();
    _themeService = Provider.of<ThemeService>(context, listen: false);
    _entitlementService = Provider.of<ThemeEntitlementService>(context, listen: false);
  }

  void _onThemeSelected(String themeId, ThemeDefinition theme) {
    // Track theme selection attempt
    PaywallAnalyticsService.logThemeSelectionAttempt(
      themeId: themeId,
      isProTheme: theme.isPro,
      hasAccess: _entitlementService.hasThemeAccess(themeId),
    );

    if (_entitlementService.shouldShowPaywallForTheme(themeId)) {
      _showThemePaywall(themeId, theme);
    } else {
      _applyTheme(themeId);
    }
  }

  void _applyTheme(String themeId) async {
    await _themeService.setSelectedTheme(themeId);
    
    PaywallAnalyticsService.logThemeSelectionAttempt(
      themeId: themeId,
      isProTheme: AppTheme.availableThemes[themeId]?.isPro ?? false,
      hasAccess: true,
      action: 'selected',
    );

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme applied: ${AppTheme.availableThemes[themeId]?.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showThemePaywall(String themeId, ThemeDefinition theme) {
    PaywallAnalyticsService.logPaywallShown(
      entryPoint: 'theme_picker',
      featureType: 'theme',
      specificFeature: themeId,
      additionalData: {
        'theme_name': theme.name,
        'theme_description': theme.description,
      },
    );

    PaywallAnalyticsService.logUpsellEntryPoint(
      entryPoint: 'theme_picker',
      action: 'clicked',
      targetFeature: themeId,
    );

    Navigator.pushNamed(
      context,
      AppRoutes.premiumUpgrade,
      arguments: {
        'entry_point': 'theme_picker',
        'target_theme': themeId,
        'theme_name': theme.name,
      },
    ).then((result) {
      // Check if user purchased premium
      if (result == true || _entitlementService.isPremium) {
        _applyTheme(themeId);
      }
    });
  }

  Widget _buildThemeCard(String themeId, ThemeDefinition theme) {
    final isSelected = _themeService.selectedTheme == themeId;
    final hasAccess = _entitlementService.hasThemeAccess(themeId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onThemeSelected(themeId, theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withAlpha(26),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Theme preview
              Container(
                height: 20.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: theme.previewColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Mock app bar
                    Container(
                      height: 6.h,
                      color: theme.previewColors.first.withAlpha(128),
                      child: Row(
                        children: [
                          SizedBox(width: 4.w),
                          Container(
                            width: 6.w,
                            height: 3.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(179),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Container(
                              height: 2.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(128),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                        ],
                      ),
                    ),
                    // Mock content area
                    Expanded(
                      child: Container(
                        color: theme.previewColors.last,
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 1.5.h,
                                  decoration: BoxDecoration(
                                    color: theme.previewColors.first.withAlpha(128),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Container(
                                    height: 1.h,
                                    decoration: BoxDecoration(
                                      color: theme.previewColors.first.withAlpha(77),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Container(
                              height: 1.h,
                              decoration: BoxDecoration(
                                color: theme.previewColors.first.withAlpha(51),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pro lock overlay
              if (theme.isPro && !hasAccess)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 8.w,
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 2.w,
                  right: 2.w,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 4.w,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, ThemeEntitlementService>(
      builder: (context, themeService, entitlementService, child) {
        final availableThemes = AppTheme.availableThemes;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title ?? 'Choose Theme',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose ?? () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              SizedBox(height: 2.h),

              // Premium status indicator
              if (entitlementService.isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successLight.withAlpha(77),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: AppTheme.successLight,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        entitlementService.getSubscriptionStatusText(),
                        style: TextStyle(
                          color: AppTheme.successLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Theme grid
              SizedBox(
                height: 50.h,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 2.w,
                    mainAxisSpacing: 2.w,
                  ),
                  itemCount: availableThemes.length,
                  itemBuilder: (context, index) {
                    final entry = availableThemes.entries.elementAt(index);
                    return Column(
                      children: [
                        Expanded(
                          child: _buildThemeCard(entry.key, entry.value),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          entry.value.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (entry.value.description.isNotEmpty)
                          Text(
                            entry.value.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: 2.h),

              // Upgrade button for non-premium users
              if (!entitlementService.isPremium)
                ElevatedButton.icon(
                  onPressed: () {
                    PaywallAnalyticsService.logUpsellEntryPoint(
                      entryPoint: 'theme_picker',
                      action: 'clicked',
                      targetFeature: 'upgrade_button',
                    );
                    
                    Navigator.pushNamed(
                      context,
                      AppRoutes.premiumUpgrade,
                      arguments: {
                        'entry_point': 'theme_picker',
                        'focus': 'themes',
                      },
                    );
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Unlock Pro Themes'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}