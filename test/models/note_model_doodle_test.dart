import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note_model.dart';

void main() {
  group('Note Model with Doodles', () {
    test('should create note with doodle paths', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
        title: 'Test Note',
        content: 'Test content',
        createdAt: now,
        updatedAt: now,
        doodlePaths: ['doodle1.json', 'doodle2.json'],
      );

      expect(note.doodlePaths.length, equals(2));
      expect(note.doodlePaths, contains('doodle1.json'));
      expect(note.doodlePaths, contains('doodle2.json'));
      expect(note.hasDoodles, equals(true));
      expect(note.hasAttachments, equals(true));
    });

    test('should create note without doodles', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
        title: 'Test Note',
        content: 'Test content',
        createdAt: now,
        updatedAt: now,
      );

      expect(note.doodlePaths.length, equals(0));
      expect(note.hasDoodles, equals(false));
    });

    test('should convert note with doodles to and from JSON', () {
      final now = DateTime.now();
      final originalNote = Note(
        id: 'test-note',
        title: 'Note with Doodles',
        content: 'This note has doodles',
        createdAt: now,
        updatedAt: now,
        folder: 'Art',
        tags: ['creative', 'drawing'],
        doodlePaths: ['art1.json', 'sketch2.json'],
        imagePaths: ['photo.jpg'],
      );

      final json = originalNote.toJson();
      final restoredNote = Note.fromJson(json);

      expect(restoredNote.id, equals(originalNote.id));
      expect(restoredNote.title, equals(originalNote.title));
      expect(restoredNote.content, equals(originalNote.content));
      expect(restoredNote.folder, equals(originalNote.folder));
      expect(restoredNote.tags, equals(originalNote.tags));
      expect(restoredNote.doodlePaths, equals(originalNote.doodlePaths));
      expect(restoredNote.imagePaths, equals(originalNote.imagePaths));
      expect(restoredNote.hasDoodles, equals(originalNote.hasDoodles));
    });

    test('should detect changes including doodle paths', () {
      final now = DateTime.now();
      final note1 = Note(
        id: '1',
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
        doodlePaths: ['doodle1.json'],
      );

      final note2 = note1.copyWith(
        doodlePaths: ['doodle1.json', 'doodle2.json'],
      );

      expect(note1.hasChangesFrom(note2), equals(true));
      expect(note2.hasChangesFrom(note1), equals(true));
    });

    test('should copy note with updated doodle paths', () {
      final now = DateTime.now();
      final originalNote = Note(
        id: '1',
        title: 'Original',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
        doodlePaths: ['old.json'],
      );

      final newDoodlePaths = ['new1.json', 'new2.json'];
      final copiedNote = originalNote.copyWith(
        doodlePaths: newDoodlePaths,
        title: 'Updated',
      );

      expect(copiedNote.id, equals(originalNote.id));
      expect(copiedNote.title, equals('Updated'));
      expect(copiedNote.content, equals(originalNote.content));
      expect(copiedNote.doodlePaths, equals(newDoodlePaths));
      expect(copiedNote.doodlePaths, isNot(equals(originalNote.doodlePaths)));
    });

    test('should handle missing doodle paths in JSON', () {
      final json = {
        'id': 'test',
        'title': 'Test',
        'content': 'Content',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'folder': 'General',
        'tags': <String>[],
        'imagePaths': <String>[],
        'attachmentPaths': <String>[],
        'voiceNotePaths': <String>[],
        // Missing doodlePaths
      };

      final note = Note.fromJson(json);
      
      expect(note.doodlePaths, equals(<String>[]));
      expect(note.hasDoodles, equals(false));
    });

    test('should include doodles in toString output', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
        doodlePaths: ['art.json', 'sketch.json'],
      );

      final string = note.toString();
      
      expect(string, contains('doodles: 2'));
      expect(string, contains('id: 1'));
      expect(string, contains('title: Test'));
    });

    test('should correctly identify has attachments with doodles', () {
      final now = DateTime.now();
      
      final noteWithOnlyDoodles = Note(
        id: '1',
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
        doodlePaths: ['doodle.json'],
      );

      final noteWithMixedAttachments = Note(
        id: '2',
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
        imagePaths: ['photo.jpg'],
        doodlePaths: ['doodle.json'],
        voiceNotePaths: ['voice.m4a'],
      );

      final noteWithoutAttachments = Note(
        id: '3',
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      expect(noteWithOnlyDoodles.hasAttachments, equals(true));
      expect(noteWithMixedAttachments.hasAttachments, equals(true));
      expect(noteWithoutAttachments.hasAttachments, equals(false));
    });
  });
}