import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../services/theme/theme_entitlement_service.dart';
import '../services/theme/paywall_analytics_service.dart';
import '../widgets/theme_picker_widget.dart';

/// Developer tools widget for testing themes and entitlements
/// Only shown in debug mode for testing purposes
class DevThemeToolsWidget extends StatelessWidget {
  const DevThemeToolsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Consumer2<ThemeService, ThemeEntitlementService>(
      builder: (context, themeService, entitlementService, child) {
        return Container(
          padding: EdgeInsets.all(4.w),
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.orange),
                  SizedBox(width: 2.w),
                  Text(
                    'Dev Theme Tools',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 2.h),
              
              // Current status
              Text(
                'Status: ${entitlementService.getSubscriptionStatusText()}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: entitlementService.isPremium ? Colors.green : Colors.grey,
                ),
              ),
              
              Text('Current Theme: ${themeService.selectedTheme}'),
              
              SizedBox(height: 2.h),
              
              // Quick actions
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  // Grant Premium
                  ElevatedButton(
                    onPressed: () async {
                      await entitlementService.grantPremiumAccess(
                        purchaseType: 'lifetime',
                      );
                      PaywallAnalyticsService.logPaywallConversion(
                        entryPoint: 'dev_tools',
                        purchaseType: 'testing',
                        planType: 'lifetime',
                        price: 0.0,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Grant Premium'),
                  ),
                  
                  // Revoke Premium
                  ElevatedButton(
                    onPressed: () async {
                      await entitlementService.revokePremiumAccess();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Revoke Premium'),
                  ),
                  
                  // Test Restore
                  ElevatedButton(
                    onPressed: () async {
                      await entitlementService.simulatePurchaseForTesting('lifetime');
                      await entitlementService.revokePremiumAccess();
                      final restored = await entitlementService.restorePurchases();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored ? 'Restore successful!' : 'Nothing to restore'),
                          backgroundColor: restored ? Colors.green : Colors.orange,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Test Restore'),
                  ),
                ],
              ),
              
              SizedBox(height: 2.h),
              
              // Quick theme switcher
              Text(
                'Quick Theme Switch:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              
              SizedBox(height: 1.h),
              
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: AppTheme.availableThemes.entries.map((entry) {
                  final themeId = entry.key;
                  final theme = entry.value;
                  final isSelected = themeService.selectedTheme == themeId;
                  final canAccess = entitlementService.hasThemeAccess(themeId);
                  
                  return GestureDetector(
                    onTap: () async {
                      if (canAccess) {
                        await themeService.setSelectedTheme(themeId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${theme.name} requires Premium access'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.orange : Colors.grey,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4.w,
                            height: 4.w,
                            decoration: BoxDecoration(
                              color: theme.previewColors.first,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            theme.name,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (theme.isPro && !canAccess) ...[
                            SizedBox(width: 1.w),
                            Icon(
                              Icons.lock,
                              size: 3.w,
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              SizedBox(height: 2.h),
              
              // Theme picker button
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ThemePickerWidget(
                      title: 'Dev Theme Picker',
                    ),
                  );
                },
                icon: Icon(Icons.palette),
                label: Text('Open Theme Picker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              
              SizedBox(height: 1.h),
              
              // Analytics info
              Text(
                'Analytics: ${PaywallAnalyticsService.getAnalyticsSummary()['events_tracked']?.length ?? 0} events tracked',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}