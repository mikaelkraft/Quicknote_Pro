import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'package:quicknote_pro/services/entitlements/entitlement_service.dart';
import 'package:quicknote_pro/widgets/premium/feature_gate.dart';
import 'package:quicknote_pro/widgets/premium/upsell_dialog.dart';

import 'feature_gate_test.mocks.dart';

@GenerateMocks([EntitlementService])
void main() {
  group('FeatureGate Widget Tests', () {
    late MockEntitlementService mockEntitlementService;

    setUp(() {
      mockEntitlementService = MockEntitlementService();
    });

    Widget createTestWidget({
      required Widget child,
      required PremiumFeature feature,
      Widget? fallback,
      bool showUpsell = true,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ChangeNotifierProvider<EntitlementService>.value(
              value: mockEntitlementService,
              child: Scaffold(
                body: FeatureGate(
                  feature: feature,
                  showUpsell: showUpsell,
                  fallback: fallback,
                  child: child,
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('should show child when user has premium access', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(true);

      const childWidget = Text('Premium Content');
      
      await tester.pumpWidget(createTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
      ));

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byType(Container), findsNothing); // No upsell container
    });

    testWidgets('should show upsell widget when user does not have premium access', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(false);

      const childWidget = Text('Premium Content');
      
      await tester.pumpWidget(createTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
      ));

      expect(find.text('Premium Content'), findsNothing);
      expect(find.text('Unlock Unlimited Voice Notes'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('should show fallback widget when provided and user lacks access', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(false);

      const childWidget = Text('Premium Content');
      const fallbackWidget = Text('Free Version');
      
      await tester.pumpWidget(createTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
        fallback: fallbackWidget,
      ));

      expect(find.text('Premium Content'), findsNothing);
      expect(find.text('Free Version'), findsOneWidget);
      expect(find.text('Unlock Unlimited Voice Notes'), findsNothing);
    });

    testWidgets('should show nothing when showUpsell is false and no fallback', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(false);

      const childWidget = Text('Premium Content');
      
      await tester.pumpWidget(createTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
        showUpsell: false,
      ));

      expect(find.text('Premium Content'), findsNothing);
      expect(find.text('Unlock Unlimited Voice Notes'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should open upsell dialog when tapping upsell widget', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(false);

      const childWidget = Text('Premium Content');
      
      await tester.pumpWidget(createTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
      ));

      // Tap the upsell container
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.byType(UpsellDialog), findsOneWidget);
      expect(find.text('Unlock Unlimited Voice Notes'), findsWidgets);
    });
  });

  group('SimpleFeatureGate Widget Tests', () {
    late MockEntitlementService mockEntitlementService;

    setUp(() {
      mockEntitlementService = MockEntitlementService();
    });

    Widget createSimpleTestWidget({
      required Widget child,
      required PremiumFeature feature,
      Widget? lockOverlay,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ChangeNotifierProvider<EntitlementService>.value(
              value: mockEntitlementService,
              child: Scaffold(
                body: SimpleFeatureGate(
                  feature: feature,
                  lockOverlay: lockOverlay,
                  child: child,
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('should show child without overlay when user has access', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(true);

      const childWidget = Text('Premium Content');
      
      await tester.pumpWidget(createSimpleTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
      ));

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('should show child with lock overlay when user lacks access', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(false);

      const childWidget = Text('Premium Content');
      
      await tester.pumpWidget(createSimpleTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
      ));

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('Premium Feature'), findsOneWidget);
    });

    testWidgets('should show custom lock overlay when provided', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(false);

      const childWidget = Text('Premium Content');
      const customOverlay = Text('Custom Lock Message');
      
      await tester.pumpWidget(createSimpleTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        child: childWidget,
        lockOverlay: customOverlay,
      ));

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.text('Custom Lock Message'), findsOneWidget);
      expect(find.text('Premium Feature'), findsNothing);
    });
  });

  group('PremiumButton Widget Tests', () {
    late MockEntitlementService mockEntitlementService;

    setUp(() {
      mockEntitlementService = MockEntitlementService();
    });

    Widget createButtonTestWidget({
      required PremiumFeature feature,
      VoidCallback? onPressed,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ChangeNotifierProvider<EntitlementService>.value(
              value: mockEntitlementService,
              child: Scaffold(
                body: PremiumButton(
                  feature: feature,
                  onPressed: onPressed,
                  child: const Text('Button Text'),
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('should execute callback when user has premium access', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(true);

      bool callbackExecuted = false;
      
      await tester.pumpWidget(createButtonTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        onPressed: () => callbackExecuted = true,
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(callbackExecuted, true);
      expect(find.byIcon(Icons.star), findsNothing); // No star icon for premium users
    });

    testWidgets('should show upsell dialog when user lacks premium access', (WidgetTester tester) async {
      when(mockEntitlementService.hasFeature(any)).thenReturn(false);

      bool callbackExecuted = false;
      
      await tester.pumpWidget(createButtonTestWidget(
        feature: PremiumFeature.unlimitedVoiceNotes,
        onPressed: () => callbackExecuted = true,
      ));

      expect(find.byIcon(Icons.star), findsOneWidget); // Star icon for non-premium users

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(callbackExecuted, false); // Callback should not be executed
      expect(find.byType(UpsellDialog), findsOneWidget);
    });
  });
}