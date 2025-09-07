import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note_model.dart';
import 'package:quicknote_pro/models/doodle_data.dart';
import 'package:quicknote_pro/services/notes/notes_service.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';

class MockNotesRepository extends NotesRepository {
  final Map<String, Note> _notes = {};
  final Map<String, String> _doodles = {};

  @override
  Future<void> initialize() async {
    // Mock initialization
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
  group('Doodle Integration Tests', () {
    late NotesService notesService;
    late MockNotesRepository mockRepository;

    setUp(() {
      mockRepository = MockNotesRepository();
      notesService = NotesService(mockRepository);
    });

    test('should complete full doodle workflow: create, save, load, edit, delete', () async {
      await notesService.initialize();
      
      // 1. Create a note
      final note = await notesService.createNote(
        title: 'Doodle Test Note',
        content: 'Testing doodle functionality',
      );
      
      // Set as current note
      notesService.setCurrentNote(note);
      
      // 2. Create and save a doodle
      final doodleData = DoodleData.createNew();
      
      // Add some strokes to make it non-empty
      final stroke1 = DoodleStroke(
        points: [const Offset(10, 10), const Offset(20, 20), const Offset(30, 15)],
        color: const Color(0xFF000000),
        width: 2.0,
        createdAt: DateTime.now(),
      );
      
      final stroke2 = DoodleStroke(
        points: [const Offset(50, 10), const Offset(60, 30)],
        color: const Color(0xFFFF0000),
        width: 4.0,
        toolType: 'highlighter',
        createdAt: DateTime.now(),
      );
      
      final layerWithStrokes = doodleData.primaryLayer.copyWith(
        strokes: [stroke1, stroke2],
      );
      
      final doodleWithStrokes = doodleData.copyWith(
        layers: [layerWithStrokes],
        updatedAt: DateTime.now(),
      );
      
      final doodlePath = await notesService.addDoodleToCurrentNote(
        doodleWithStrokes.toJsonString(),
      );
      
      // Verify doodle was saved
      expect(doodlePath, isNotNull);
      expect(doodlePath, contains('doodle'));
      expect(doodlePath, contains('.json'));
      
      // 3. Verify note was updated with doodle path
      final updatedNote = notesService.currentNote!;
      expect(updatedNote.doodlePaths, contains(doodlePath));
      expect(updatedNote.hasDoodles, isTrue);
      
      // 4. Load the doodle data back
      final loadedJsonData = await notesService.loadDoodleData(doodlePath!);
      expect(loadedJsonData, isNotNull);
      
      final loadedDoodle = DoodleData.fromJsonString(loadedJsonData!);
      expect(loadedDoodle.isEmpty, isFalse);
      expect(loadedDoodle.strokeCount, equals(2));
      expect(loadedDoodle.allStrokes.length, equals(2));
      
      // Verify stroke data integrity
      final loadedStrokes = loadedDoodle.allStrokes;
      expect(loadedStrokes[0].points.length, equals(3));
      expect(loadedStrokes[0].color.value, equals(0xFF000000));
      expect(loadedStrokes[0].width, equals(2.0));
      expect(loadedStrokes[0].toolType, equals('pen'));
      
      expect(loadedStrokes[1].points.length, equals(2));
      expect(loadedStrokes[1].color.value, equals(0xFFFF0000));
      expect(loadedStrokes[1].width, equals(4.0));
      expect(loadedStrokes[1].toolType, equals('highlighter'));
      
      // 5. Edit the doodle (add another stroke)
      final newStroke = DoodleStroke(
        points: [const Offset(100, 100), const Offset(150, 150)],
        color: const Color(0xFF00FF00),
        width: 6.0,
        toolType: 'brush',
        createdAt: DateTime.now(),
      );
      
      final editedLayer = loadedDoodle.primaryLayer.copyWith(
        strokes: [...loadedDoodle.primaryLayer.strokes, newStroke],
      );
      
      final editedDoodle = loadedDoodle.copyWith(
        layers: [editedLayer],
        updatedAt: DateTime.now(),
      );
      
      await notesService.updateDoodleInCurrentNote(
        doodlePath,
        editedDoodle.toJsonString(),
      );
      
      // 6. Verify the edit
      final editedJsonData = await notesService.loadDoodleData(doodlePath);
      final editedLoadedDoodle = DoodleData.fromJsonString(editedJsonData!);
      
      expect(editedLoadedDoodle.strokeCount, equals(3));
      expect(editedLoadedDoodle.allStrokes.last.color.value, equals(0xFF00FF00));
      expect(editedLoadedDoodle.allStrokes.last.toolType, equals('brush'));
      
      // 7. Test doodle removal
      await notesService.removeMediaFromCurrentNote(doodlePath, 'doodle');
      
      // Verify doodle was removed from note
      expect(notesService.currentNote!.doodlePaths, isNot(contains(doodlePath)));
      expect(notesService.currentNote!.hasDoodles, isFalse);
      
      // Verify doodle file was deleted
      final deletedData = await notesService.loadDoodleData(doodlePath);
      expect(deletedData, isNull);
    });

    test('should handle multiple doodles in single note', () async {
      await notesService.initialize();
      
      // Create a note
      final note = await notesService.createNote(title: 'Multi-Doodle Note');
      notesService.setCurrentNote(note);
      
      // Create and save multiple doodles
      final doodle1 = DoodleData.createNew();
      final doodle2 = DoodleData.createNew();
      final doodle3 = DoodleData.createNew();
      
      final path1 = await notesService.addDoodleToCurrentNote(doodle1.toJsonString());
      final path2 = await notesService.addDoodleToCurrentNote(doodle2.toJsonString());
      final path3 = await notesService.addDoodleToCurrentNote(doodle3.toJsonString());
      
      // Verify all doodles are tracked
      final finalNote = notesService.currentNote!;
      expect(finalNote.doodlePaths.length, equals(3));
      expect(finalNote.doodlePaths, containsAll([path1, path2, path3]));
      
      // Verify each doodle can be loaded independently
      final loaded1 = await notesService.loadDoodleData(path1!);
      final loaded2 = await notesService.loadDoodleData(path2!);
      final loaded3 = await notesService.loadDoodleData(path3!);
      
      expect(loaded1, isNotNull);
      expect(loaded2, isNotNull);
      expect(loaded3, isNotNull);
      
      // Remove middle doodle
      await notesService.removeMediaFromCurrentNote(path2, 'doodle');
      
      // Verify only the specific doodle was removed
      expect(notesService.currentNote!.doodlePaths.length, equals(2));
      expect(notesService.currentNote!.doodlePaths, contains(path1));
      expect(notesService.currentNote!.doodlePaths, isNot(contains(path2)));
      expect(notesService.currentNote!.doodlePaths, contains(path3));
    });

    test('should handle error cases gracefully', () async {
      await notesService.initialize();
      
      // Try to add doodle without current note
      final result = await notesService.addDoodleToCurrentNote('{"test": "data"}');
      expect(result, isNull);
      
      // Try to load non-existent doodle
      final loadResult = await notesService.loadDoodleData('non-existent-path');
      expect(loadResult, isNull);
    });
  });
}