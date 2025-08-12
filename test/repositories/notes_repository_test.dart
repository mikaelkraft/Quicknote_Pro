import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quicknote_pro/models/note_model.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';

void main() {
  group('NotesRepository Tests', () {
    late NotesRepository repository;
    late Note testNote;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      repository = NotesRepository();
      await repository.initialize();

      testNote = Note(
        id: 'test_note_1',
        title: 'Test Note',
        content: 'This is a test note',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        folder: 'Test',
        tags: ['test', 'note'],
      );
    });

    tearDown(() async {
      await repository.clearAllNotes();
    });

    test('should save and retrieve a note', () async {
      await repository.saveNote(testNote);
      
      final retrievedNote = await repository.getNoteById(testNote.id);
      expect(retrievedNote, isNotNull);
      expect(retrievedNote!.id, testNote.id);
      expect(retrievedNote.title, testNote.title);
      expect(retrievedNote.content, testNote.content);
    });

    test('should save and retrieve multiple notes', () async {
      final note1 = testNote;
      final note2 = testNote.copyWith(id: 'test_note_2', title: 'Second Note');
      final note3 = testNote.copyWith(id: 'test_note_3', title: 'Third Note');

      await repository.saveNote(note1);
      await repository.saveNote(note2);
      await repository.saveNote(note3);

      final allNotes = await repository.getAllNotes();
      expect(allNotes.length, 3);
      expect(allNotes.any((note) => note.id == note1.id), isTrue);
      expect(allNotes.any((note) => note.id == note2.id), isTrue);
      expect(allNotes.any((note) => note.id == note3.id), isTrue);
    });

    test('should update existing note', () async {
      await repository.saveNote(testNote);
      
      final updatedNote = testNote.copyWith(
        title: 'Updated Title',
        content: 'Updated content',
      );
      await repository.saveNote(updatedNote);

      final retrievedNote = await repository.getNoteById(testNote.id);
      expect(retrievedNote!.title, 'Updated Title');
      expect(retrievedNote.content, 'Updated content');

      final allNotes = await repository.getAllNotes();
      expect(allNotes.length, 1); // Should not create duplicate
    });

    test('should delete a note', () async {
      await repository.saveNote(testNote);
      
      final beforeDelete = await repository.getAllNotes();
      expect(beforeDelete.length, 1);

      await repository.deleteNote(testNote.id);

      final afterDelete = await repository.getAllNotes();
      expect(afterDelete.length, 0);

      final deletedNote = await repository.getNoteById(testNote.id);
      expect(deletedNote, isNull);
    });

    test('should search notes by title and content', () async {
      final note1 = testNote.copyWith(id: 'note1', title: 'Flutter Development');
      final note2 = testNote.copyWith(id: 'note2', content: 'Learning Dart programming');
      final note3 = testNote.copyWith(id: 'note3', title: 'React Native', content: 'JavaScript');

      await repository.saveNote(note1);
      await repository.saveNote(note2);
      await repository.saveNote(note3);

      final flutterResults = await repository.searchNotes('Flutter');
      expect(flutterResults.length, 1);
      expect(flutterResults.first.id, 'note1');

      final dartResults = await repository.searchNotes('Dart');
      expect(dartResults.length, 1);
      expect(dartResults.first.id, 'note2');

      final programmingResults = await repository.searchNotes('program');
      expect(programmingResults.length, 1); // Case insensitive
    });

    test('should get notes by folder', () async {
      final note1 = testNote.copyWith(id: 'note1', folder: 'Work');
      final note2 = testNote.copyWith(id: 'note2', folder: 'Personal');
      final note3 = testNote.copyWith(id: 'note3', folder: 'Work');

      await repository.saveNote(note1);
      await repository.saveNote(note2);
      await repository.saveNote(note3);

      final workNotes = await repository.getNotesByFolder('Work');
      expect(workNotes.length, 2);

      final personalNotes = await repository.getNotesByFolder('Personal');
      expect(personalNotes.length, 1);
    });

    test('should get all folders', () async {
      final note1 = testNote.copyWith(id: 'note1', folder: 'Work');
      final note2 = testNote.copyWith(id: 'note2', folder: 'Personal');
      final note3 = testNote.copyWith(id: 'note3', folder: 'Work');

      await repository.saveNote(note1);
      await repository.saveNote(note2);
      await repository.saveNote(note3);

      final folders = await repository.getAllFolders();
      expect(folders.length, 2);
      expect(folders.contains('Work'), isTrue);
      expect(folders.contains('Personal'), isTrue);
    });

    test('should get all tags', () async {
      final note1 = testNote.copyWith(id: 'note1', tags: ['flutter', 'mobile']);
      final note2 = testNote.copyWith(id: 'note2', tags: ['dart', 'programming']);
      final note3 = testNote.copyWith(id: 'note3', tags: ['flutter', 'dart']);

      await repository.saveNote(note1);
      await repository.saveNote(note2);
      await repository.saveNote(note3);

      final tags = await repository.getAllTags();
      expect(tags.length, 4);
      expect(tags.contains('flutter'), isTrue);
      expect(tags.contains('mobile'), isTrue);
      expect(tags.contains('dart'), isTrue);
      expect(tags.contains('programming'), isTrue);
    });

    test('should export and import notes', () async {
      final note1 = testNote.copyWith(id: 'note1');
      final note2 = testNote.copyWith(id: 'note2', title: 'Second Note');

      await repository.saveNote(note1);
      await repository.saveNote(note2);

      final exportData = await repository.exportNotesAsJson();
      expect(exportData['notes_count'], 2);
      expect(exportData['notes'], isA<List>());

      // Clear notes and import
      await repository.clearAllNotes();
      final importedCount = await repository.importNotesFromJson(exportData);
      expect(importedCount, 2);

      final allNotes = await repository.getAllNotes();
      expect(allNotes.length, 2);
    });

    test('should get storage statistics', () async {
      final note1 = testNote.copyWith(
        id: 'note1',
        imagePaths: ['image1.jpg', 'image2.jpg'],
        attachmentPaths: ['file1.pdf'],
      );
      final note2 = testNote.copyWith(
        id: 'note2',
        voiceNotePaths: ['voice1.m4a'],
      );

      await repository.saveNote(note1);
      await repository.saveNote(note2);

      final stats = await repository.getStorageStats();
      expect(stats['total_notes'], 2);
      expect(stats['total_images'], 2);
      expect(stats['total_attachments'], 1);
      expect(stats['total_voice_notes'], 1);
      expect(stats['total_characters'], greaterThan(0));
    });

    test('should handle corrupted note data gracefully', () async {
      // Manually corrupt data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('note_ids', ['corrupted_note']);
      await prefs.setString('note_corrupted_note', 'invalid_json');

      final note = await repository.getNoteById('corrupted_note');
      expect(note, isNull);

      final allNotes = await repository.getAllNotes();
      expect(allNotes.length, 0); // Corrupted note should be removed
    });

    test('should sort notes by updated date', () async {
      final note1 = testNote.copyWith(
        id: 'note1',
        updatedAt: DateTime(2024, 1, 1),
      );
      final note2 = testNote.copyWith(
        id: 'note2',
        updatedAt: DateTime(2024, 1, 3),
      );
      final note3 = testNote.copyWith(
        id: 'note3',
        updatedAt: DateTime(2024, 1, 2),
      );

      await repository.saveNote(note1);
      await repository.saveNote(note2);
      await repository.saveNote(note3);

      final allNotes = await repository.getAllNotes();
      expect(allNotes[0].id, 'note2'); // Most recent first
      expect(allNotes[1].id, 'note3');
      expect(allNotes[2].id, 'note1');
    });
  });
}