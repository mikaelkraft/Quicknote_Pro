import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:quicknote_pro/widgets/premium_gate_widget.dart';
import 'package:quicknote_pro/services/entitlement/entitlement_service.dart';

@GenerateMocks([EntitlementService])
import 'premium_gate_widget_test.mocks.dart';

void main() {
  group('PremiumGateWidget Tests', () {
    late MockEntitlementService mockEntitlementService;

    setUp(() {
      mockEntitlementService = MockEntitlementService();
    });

    Widget createTestWidget({
      required bool hasFeature,
      bool showAsReadOnly = false,
      VoidCallback? onUpgradePressed,
    }) {
      when(mockEntitlementService.hasFeature(PremiumFeature.voiceNoteTranscription))
          .thenReturn(hasFeature);
      when(mockEntitlementService.getFeatureName(PremiumFeature.voiceNoteTranscription))
          .thenReturn('Voice Note Transcription');
      when(mockEntitlementService.getFeatureDescription(PremiumFeature.voiceNoteTranscription))
          .thenReturn('Automatically transcribe your voice notes with AI');

      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ChangeNotifierProvider<EntitlementService>.value(
              value: mockEntitlementService,
              child: Scaffold(
                body: PremiumGateWidget(
                  feature: PremiumFeature.voiceNoteTranscription,
                  showAsReadOnly: showAsReadOnly,
                  onUpgradePressed: onUpgradePressed,
                  child: Container(
                    key: const Key('test_feature'),
                    child: const Text('Premium Feature Content'),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    group('Feature Access', () {
      testWidgets('should show child when user has feature access', (tester) async {
        await tester.pumpWidget(createTestWidget(hasFeature: true));

        // Should find the child widget
        expect(find.byKey(const Key('test_feature')), findsOneWidget);
        expect(find.text('Premium Feature Content'), findsOneWidget);

        // Should not find premium gate UI
        expect(find.text('Voice Note Transcription'), findsNothing);
        expect(find.text('Upgrade to Premium'), findsNothing);
      });

      testWidgets('should show upsell view when user lacks feature access', (tester) async {
        await tester.pumpWidget(createTestWidget(hasFeature: false));

        // Should not find the child widget
        expect(find.byKey(const Key('test_feature')), findsNothing);
        expect(find.text('Premium Feature Content'), findsNothing);

        // Should find premium gate UI
        expect(find.text('Voice Note Transcription'), findsOneWidget);
        expect(find.text('Upgrade to Premium'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium), findsWidgets);
      });

      testWidgets('should show read-only view when showAsReadOnly is true', (tester) async {
        await tester.pumpWidget(createTestWidget(
          hasFeature: false,
          showAsReadOnly: true,
        ));

        // Should find the child widget (grayed out)
        expect(find.byKey(const Key('test_feature')), findsOneWidget);
        expect(find.text('Premium Feature Content'), findsOneWidget);

        // Should find overlay with premium indicator
        expect(find.text('Premium Feature'), findsOneWidget);
        expect(find.text('Upgrade'), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should call custom onUpgradePressed when provided', (tester) async {
        bool upgradePressed = false;
        
        await tester.pumpWidget(createTestWidget(
          hasFeature: false,
          onUpgradePressed: () => upgradePressed = true,
        ));

        // Tap the upgrade button
        await tester.tap(find.text('Upgrade to Premium'));
        await tester.pumpAndSettle();

        expect(upgradePressed, isTrue);
      });

      testWidgets('should show feature details dialog on "Learn more" tap', (tester) async {
        await tester.pumpWidget(createTestWidget(hasFeature: false));

        // Tap "Learn more" button
        await tester.tap(find.text('Learn more about Premium'));
        await tester.pumpAndSettle();

        // Should show dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Voice Note Transcription'), findsWidgets); // Title in dialog
      });

      testWidgets('should handle upgrade button tap in read-only mode', (tester) async {
        bool upgradePressed = false;
        
        await tester.pumpWidget(createTestWidget(
          hasFeature: false,
          showAsReadOnly: true,
          onUpgradePressed: () => upgradePressed = true,
        ));

        // Tap the upgrade button in overlay
        await tester.tap(find.text('Upgrade'));
        await tester.pumpAndSettle();

        expect(upgradePressed, isTrue);
      });
    });

    group('Custom Content', () {
      testWidgets('should use custom title and description when provided', (tester) async {
        when(mockEntitlementService.hasFeature(PremiumFeature.voiceNoteTranscription))
            .thenReturn(false);

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: ChangeNotifierProvider<EntitlementService>.value(
                  value: mockEntitlementService,
                  child: Scaffold(
                    body: PremiumGateWidget(
                      feature: PremiumFeature.voiceNoteTranscription,
                      customTitle: 'Custom Feature Title',
                      customDescription: 'Custom feature description text',
                      child: const Text('Premium Feature Content'),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        expect(find.text('Custom Feature Title'), findsOneWidget);
        expect(find.text('Custom feature description text'), findsOneWidget);
      });
    });

    group('Premium Feature Dialog', () {
      testWidgets('should show premium benefits in dialog', (tester) async {
        await tester.pumpWidget(createTestWidget(hasFeature: false));

        // Open dialog
        await tester.tap(find.text('Learn more about Premium'));
        await tester.pumpAndSettle();

        // Should show benefits
        expect(find.text('Premium Benefits:'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsWidgets);
      });

      testWidgets('should close dialog on cancel', (tester) async {
        await tester.pumpWidget(createTestWidget(hasFeature: false));

        // Open dialog
        await tester.tap(find.text('Learn more about Premium'));
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('should navigate to upgrade on "Upgrade Now" tap', (tester) async {
        await tester.pumpWidget(createTestWidget(hasFeature: false));

        // Open dialog
        await tester.tap(find.text('Learn more about Premium'));
        await tester.pumpAndSettle();

        // Should have "Upgrade Now" button
        expect(find.text('Upgrade Now'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible with screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget(hasFeature: false));

        // Check for semantic labels
        expect(find.byType(ElevatedButton), findsWidgets);
        expect(find.byType(TextButton), findsOneWidget);
      });

      testWidgets('should have proper contrast for premium indicators', (tester) async {
        await tester.pumpWidget(createTestWidget(
          hasFeature: false,
          showAsReadOnly: true,
        ));

        // Premium icon should be visible
        expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
        
        // Check for amber color (high contrast)
        final iconWidget = tester.widget<Icon>(find.byIcon(Icons.workspace_premium));
        expect(iconWidget.color, equals(Colors.amber));
      });
    });
  });
}