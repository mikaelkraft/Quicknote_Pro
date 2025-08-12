import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicknote_pro/main.dart' as app;
import 'package:quicknote_pro/services/entitlement/entitlement_service.dart';
import 'package:quicknote_pro/services/billing/billing_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Premium Features Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should show premium gate for voice transcription', (tester) async {
      // Start the app
      // Note: This would require a test-specific main function in a real implementation
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<BillingService>(
                create: (_) => MockBillingService(isPremium: false),
              ),
              ChangeNotifierProvider<EntitlementService>(
                create: (context) => MockEntitlementService(
                  Provider.of<BillingService>(context, listen: false),
                  isPremium: false,
                ),
              ),
            ],
            child: const TestPremiumFeatureScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for premium features that should be gated
      expect(find.text('Premium Feature'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsWidgets);
    });

    testWidgets('should allow access for premium users', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<BillingService>(
                create: (_) => MockBillingService(isPremium: true),
              ),
              ChangeNotifierProvider<EntitlementService>(
                create: (context) => MockEntitlementService(
                  Provider.of<BillingService>(context, listen: false),
                  isPremium: true,
                ),
              ),
            ],
            child: const TestPremiumFeatureScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Premium users should see the actual feature content
      expect(find.text('Premium Feature Content'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsNothing);
    });

    testWidgets('should navigate to premium upgrade screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<BillingService>(
                create: (_) => MockBillingService(isPremium: false),
              ),
              ChangeNotifierProvider<EntitlementService>(
                create: (context) => MockEntitlementService(
                  Provider.of<BillingService>(context, listen: false),
                  isPremium: false,
                ),
              ),
            ],
            child: const TestPremiumFeatureScreen(),
          ),
          routes: {
            '/premium-upgrade': (context) => const MockPremiumUpgradeScreen(),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Tap the upgrade button
      await tester.tap(find.text('Upgrade to Premium'));
      await tester.pumpAndSettle();

      // Should navigate to upgrade screen
      expect(find.text('Premium Upgrade'), findsOneWidget);
    });
  });
}

// Mock classes for testing
class MockBillingService extends ChangeNotifier implements BillingService {
  final bool isPremium;
  
  MockBillingService({required this.isPremium});

  @override
  bool get isAvailable => true;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  List get products => [];

  @override
  bool get hasPremium => isPremium;

  @override
  bool get isPremiumUser => isPremium;

  @override
  bool hasProduct(String productId) => isPremium;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockEntitlementService extends ChangeNotifier implements EntitlementService {
  final BillingService billingService;
  final bool isPremium;
  
  MockEntitlementService(this.billingService, {required this.isPremium});

  @override
  bool get isInitialized => true;

  @override
  bool get isPremiumUser => isPremium;

  @override
  bool hasFeature(dynamic feature) => isPremium;

  @override
  bool hasReachedLimit(dynamic feature, int currentUsage) => !isPremium && currentUsage >= 10;

  @override
  String getFeatureName(dynamic feature) => 'Test Feature';

  @override
  String getFeatureDescription(dynamic feature) => 'Test description';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test screens
class TestPremiumFeatureScreen extends StatelessWidget {
  const TestPremiumFeatureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EntitlementService>(
        builder: (context, entitlementService, _) {
          if (entitlementService.hasFeature(PremiumFeature.voiceNoteTranscription)) {
            return const Center(
              child: Text('Premium Feature Content'),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium),
                  const Text('Premium Feature'),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/premium-upgrade'),
                    child: const Text('Upgrade to Premium'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class MockPremiumUpgradeScreen extends StatelessWidget {
  const MockPremiumUpgradeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Premium Upgrade'),
      ),
    );
  }
}