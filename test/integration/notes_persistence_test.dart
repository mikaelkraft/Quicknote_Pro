import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/models/note_model.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';
import 'package:quicknote_pro/services/notes/notes_service.dart';
import 'package:quicknote_pro/services/theme/theme_service.dart';
import 'package:quicknote_pro/presentation/note_creation_editor/note_creation_editor.dart';
import 'package:quicknote_pro/presentation/notes_dashboard/notes_dashboard.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notes Persistence Integration Tests', () {
    late NotesService notesService;
    late ThemeService themeService;

    setUp(() async {
      // Clear any existing data
      SharedPreferences.setMockInitialValues({});
      
      // Initialize services
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

    Widget createTestApp() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: notesService),
            ChangeNotifierProvider.value(value: themeService),
          ],
          child: const TestNavigator(),
        ),
      );
    }

    testWidgets('should persist note across app restart simulation', (tester) async {
      // Phase 1: Create and save a note
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to note editor
      await tester.tap(find.text('Create Note'));
      await tester.pumpAndSettle();

      // Enter note content
      final titleField = find.widgetWithText(TextField, 'Note title...');
      final contentField = find.widgetWithText(TextField, 'Start writing your note...');
      
      await tester.enterText(titleField, 'Integration Test Note');
      await tester.pump();
      
      await tester.enterText(contentField, 'This note should persist across restarts');
      await tester.pump();

      // Save the note
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Verify save success
      expect(find.text('Note saved successfully'), findsOneWidget);
      
      // Go back to dashboard
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Phase 2: Simulate app restart by recreating services
      final oldNotesService = notesService;
      oldNotesService.dispose();

      // Create new services (simulating app restart)
      final newRepository = NotesRepository();
      final newNotesService = NotesService(newRepository);
      await newNotesService.initialize();

      // Phase 3: Verify note persisted
      final persistedNotes = await newNotesService.getAllNotes();
      expect(persistedNotes.length, 1);
      expect(persistedNotes.first.title, 'Integration Test Note');
      expect(persistedNotes.first.content, 'This note should persist across restarts');

      // Clean up
      await newNotesService.dispose();
    });

    testWidgets('should handle multiple notes creation and persistence', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create first note
      await tester.tap(find.text('Create Note'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Note title...'), 'First Note');
      await tester.enterText(find.widgetWithText(TextField, 'Start writing your note...'), 'First content');
      
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Create second note
      await tester.tap(find.text('Create Note'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Note title...'), 'Second Note');
      await tester.enterText(find.widgetWithText(TextField, 'Start writing your note...'), 'Second content');
      
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify both notes exist
      final allNotes = notesService.notes;
      expect(allNotes.length, 2);
      
      // Notes should be sorted by updated date (most recent first)
      expect(allNotes.any((note) => note.title == 'First Note'), isTrue);
      expect(allNotes.any((note) => note.title == 'Second Note'), isTrue);
    });

    testWidgets('should handle note deletion and persistence', (tester) async {
      // Create a note first
      final note = await notesService.createNote(
        title: 'Note to Delete',
        content: 'This will be deleted',
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to note editor with existing note
      // (This would normally be done through dashboard, but we're testing the service directly)
      notesService.setCurrentNote(note);

      await tester.tap(find.text('Edit Note'));
      await tester.pumpAndSettle();

      // Open popup menu and delete
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // Verify note was deleted
      expect(notesService.notes.length, 0);
      
      // Verify persistence - note should not exist after service restart
      final newRepository = NotesRepository();
      await newRepository.initialize();
      final deletedNote = await newRepository.getNoteById(note.id);
      expect(deletedNote, isNull);
      
      await newRepository.clearAllNotes();
    });

    testWidgets('should handle unsaved changes correctly', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to note editor
      await tester.tap(find.text('Create Note'));
      await tester.pumpAndSettle();

      // Enter some content but don't save
      await tester.enterText(find.widgetWithText(TextField, 'Note title...'), 'Unsaved Note');
      await tester.pump();

      // Try to go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should show unsaved changes dialog
      expect(find.text('Unsaved Changes'), findsOneWidget);

      // Choose to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should save and navigate back
      expect(notesService.notes.length, 1);
      expect(notesService.notes.first.title, 'Unsaved Note');
    });

    testWidgets('should preserve note order after modifications', (tester) async {
      // Create multiple notes with different timestamps
      final note1 = await notesService.createNote(title: 'Old Note');
      await Future.delayed(const Duration(milliseconds: 10));
      
      final note2 = await notesService.createNote(title: 'Middle Note');
      await Future.delayed(const Duration(milliseconds: 10));
      
      final note3 = await notesService.createNote(title: 'New Note');

      // Update the old note to make it most recent
      await notesService.saveNote(note1.copyWith(content: 'Updated content'));

      // Verify order is correct (most recently updated first)
      final notes = notesService.notes;
      expect(notes[0].title, 'Old Note'); // Most recently updated
      expect(notes[1].title, 'New Note');
      expect(notes[2].title, 'Middle Note');
    });
  });
}

/// Test widget that simulates basic navigation
class TestNavigator extends StatelessWidget {
  const TestNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoteCreationEditor(),
                  ),
                );
              },
              child: const Text('Create Note'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final notesService = Provider.of<NotesService>(context, listen: false);
                if (notesService.currentNote != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteCreationEditor(
                        noteId: notesService.currentNote!.id,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Edit Note'),
            ),
            const SizedBox(height: 16),
            Consumer<NotesService>(
              builder: (context, notesService, child) {
                return Text('Notes: ${notesService.notes.length}');
              },
            ),
          ],
        ),
      ),
    );
  }
}