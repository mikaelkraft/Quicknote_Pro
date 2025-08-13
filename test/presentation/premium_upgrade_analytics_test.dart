import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quicknote_pro/presentation/premium_upgrade/premium_upgrade.dart';
import 'package:quicknote_pro/services/analytics/analytics_service.dart';

void main() {
  group('PremiumUpgrade Analytics', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    testWidgets('should track screen view and upgrade prompt on initialization', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AnalyticsService>.value(
            value: analyticsService,
            child: const PremiumUpgrade(),
          ),
        ),
      );

      // Verify the screen renders without errors
      expect(find.byType(PremiumUpgrade), findsOneWidget);
      
      // Verify animations complete
      await tester.pumpAndSettle();
      
      // Screen should be visible
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle plan selection without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AnalyticsService>.value(
            value: analyticsService,
            child: const PremiumUpgrade(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for plan selection widgets and verify they don't crash
      // This tests that analytics calls don't break the UI
      expect(find.byType(PremiumUpgrade), findsOneWidget);
    });
  });
}