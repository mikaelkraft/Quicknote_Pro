import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';

/// Example showing how to use PremiumGateWidget for feature gating
class PremiumFeatureExampleScreen extends StatelessWidget {
  const PremiumFeatureExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Example 1: Voice transcription with upsell view
            Text(
              'Voice Transcription',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 2.h),
            PremiumGateWidget(
              feature: PremiumFeature.voiceNoteTranscription,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    Icon(Icons.mic, size: 48.sp, color: Colors.blue),
                    SizedBox(height: 2.h),
                    const Text('Voice-to-text transcription active'),
                    SizedBox(height: 1.h),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Start Recording'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Example 2: Advanced drawing tools with read-only mode
            Text(
              'Advanced Drawing Tools',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 2.h),
            PremiumGateWidget(
              feature: PremiumFeature.advancedDrawingTools,
              showAsReadOnly: true,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.brush, size: 32.sp, color: Colors.green),
                        Icon(Icons.palette, size: 32.sp, color: Colors.green),
                        Icon(Icons.layers, size: 32.sp, color: Colors.green),
                        Icon(Icons.texture, size: 32.sp, color: Colors.green),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    const Text('Professional drawing tools'),
                    SizedBox(height: 1.h),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Open Canvas'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Example 3: Export formats with custom message
            Text(
              'Export Formats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 2.h),
            PremiumGateWidget(
              feature: PremiumFeature.exportFormats,
              customTitle: 'Advanced Export Options',
              customDescription: 'Export your notes in multiple formats including PDF, Word, and more.',
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 32.sp, color: Colors.orange),
                            const Text('PDF'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.description, size: 32.sp, color: Colors.orange),
                            const Text('Word'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.html, size: 32.sp, color: Colors.orange),
                            const Text('HTML'),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    const Text('Multiple export formats available'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Show current premium status
            Consumer<EntitlementService>(
              builder: (context, entitlementService, _) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        Text(
                          'Current Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Icon(
                              entitlementService.isPremiumUser 
                                  ? Icons.check_circle 
                                  : Icons.lock,
                              color: entitlementService.isPremiumUser 
                                  ? Colors.green 
                                  : Colors.grey,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              entitlementService.isPremiumUser 
                                  ? 'Premium User' 
                                  : 'Free User',
                            ),
                          ],
                        ),
                        if (!entitlementService.isPremiumUser) ...[
                          SizedBox(height: 2.h),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context, 
                              AppRoutes.premiumUpgrade,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                            ),
                            child: const Text(
                              'Upgrade to Premium',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}