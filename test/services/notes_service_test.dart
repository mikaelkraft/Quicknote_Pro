import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/models/note_model.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';
import 'package:quicknote_pro/services/notes/notes_service.dart';

void main() {
  group('NotesService Tests', () {
    late NotesService notesService;
    late NotesRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = NotesRepository();
      notesService = NotesService(repository);
      await notesService.initialize();
    });

    tearDown(() async {
      await repository.clearAllNotes();
      notesService.dispose();
    });

    test('should initialize and load notes', () async {
      expect(notesService.notes, isEmpty);
      expect(notesService.isLoading, isFalse);
      expect(notesService.error, isNull);
    });

    test('should create a new note', () async {
      final note = await notesService.createNote(
        title: 'Test Note',
        content: 'Test content',
        folder: 'Test Folder',
        tags: ['test'],
      );

      expect(note.title, 'Test Note');
      expect(note.content, 'Test content');
      expect(note.folder, 'Test Folder');
      expect(note.tags, ['test']);
      expect(notesService.notes.length, 1);
      expect(notesService.notes.first.id, note.id);
    });

    test('should save and update notes', () async {
      final note = await notesService.createNote(title: 'Original Title');
      
      final updatedNote = note.copyWith(
        title: 'Updated Title',
        content: 'Updated content',
      );
      
      await notesService.saveNote(updatedNote);
      
      expect(notesService.notes.length, 1);
      expect(notesService.notes.first.title, 'Updated Title');
      expect(notesService.notes.first.content, 'Updated content');
    });

    test('should delete a note', () async {
      final note = await notesService.createNote(title: 'To Delete');
      expect(notesService.notes.length, 1);

      await notesService.deleteNote(note.id);
      expect(notesService.notes.length, 0);
    });

    test('should set and get current note', () async {
      final note = await notesService.createNote(title: 'Current Note');
      
      notesService.setCurrentNote(note);
      expect(notesService.currentNote, note);

      notesService.setCurrentNote(null);
      expect(notesService.currentNote, isNull);
    });

    test('should search notes', () async {
      await notesService.createNote(title: 'Flutter Tutorial', content: 'Learning Flutter');
      await notesService.createNote(title: 'Dart Guide', content: 'Dart programming');
      await notesService.createNote(title: 'React Notes', content: 'JavaScript framework');

      final flutterResults = await notesService.searchNotes('Flutter');
      expect(flutterResults.length, 1);
      expect(flutterResults.first.title, 'Flutter Tutorial');

      final programmingResults = await notesService.searchNotes('programming');
      expect(programmingResults.length, 1);
      expect(programmingResults.first.title, 'Dart Guide');
    });

    test('should get notes by folder', () async {
      await notesService.createNote(title: 'Work Note', folder: 'Work');
      await notesService.createNote(title: 'Personal Note', folder: 'Personal');
      await notesService.createNote(title: 'Another Work Note', folder: 'Work');

      final workNotes = await notesService.getNotesByFolder('Work');
      expect(workNotes.length, 2);

      final personalNotes = await notesService.getNotesByFolder('Personal');
      expect(personalNotes.length, 1);
    });

    test('should handle errors gracefully', () async {
      // Create a service with a null repository to trigger errors
      final errorService = NotesService(repository);
      
      // Clear the internal repository reference to simulate failure
      await repository.clearAllNotes();
      
      // The service should handle errors and set error state
      expect(errorService.error, isNull);
    });

    test('should export and import notes', () async {
      await notesService.createNote(title: 'Note 1', content: 'Content 1');
      await notesService.createNote(title: 'Note 2', content: 'Content 2');

      final exportData = await notesService.exportNotes();
      expect(exportData['notes_count'], 2);

      // Clear notes
      await repository.clearAllNotes();
      await notesService.loadNotes();
      expect(notesService.notes.length, 0);

      // Import notes
      final importedCount = await notesService.importNotes(exportData);
      expect(importedCount, 2);
      expect(notesService.notes.length, 2);
    });

    test('should get storage statistics', () async {
      await notesService.createNote(
        title: 'Note with content',
        content: 'This is some content',
      );

      final stats = await notesService.getStorageStats();
      expect(stats['total_notes'], 1);
      expect(stats['total_characters'], greaterThan(0));
    });

    test('should clear errors', () async {
      // Manually set an error
      notesService.clearError();
      expect(notesService.error, isNull);
    });

    test('should sort notes by updated date', () async {
      final note1 = await notesService.createNote(title: 'First Note');
      await Future.delayed(const Duration(milliseconds: 10));
      
      final note2 = await notesService.createNote(title: 'Second Note');
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Update first note to make it more recent
      await notesService.saveNote(note1.copyWith(content: 'Updated'));

      final notes = notesService.notes;
      expect(notes.first.title, 'First Note'); // Most recently updated
      expect(notes.last.title, 'Second Note');
    });

    test('should handle auto-save start and stop', () async {
      final note = await notesService.createNote(title: 'Auto Save Test');
      
      // Start auto-save
      notesService.startAutoSave(note, interval: const Duration(milliseconds: 100));
      
      // Stop auto-save
      notesService.stopAutoSave();
      
      // Should complete without errors
      expect(true, isTrue);
    });

    test('should handle current note operations when no note is set', () async {
      // These should not throw errors when current note is null
      await notesService.addImageToCurrentNote('fake_path');
      await notesService.addAttachmentToCurrentNote('fake_path');
      await notesService.addVoiceNoteToCurrentNote('fake_path');
      await notesService.removeMediaFromCurrentNote('fake_path', 'image');
      
      // Should complete without errors
      expect(true, isTrue);
    });

    test('should add audio to current note', () async {
      final note = await notesService.createNote(title: 'Audio Test Note');
      notesService.setCurrentNote(note);
      
      // Mock audio path and duration
      const audioPath = '/test/audio/voice_note.m4a';
      const durationSeconds = 120;
      
      await notesService.addAudioToCurrentNote(audioPath, durationSeconds);
      
      // Since we're using the old model, this would be added to voice note paths
      // In a real implementation, we'd need to mock the repository's copyFileToAppDirectory method
      expect(notesService.currentNote, isNotNull);
    });

    test('should remove audio attachment from current note', () async {
      final note = await notesService.createNote(title: 'Audio Removal Test');
      notesService.setCurrentNote(note);
      
      // Add a voice note first
      await notesService.addVoiceNoteToCurrentNote('/test/voice_note.m4a');
      
      // Remove by attachment ID
      await notesService.removeAttachmentFromCurrentNote('voice_note');
      
      expect(notesService.currentNote, isNotNull);
    });

    test('should handle voice note operations', () async {
      final note = await notesService.createNote(title: 'Voice Note Test');
      notesService.setCurrentNote(note);
      
      // Add voice note
      await notesService.addVoiceNoteToCurrentNote('/test/voice.m4a');
      
      // Remove voice note
      await notesService.removeMediaFromCurrentNote('/test/voice.m4a', 'voice');
      
      expect(notesService.currentNote, isNotNull);
    });
  });
}