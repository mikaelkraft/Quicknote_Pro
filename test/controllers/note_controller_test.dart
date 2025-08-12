import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/controllers/note_controller.dart';
import 'package:quicknote_pro/services/note_persistence_service.dart';
import 'package:quicknote_pro/services/attachment_service.dart';
import 'package:quicknote_pro/models/note.dart';
import 'package:quicknote_pro/models/attachment.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';

import '../mocks/mock_repositories.dart';

void main() {
  group('NoteController Tests', () {
    late NoteController noteController;
    late MockNotesRepository mockRepository;
    late NotePersistenceService persistenceService;
    late AttachmentService attachmentService;

    setUp(() async {
      mockRepository = MockNotesRepository();
      persistenceService = NotePersistenceService(mockRepository);
      attachmentService = AttachmentService();
      
      await attachmentService.initialize();
      
      noteController = NoteController(persistenceService, attachmentService);
    });

    tearDown(() {
      noteController.dispose();
    });

    test('should create new note with Note.create()', () {
      noteController.createNew(title: 'Test Title', content: 'Test Content');

      expect(noteController.currentNote, isNotNull);
      expect(noteController.currentNote!.title, 'Test Title');
      expect(noteController.currentNote!.content, 'Test Content');
      expect(noteController.currentNote!.id, isNotEmpty);
      expect(noteController.currentNote!.attachments, isEmpty);
    });

    test('should update text controllers when creating new note', () {
      noteController.createNew(title: 'Controller Title', content: 'Controller Content');

      expect(noteController.titleController.text, 'Controller Title');
      expect(noteController.contentController.text, 'Controller Content');
    });

    test('should handle empty note creation', () {
      noteController.createNew();

      expect(noteController.currentNote, isNotNull);
      expect(noteController.currentNote!.title, isEmpty);
      expect(noteController.currentNote!.content, isEmpty);
      expect(noteController.titleController.text, isEmpty);
      expect(noteController.contentController.text, isEmpty);
    });

    test('should save note with debounced autosave', () async {
      noteController.createNew();
      
      // Simulate typing in title
      noteController.titleController.text = 'Autosave Test';
      
      // Trigger autosave manually
      await noteController.debouncedAutosave();
      
      expect(noteController.currentNote!.title, 'Autosave Test');
      expect(mockRepository.savedNotes.length, 1);
    });

    test('should flush pending saves', () async {
      noteController.createNew();
      
      noteController.titleController.text = 'Flush Test';
      noteController.contentController.text = 'Content to flush';
      
      await noteController.flushPendingSave();
      
      expect(noteController.currentNote!.title, 'Flush Test');
      expect(noteController.currentNote!.content, 'Content to flush');
      expect(mockRepository.savedNotes.length, 1);
    });

    test('should handle saving state correctly', () async {
      noteController.createNew();
      
      expect(noteController.isSaving, false);
      
      // Start save operation
      final saveOperation = noteController.saveNote();
      
      await saveOperation;
      
      expect(noteController.isSaving, false);
    });

    test('should clear error after successful operation', () async {
      noteController.createNew();
      
      // Clear any existing error
      noteController.clearError();
      expect(noteController.error, isNull);
      
      await noteController.saveNote();
      expect(noteController.error, isNull);
    });

    test('should delete current note and clear state', () async {
      noteController.createNew(title: 'To Delete', content: 'Delete me');
      await noteController.saveNote();
      
      final noteId = noteController.currentNote!.id;
      
      await noteController.deleteCurrentNote();
      
      expect(noteController.currentNote, isNull);
      expect(noteController.titleController.text, isEmpty);
      expect(noteController.contentController.text, isEmpty);
      expect(mockRepository.deletedNoteIds, contains(noteId));
    });

    test('should return empty attachments list when no current note', () {
      expect(noteController.attachments, isEmpty);
    });

    test('should handle note stream updates', () async {
      noteController.createNew(title: 'Stream Test');
      
      bool streamUpdated = false;
      noteController.noteStream.listen((note) {
        if (note != null && note.title == 'Stream Test') {
          streamUpdated = true;
        }
      });
      
      await Future.delayed(Duration(milliseconds: 100));
      expect(streamUpdated, true);
    });
  });
}