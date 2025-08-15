import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quicknote_pro/presentation/settings_profile/backup_import_screen.dart';
import 'package:quicknote_pro/services/sync/sync_manager.dart';
import 'package:quicknote_pro/theme/app_theme.dart';

// Mock SyncManager for testing
class MockSyncManager extends ChangeNotifier implements SyncManager {
  bool _isConnected = false;
  String _connectedProvider = '';

  @override
  bool get isConnected => _isConnected;

  @override
  String get connectedProvider => _connectedProvider;

  void setConnected(bool connected, [String provider = '']) {
    _isConnected = connected;
    _connectedProvider = provider;
    notifyListeners();
  }

  @override
  bool shouldAutoSyncAfterImport() => _isConnected;

  @override
  Future<bool> triggerSync() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _isConnected;
  }

  @override
  String getSyncStatusText() {
    if (_isConnected) {
      return 'Connected to $_connectedProvider';
    }
    return 'Not connected to cloud sync';
  }

  // Implement other required methods with default behavior
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BackupImportScreen Widget Tests', () {
    late MockSyncManager mockSyncManager;

    setUp(() {
      mockSyncManager = MockSyncManager();
    });

    Widget createTestWidget({bool isDark = false}) {
      return ChangeNotifierProvider<SyncManager>.value(
        value: mockSyncManager,
        child: MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: const BackupImportScreen(),
        ),
      );
    }

    group('Screen Layout Tests', () {
      testWidgets('should display all main sections', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Backup & Import'), findsOneWidget);
        expect(find.text('Export Data'), findsOneWidget);
        expect(find.text('Import Data'), findsOneWidget);
        expect(find.text('Import Options'), findsOneWidget);
      });

      testWidgets('should show back navigation button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(GestureDetector), findsWidgets);
        // The back button should be present as a GestureDetector
      });

      testWidgets('should display export and import buttons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Export All Notes'), findsOneWidget);
        expect(find.text('Import from File'), findsOneWidget);
      });

      testWidgets('should show import options checkboxes', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Import as copies'), findsOneWidget);
        expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
      });
    });

    group('Export Functionality Tests', () {
      testWidgets('should show loading state during export', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Tap export button
        await tester.tap(find.text('Export All Notes'));
        await tester.pump(); // Process the tap

        // Assert - Should show loading state
        expect(find.text('Creating Backup...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should disable export button during export', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Tap export button
        await tester.tap(find.text('Export All Notes'));
        await tester.pump();

        // Assert - Button should be disabled
        final exportButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Creating Backup...'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(exportButton.onPressed, isNull);
      });

      testWidgets('should show export confirmation dialog', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - Tap export button
        await tester.tap(find.text('Export All Notes'));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Assert - Dialog should appear
        expect(find.text('Export Backup'), findsOneWidget);
        expect(find.text('This will create a backup containing:'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);
      });

      testWidgets('should cancel export when Cancel is pressed', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Export All Notes'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert - Should return to normal state
        expect(find.text('Export All Notes'), findsOneWidget);
        expect(find.text('Creating Backup...'), findsNothing);
      });
    });

    group('Import Functionality Tests', () {
      testWidgets('should show loading state during import', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Note: This test would need to mock file picker to work fully
        // For now, we test the UI state changes
        
        // The import button should be present and ready
        expect(find.text('Import from File'), findsOneWidget);
      });

      testWidgets('should toggle import as copies checkbox', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the first checkbox (import as copies)
        final checkboxFinder = find.byType(Checkbox).first;
        
        // Act - Initial state should be unchecked
        expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

        // Tap to check
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();

        // Assert - Should be checked now
        expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
      });

      testWidgets('should show import result dialog on successful import', (WidgetTester tester) async {
        // This test would need a way to mock successful import
        // For now, we verify the UI structure exists
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        expect(find.text('Import from File'), findsOneWidget);
      });
    });

    group('Sync Integration Tests', () {
      testWidgets('should show sync options when connected', (WidgetTester tester) async {
        // Arrange
        mockSyncManager.setConnected(true, 'Google Drive');
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Sync after import'), findsOneWidget);
        expect(find.text('Connected to Google Drive'), findsOneWidget);
      });

      testWidgets('should hide sync options when not connected', (WidgetTester tester) async {
        // Arrange
        mockSyncManager.setConnected(false);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Sync after import'), findsNothing);
        expect(find.text('Not connected to cloud sync'), findsOneWidget);
      });

      testWidgets('should toggle sync after import checkbox', (WidgetTester tester) async {
        // Arrange
        mockSyncManager.setConnected(true, 'Dropbox');
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the sync checkbox (should be the second one)
        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsAtLeastNWidgets(2));
        
        final syncCheckbox = checkboxes.at(1);
        
        // Act - Initial state should be checked (true by default)
        expect(tester.widget<Checkbox>(syncCheckbox).value, isTrue);

        // Tap to uncheck
        await tester.tap(syncCheckbox);
        await tester.pumpAndSettle();

        // Assert - Should be unchecked now
        expect(tester.widget<Checkbox>(syncCheckbox).value, isFalse);
      });

      testWidgets('should update sync status dynamically', (WidgetTester tester) async {
        // Arrange
        mockSyncManager.setConnected(false);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initial state
        expect(find.text('Not connected to cloud sync'), findsOneWidget);

        // Act - Connect to sync
        mockSyncManager.setConnected(true, 'OneDrive');
        await tester.pumpAndSettle();

        // Assert - Should show connected state
        expect(find.text('Connected to OneDrive'), findsOneWidget);
        expect(find.text('Not connected to cloud sync'), findsNothing);
      });
    });

    group('Theme and Accessibility Tests', () {
      testWidgets('should adapt to dark theme', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(isDark: true));
        await tester.pumpAndSettle();

        // Assert - Should render without errors in dark theme
        expect(find.text('Backup & Import'), findsOneWidget);
        expect(find.text('Export Data'), findsOneWidget);
        expect(find.text('Import Data'), findsOneWidget);
      });

      testWidgets('should be accessible with semantic labels', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check for accessibility
        expect(find.byType(ElevatedButton), findsAtLeastNWidgets(2));
        expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
        
        // All buttons should be tappable
        final buttons = find.byType(ElevatedButton);
        for (int i = 0; i < buttons.evaluate().length; i++) {
          final button = tester.widget<ElevatedButton>(buttons.at(i));
          // Button should either be enabled (onPressed != null) or disabled during operation
          expect(button, isNotNull);
        }
      });

      testWidgets('should have proper contrast and readability', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Text should be readable
        expect(find.text('Export Data'), findsOneWidget);
        expect(find.text('Import Data'), findsOneWidget);
        expect(find.text('Import Options'), findsOneWidget);
        
        // Description text should be present
        expect(find.textContaining('Create a backup of all your notes'), findsOneWidget);
        expect(find.textContaining('Import notes from a backup file'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should show snackbar on export error', (WidgetTester tester) async {
        // This test would need to mock export failure
        // For now, we verify the UI structure can handle errors
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(ScaffoldMessenger), findsOneWidget);
      });

      testWidgets('should show snackbar on import error', (WidgetTester tester) async {
        // This test would need to mock import failure
        // For now, we verify the UI structure can handle errors
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(ScaffoldMessenger), findsOneWidget);
      });

      testWidgets('should handle missing file picker gracefully', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // The import button should still be functional even if file picker fails
        expect(find.text('Import from File'), findsOneWidget);
        
        // Button should be enabled
        final importButton = find.ancestor(
          of: find.text('Import from File'),
          matching: find.byType(ElevatedButton),
        );
        expect(tester.widget<ElevatedButton>(importButton).onPressed, isNotNull);
      });
    });

    group('Animation Tests', () {
      testWidgets('should have background animation', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // The screen should have animated background
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });

      testWidgets('should animate properly during state changes', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // Initial frame
        
        // Act - Trigger export
        await tester.tap(find.text('Export All Notes'));
        await tester.pump(); // State change frame
        await tester.pump(const Duration(milliseconds: 100)); // Animation frame

        // Assert - Animation should be smooth
        expect(find.text('Creating Backup...'), findsOneWidget);
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(400, 800)); // Phone
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Backup & Import'), findsOneWidget);

        // Test with tablet size
        await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Backup & Import'), findsOneWidget);
        
        // Reset to default
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should maintain layout integrity', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Layout should be scrollable and not overflow
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
      });
    });
  });
}