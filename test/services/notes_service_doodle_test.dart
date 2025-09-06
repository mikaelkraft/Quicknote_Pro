import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note_model.dart';
import 'package:quicknote_pro/models/doodle_data.dart';
import 'package:quicknote_pro/services/notes/notes_service.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';

class MockNotesRepository extends NotesRepository {
  final Map<String, Note> _notes = {};
  final Map<String, String> _doodles = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<List<Note>> getAllNotes() async {
    return _notes.values.toList();
  }

  @override
  Future<Note?> getNoteById(String id) async {
    return _notes[id];
  }

  @override
  Future<void> saveNote(Note note) async {
    _notes[note.id] = note;
  }

  @override
  Future<String?> saveDoodleData(String noteId, String doodleJsonData) async {
    final path = 'media/doodles/${noteId}_doodle_${DateTime.now().millisecondsSinceEpoch}.json';
    _doodles[path] = doodleJsonData;
    return path;
  }

  @override
  Future<void> updateDoodleData(String doodlePath, String doodleJsonData) async {
    _doodles[doodlePath] = doodleJsonData;
  }

  @override
  Future<String?> loadDoodleData(String doodlePath) async {
    return _doodles[doodlePath];
  }

  @override
  Future<void> deleteDoodleData(String doodlePath) async {
    _doodles.remove(doodlePath);
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.remove(id);
  }
}

void main() {
  group('NotesService Doodle Integration', () {
    late NotesService notesService;
    late MockNotesRepository mockRepository;

    setUp(() {
      mockRepository = MockNotesRepository();
      notesService = NotesService(mockRepository);
    });

    test('should initialize service', () async {
      await notesService.initialize();
      expect(notesService.notes, isEmpty);
    });

    test('should create note and add doodle', () async {
      await notesService.initialize();
      
      // Create a note
      final note = await notesService.createNote(
        title: 'Test Note',
        content: 'Test content',
      );
      
      // Set as current note
      notesService.setCurrentNote(note);
      
      // Create test doodle data
      final doodleData = DoodleData.createNew();
      final doodleJsonData = doodleData.toJsonString();
      
      // Add doodle to current note
      final doodlePath = await notesService.addDoodleToCurrentNote(doodleJsonData);
      
      expect(doodlePath, isNotNull);
      expect(doodlePath, contains('doodle'));
      expect(doodlePath, contains('.json'));
      
      // Verify note was updated
      final updatedNote = await notesService.getNoteById(note.id);
      expect(updatedNote, isNotNull);
      expect(updatedNote!.doodlePaths, contains(doodlePath));
      expect(updatedNote.hasDoodles, isTrue);
    });

    test('should load existing doodle data', () async {
      await notesService.initialize();
      
      // Create a note
      final note = await notesService.createNote(title: 'Test Note');
      notesService.setCurrentNote(note);
      
      // Create and save doodle
      final doodleData = DoodleData.createNew();
      final originalJsonData = doodleData.toJsonString();
      final doodlePath = await notesService.addDoodleToCurrentNote(originalJsonData);
      
      // Load the doodle data back
      final loadedJsonData = await notesService.loadDoodleData(doodlePath!);
      
      expect(loadedJsonData, isNotNull);
      expect(loadedJsonData, equals(originalJsonData));
      
      // Verify we can parse it back to DoodleData
      final loadedDoodleData = DoodleData.fromJsonString(loadedJsonData!);
      expect(loadedDoodleData.layers.length, equals(1));
      expect(loadedDoodleData.isEmpty, isTrue);
    });

    test('should update existing doodle', () async {
      await notesService.initialize();
      
      // Create a note and doodle
      final note = await notesService.createNote(title: 'Test Note');
      notesService.setCurrentNote(note);
      
      final originalDoodle = DoodleData.createNew();
      final doodlePath = await notesService.addDoodleToCurrentNote(
        originalDoodle.toJsonString(),
      );
      
      // Create updated doodle with a stroke
      final stroke = DoodleStroke(
        points: [const Offset(10, 10), const Offset(20, 20)],
        color: const Color(0xFF000000),
        width: 2.0,
        createdAt: DateTime.now(),
      );
      
      final layer = originalDoodle.primaryLayer.copyWith(strokes: [stroke]);
      final updatedDoodle = originalDoodle.copyWith(
        layers: [layer],
        updatedAt: DateTime.now(),
      );
      
      // Update the doodle
      await notesService.updateDoodleInCurrentNote(
        doodlePath!,
        updatedDoodle.toJsonString(),
      );
      
      // Load and verify the update
      final loadedJsonData = await notesService.loadDoodleData(doodlePath);
      final loadedDoodle = DoodleData.fromJsonString(loadedJsonData!);
      
      expect(loadedDoodle.isEmpty, isFalse);
      expect(loadedDoodle.strokeCount, equals(1));
      expect(loadedDoodle.allStrokes.first.points.length, equals(2));
    });

    test('should remove doodle from note', () async {
      await notesService.initialize();
      
      // Create a note with a doodle
      final note = await notesService.createNote(title: 'Test Note');
      notesService.setCurrentNote(note);
      
      final doodleData = DoodleData.createNew();
      final doodlePath = await notesService.addDoodleToCurrentNote(
        doodleData.toJsonString(),
      );
      
      // Verify doodle was added
      expect(notesService.currentNote!.doodlePaths, contains(doodlePath));
      
      // Remove the doodle
      await notesService.removeMediaFromCurrentNote(doodlePath!, 'doodle');
      
      // Verify doodle was removed from note
      expect(notesService.currentNote!.doodlePaths, isNot(contains(doodlePath)));
      expect(notesService.currentNote!.hasDoodles, isFalse);
      
      // Verify doodle file was deleted
      final loadedData = await notesService.loadDoodleData(doodlePath);
      expect(loadedData, isNull);
    });

    test('should handle multiple doodles in one note', () async {
      await notesService.initialize();
      
      // Create a note
      final note = await notesService.createNote(title: 'Multi-Doodle Note');
      notesService.setCurrentNote(note);
      
      // Add multiple doodles
      final doodle1 = DoodleData.createNew();
      final doodle2 = DoodleData.createNew();
      
      final path1 = await notesService.addDoodleToCurrentNote(doodle1.toJsonString());
      final path2 = await notesService.addDoodleToCurrentNote(doodle2.toJsonString());
      
      // Verify both doodles are in the note
      final updatedNote = notesService.currentNote!;
      expect(updatedNote.doodlePaths.length, equals(2));
      expect(updatedNote.doodlePaths, contains(path1));
      expect(updatedNote.doodlePaths, contains(path2));
      
      // Verify both doodles can be loaded
      final loaded1 = await notesService.loadDoodleData(path1!);
      final loaded2 = await notesService.loadDoodleData(path2!);
      
      expect(loaded1, isNotNull);
      expect(loaded2, isNotNull);
      expect(loaded1, isNot(equals(loaded2))); // Different objects
    });

    test('should handle error when saving doodle fails', () async {
      await notesService.initialize();
      
      // Create a note but don't set it as current
      await notesService.createNote(title: 'Test Note');
      // notesService.setCurrentNote is not called intentionally
      
      // Try to add doodle without current note set
      final doodleData = DoodleData.createNew();
      final result = await notesService.addDoodleToCurrentNote(doodleData.toJsonString());
      
      expect(result, isNull);
    });
  });
}