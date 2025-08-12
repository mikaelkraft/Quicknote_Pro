import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quicknote_pro/core/app_export.dart';

/// Example demonstrating premium feature gating in action
class PremiumFeatureExample extends StatelessWidget {
  const PremiumFeatureExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features Demo'),
        actions: [
          Consumer<EntitlementService>(
            builder: (context, entitlement, _) {
              return Switch(
                value: entitlement.isPremium,
                onChanged: (value) async {
                  if (value) {
                    await entitlement.grantPremium();
                  } else {
                    await entitlement.revokePremium();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status display
            Consumer<EntitlementService>(
              builder: (context, entitlement, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: entitlement.isPremium ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entitlement.isPremium ? Icons.star : Icons.star_border,
                        color: entitlement.isPremium ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entitlement.isPremium 
                          ? 'Premium User (${entitlement.entitlementLevel.name})'
                          : 'Free User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Voice Notes Feature
            const Text('Voice Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FeatureGate(
              feature: PremiumFeature.unlimitedVoiceNotes,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(child: Text('Unlimited voice recordings available!')),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Drawing Tools Feature
            const Text('Drawing Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SimpleFeatureGate(
              feature: PremiumFeature.advancedDrawingTools,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.brush, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Advanced drawing tools enabled'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Export Feature with Button
            const Text('Export Feature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            PremiumButton(
              feature: PremiumFeature.exportFormats,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export started!')),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('Export as PDF'),
                ],
              ),
            ),

            const Spacer(),

            // Upgrade button for free users
            Consumer<EntitlementService>(
              builder: (context, entitlement, _) {
                if (entitlement.isPremium) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.premiumUpgrade);
                    },
                    child: const Text('Upgrade to Premium'),
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