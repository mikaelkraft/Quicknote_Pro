import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/models/note_model.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';
import 'package:quicknote_pro/services/notes/notes_service.dart';
import 'package:quicknote_pro/presentation/note_creation_editor/note_creation_editor.dart';
import 'package:quicknote_pro/services/theme/theme_service.dart';

void main() {
  group('NoteCreationEditor Widget Tests', () {
    late NotesService notesService;
    late ThemeService themeService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      final repository = NotesRepository();
      notesService = NotesService(repository);
      await notesService.initialize();
      
      themeService = ThemeService();
      await themeService.initialize();
    });

    tearDown(() async {
      await NotesRepository().clearAllNotes();
      notesService.dispose();
    });

    Widget createTestWidget({String? noteId}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: notesService),
            ChangeNotifierProvider.value(value: themeService),
          ],
          child: NoteCreationEditor(noteId: noteId),
        ),
      );
    }

    testWidgets('should display note editor with title and content fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for title field
      expect(find.byType(TextField), findsAtLeast(2));
      expect(find.text('Note title...'), findsOneWidget);
      expect(find.text('Start writing your note...'), findsOneWidget);
    });

    testWidgets('should allow typing in title and content fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find text fields
      final titleField = find.widgetWithText(TextField, 'Note title...');
      final contentField = find.widgetWithText(TextField, 'Start writing your note...');

      // Type in title
      await tester.enterText(titleField, 'Test Note Title');
      await tester.pump();

      // Type in content  
      await tester.enterText(contentField, 'This is test content');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Test Note Title'), findsOneWidget);
      expect(find.text('This is test content'), findsOneWidget);
    });

    testWidgets('should show save button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for save icon in app bar
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('should show floating action buttons for drawing and image', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for floating action buttons
      expect(find.byType(FloatingActionButton), findsAtLeast(2));
    });

    testWidgets('should show popup menu with export, share, delete options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the more menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Check for menu items
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should open image insertion dialog when tapping image FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the image FAB (should be the second one)
      final imageFabs = find.byType(FloatingActionButton);
      await tester.tap(imageFabs.last);
      await tester.pumpAndSettle();

      // Should show image insertion dialog
      expect(find.text('Insert Image'), findsOneWidget);
      expect(find.text('Add Image'), findsOneWidget);
    });

    testWidgets('should save note when save button is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter some content
      final titleField = find.widgetWithText(TextField, 'Note title...');
      await tester.enterText(titleField, 'Test Note');
      await tester.pump();

      // Tap save button
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Note saved successfully'), findsOneWidget);
    });

    testWidgets('should show unsaved changes dialog when back button is pressed with changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter some content to create unsaved changes
      final titleField = find.widgetWithText(TextField, 'Note title...');
      await tester.enterText(titleField, 'Unsaved Note');
      await tester.pump();

      // Try to go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should show unsaved changes dialog
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('You have unsaved changes. Do you want to save before leaving?'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('should load existing note when noteId is provided', (tester) async {
      // Create a note first
      final existingNote = await notesService.createNote(
        title: 'Existing Note',
        content: 'Existing content',
      );

      await tester.pumpWidget(createTestWidget(noteId: existingNote.id));
      await tester.pumpAndSettle();

      // Should load the existing note content
      expect(find.text('Existing Note'), findsOneWidget);
      expect(find.text('Existing content'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should show delete confirmation
      expect(find.text('Delete Note'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this note? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsAtLeast(1)); // At least one Delete button
    });

    testWidgets('should show export options dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap export
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Should show export options
      expect(find.text('Export Note'), findsOneWidget);
      expect(find.text('Export as TXT'), findsOneWidget);
      expect(find.text('Export as PDF'), findsOneWidget);
    });

    testWidgets('should close image insertion dialog when close button is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open image insertion dialog
      final imageFabs = find.byType(FloatingActionButton);
      await tester.tap(imageFabs.last);
      await tester.pumpAndSettle();

      expect(find.text('Insert Image'), findsOneWidget);

      // Close the dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Insert Image'), findsNothing);
    });

    testWidgets('should handle back navigation without unsaved changes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go back without making changes
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should not show unsaved changes dialog
      expect(find.text('Unsaved Changes'), findsNothing);
    });
  });
}