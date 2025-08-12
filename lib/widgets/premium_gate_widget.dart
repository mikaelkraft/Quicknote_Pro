import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../services/entitlement/entitlement_service.dart';
import '../core/app_export.dart';

/// Widget that gates premium features with contextual upsell UI
class PremiumGateWidget extends StatelessWidget {
  final PremiumFeature feature;
  final Widget child;
  final String? customTitle;
  final String? customDescription;
  final VoidCallback? onUpgradePressed;
  final bool showAsReadOnly;
  
  const PremiumGateWidget({
    Key? key,
    required this.feature,
    required this.child,
    this.customTitle,
    this.customDescription,
    this.onUpgradePressed,
    this.showAsReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EntitlementService>(
      builder: (context, entitlementService, _) {
        // If user has access, show the feature
        if (entitlementService.hasFeature(feature)) {
          return child;
        }
        
        // Show gated version based on showAsReadOnly flag
        return showAsReadOnly ? _buildReadOnlyView(context, entitlementService) 
                             : _buildUpsellView(context, entitlementService);
      },
    );
  }
  
  /// Build read-only version of the feature
  Widget _buildReadOnlyView(BuildContext context, EntitlementService entitlementService) {
    return Stack(
      children: [
        // Grayed out version of the feature
        Opacity(
          opacity: 0.5,
          child: IgnorePointer(child: child),
        ),
        // Overlay with premium indicator
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: 24.sp,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Premium Feature',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  ElevatedButton(
                    onPressed: () => _handleUpgradePressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    ),
                    child: Text(
                      'Upgrade',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build upsell view when feature is blocked
  Widget _buildUpsellView(BuildContext context, EntitlementService entitlementService) {
    final featureName = customTitle ?? entitlementService.getFeatureName(feature);
    final featureDescription = customDescription ?? entitlementService.getFeatureDescription(feature);
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium icon
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: Colors.amber,
              size: 32.sp,
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Feature name
          Text(
            featureName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 1.h),
          
          // Feature description
          Text(
            featureDescription,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 2.h),
          
          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleUpgradePressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upgrade, size: 16.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 1.h),
          
          // Learn more link
          TextButton(
            onPressed: () => _showFeatureDetails(context, entitlementService),
            child: Text(
              'Learn more about Premium',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.amber,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Handle upgrade button press
  void _handleUpgradePressed(BuildContext context) {
    if (onUpgradePressed != null) {
      onUpgradePressed!();
    } else {
      // Navigate to premium upgrade screen
      Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
    }
  }
  
  /// Show detailed feature information
  void _showFeatureDetails(BuildContext context, EntitlementService entitlementService) {
    showDialog(
      context: context,
      builder: (context) => PremiumFeatureDialog(
        feature: feature,
        entitlementService: entitlementService,
      ),
    );
  }
}

/// Dialog showing detailed premium feature information
class PremiumFeatureDialog extends StatelessWidget {
  final PremiumFeature feature;
  final EntitlementService entitlementService;
  
  const PremiumFeatureDialog({
    Key? key,
    required this.feature,
    required this.entitlementService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final featureName = entitlementService.getFeatureName(feature);
    final featureDescription = entitlementService.getFeatureDescription(feature);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.amber),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              featureName,
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(featureDescription),
          SizedBox(height: 2.h),
          Text(
            'Premium Benefits:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 1.h),
          ..._getPremiumBenefits().map((benefit) => Padding(
            padding: EdgeInsets.only(bottom: 0.5.h),
            child: Row(
              children: [
                Icon(Icons.check, color: Colors.green, size: 16.sp),
                SizedBox(width: 2.w),
                Expanded(child: Text(benefit, style: TextStyle(fontSize: 11.sp))),
              ],
            ),
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: Text('Upgrade Now', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
  
  List<String> _getPremiumBenefits() {
    switch (feature) {
      case PremiumFeature.voiceNoteTranscription:
        return [
          'Unlimited transcriptions per month',
          'High accuracy AI transcription',
          'Multiple language support',
          'Offline transcription capability',
        ];
      case PremiumFeature.advancedDrawingTools:
        return [
          'Professional brush tools',
          'Custom shapes and stamps',
          'Advanced color picker',
          'Pressure sensitivity support',
        ];
      case PremiumFeature.drawingLayers:
        return [
          'Multiple drawing layers',
          'Layer blending modes',
          'Layer opacity control',
          'Group and organize layers',
        ];
      case PremiumFeature.exportFormats:
        return [
          'Export to PDF, Word, HTML',
          'Custom export settings',
          'Batch export multiple notes',
          'Cloud export integration',
        ];
      default:
        return [
          'Unlock all premium features',
          'Priority customer support',
          'Regular feature updates',
          'Ad-free experience',
        ];
    }
  }
}