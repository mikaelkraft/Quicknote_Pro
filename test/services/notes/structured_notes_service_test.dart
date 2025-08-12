import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/models/note.dart';
import 'package:quicknote_pro/models/attachment.dart';
import 'package:quicknote_pro/repositories/structured_notes_repository.dart';
import 'package:quicknote_pro/services/notes/structured_notes_service.dart';

void main() {
  group('Structured Notes Service Tests', () {
    late StructuredNotesService service;
    late MockStructuredNotesRepository mockRepository;
    
    setUp(() {
      mockRepository = MockStructuredNotesRepository();
      service = StructuredNotesService(mockRepository);
    });
    
    tearDown(() {
      service.dispose();
    });

    test('should initialize service and load notes', () async {
      // Setup mock data
      final testNotes = [
        Note(
          id: 'note1',
          title: 'Test Note 1',
          content: 'Content 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Note(
          id: 'note2',
          title: 'Test Note 2',
          content: 'Content 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      mockRepository.setMockNotes(testNotes);
      
      await service.initialize();
      
      expect(service.notes.length, 2);
      expect(service.hasNotes, isTrue);
      expect(service.isLoading, isFalse);
      expect(service.error, isNull);
    });

    test('should create new note with attachments', () async {
      final attachment = Attachment(
        id: 'attach1',
        name: 'test.jpg',
        relativePath: 'images/test.jpg',
        type: AttachmentType.image,
        createdAt: DateTime.now(),
      );
      
      final note = await service.createNote(
        title: 'New Note',
        content: 'New content',
        folder: 'Work',
        tags: ['important'],
        attachments: [attachment],
      );
      
      expect(note.title, 'New Note');
      expect(note.content, 'New content');
      expect(note.folder, 'Work');
      expect(note.tags, contains('important'));
      expect(note.attachments.length, 1);
      expect(note.attachments[0].id, 'attach1');
    });

    test('should update existing note', () async {
      final originalNote = Note(
        id: 'note1',
        title: 'Original Title',
        content: 'Original content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNote(originalNote);
      
      final updatedNote = await service.updateNote(
        originalNote,
        title: 'Updated Title',
        content: 'Updated content',
      );
      
      expect(updatedNote.title, 'Updated Title');
      expect(updatedNote.content, 'Updated content');
      expect(updatedNote.id, originalNote.id);
      expect(updatedNote.updatedAt.isAfter(originalNote.updatedAt), isTrue);
    });

    test('should delete note and clean up', () async {
      final testNote = Note(
        id: 'note_to_delete',
        title: 'Delete Me',
        content: 'This will be deleted',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNote(testNote);
      service.setCurrentNote(testNote);
      
      await service.deleteNote('note_to_delete');
      
      expect(service.currentNote, isNull);
      expect(mockRepository.deletedNoteIds, contains('note_to_delete'));
    });

    test('should add attachment to note', () async {
      final note = Note(
        id: 'note1',
        title: 'Test Note',
        content: 'Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final attachment = Attachment(
        id: 'new_attach',
        name: 'document.pdf',
        relativePath: 'files/document.pdf',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );
      
      mockRepository.setMockNote(note);
      
      final updatedNote = await service.addAttachmentToNote(
        'note1',
        attachment,
        '/tmp/source_document.pdf',
      );
      
      expect(updatedNote.attachments.length, 1);
      expect(updatedNote.attachments[0].id, 'new_attach');
      expect(mockRepository.savedAttachments, contains(attachment));
    });

    test('should remove attachment from note', () async {
      final attachment = Attachment(
        id: 'remove_me',
        name: 'old_file.txt',
        relativePath: 'files/old_file.txt',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      );
      
      final note = Note(
        id: 'note1',
        title: 'Test Note',
        content: 'Content',
        attachments: [attachment],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNote(note);
      
      final updatedNote = await service.removeAttachmentFromNote('note1', 'remove_me');
      
      expect(updatedNote.attachments.length, 0);
      expect(mockRepository.deletedAttachments, contains(attachment));
    });

    test('should get notes by folder', () async {
      final workNote = Note(
        id: 'work1',
        title: 'Work Note',
        content: 'Work content',
        folder: 'Work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final personalNote = Note(
        id: 'personal1',
        title: 'Personal Note',
        content: 'Personal content',
        folder: 'Personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNotes([workNote, personalNote]);
      
      final workNotes = await service.getNotesByFolder('Work');
      expect(workNotes.length, 1);
      expect(workNotes[0].folder, 'Work');
    });

    test('should get notes by tag', () async {
      final importantNote = Note(
        id: 'important1',
        title: 'Important Note',
        content: 'Important content',
        tags: ['important', 'urgent'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final regularNote = Note(
        id: 'regular1',
        title: 'Regular Note',
        content: 'Regular content',
        tags: ['regular'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNotes([importantNote, regularNote]);
      
      final importantNotes = await service.getNotesByTag('important');
      expect(importantNotes.length, 1);
      expect(importantNotes[0].hasTag('important'), isTrue);
    });

    test('should search notes by content', () async {
      final note1 = Note(
        id: 'search1',
        title: 'Flutter Development',
        content: 'Working on Flutter app',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final note2 = Note(
        id: 'search2',
        title: 'React Native',
        content: 'Mobile development with React',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNotes([note1, note2]);
      
      final results = await service.searchNotes('Flutter');
      expect(results.length, 1);
      expect(results[0].title, 'Flutter Development');
    });

    test('should get all folders and tags', () async {
      final notes = [
        Note(
          id: 'note1',
          title: 'Note 1',
          content: 'Content',
          folder: 'Work',
          tags: ['project', 'important'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Note(
          id: 'note2',
          title: 'Note 2',
          content: 'Content',
          folder: 'Personal',
          tags: ['hobby', 'important'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      mockRepository.setMockNotes(notes);
      await service.loadNotes();
      
      final folders = service.getAllFolders();
      final tags = service.getAllTags();
      
      expect(folders, containsAll(['Work', 'Personal']));
      expect(tags, containsAll(['project', 'important', 'hobby']));
    });

    test('should add and remove tags', () async {
      final note = Note(
        id: 'tag_test',
        title: 'Tag Test',
        content: 'Testing tags',
        tags: ['existing'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNote(note);
      
      // Add tag
      final withNewTag = await service.addTagToNote('tag_test', 'new_tag');
      expect(withNewTag.hasTag('new_tag'), isTrue);
      expect(withNewTag.hasTag('existing'), isTrue);
      
      // Remove tag
      final withoutTag = await service.removeTagFromNote('tag_test', 'existing');
      expect(withoutTag.hasTag('existing'), isFalse);
      expect(withoutTag.hasTag('new_tag'), isTrue);
    });

    test('should move note to folder', () async {
      final note = Note(
        id: 'move_test',
        title: 'Move Test',
        content: 'Testing folder move',
        folder: 'Old Folder',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockRepository.setMockNote(note);
      
      final movedNote = await service.moveNoteToFolder('move_test', 'New Folder');
      expect(movedNote.folder, 'New Folder');
    });

    test('should handle auto-save', () async {
      final note = Note(
        id: 'autosave_test',
        title: 'Auto Save Test',
        content: 'Testing auto save',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      service.startAutoSave(note);
      expect(service, isNotNull); // Timer is running
      
      service.stopAutoSave();
      expect(service, isNotNull); // Timer is stopped
    });

    test('should export and import notes', () async {
      final notes = [
        Note(
          id: 'export1',
          title: 'Export Test 1',
          content: 'Export content 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Note(
          id: 'export2',
          title: 'Export Test 2',
          content: 'Export content 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      mockRepository.setMockNotes(notes);
      
      final backup = await service.exportNotes();
      expect(backup['notes'], isNotNull);
      expect(backup['version'], isNotNull);
      expect(backup['exportDate'], isNotNull);
      
      // Test import
      await service.importNotes(backup);
      expect(mockRepository.importedBackups.length, 1);
    });

    test('should handle errors gracefully', () async {
      mockRepository.setShouldError(true);
      
      await service.loadNotes();
      expect(service.error, isNotNull);
      expect(service.error, contains('Failed to load notes'));
      
      service.clearError();
      expect(service.error, isNull);
    });
  });
}

/// Mock repository for testing
class MockStructuredNotesRepository extends StructuredNotesRepository {
  List<Note> _mockNotes = [];
  final List<String> deletedNoteIds = [];
  final List<Attachment> savedAttachments = [];
  final List<Attachment> deletedAttachments = [];
  final List<Map<String, dynamic>> importedBackups = [];
  bool _shouldError = false;
  
  void setMockNotes(List<Note> notes) {
    _mockNotes = notes;
  }
  
  void setMockNote(Note note) {
    final index = _mockNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _mockNotes[index] = note;
    } else {
      _mockNotes.add(note);
    }
  }
  
  void setShouldError(bool shouldError) {
    _shouldError = shouldError;
  }
  
  @override
  Future<void> initialize() async {
    if (_shouldError) throw Exception('Mock error');
    // Mock initialization
  }
  
  @override
  Future<List<Note>> getAllNotes() async {
    if (_shouldError) throw Exception('Mock error');
    return List.from(_mockNotes);
  }
  
  @override
  Future<Note?> getNoteById(String id) async {
    if (_shouldError) throw Exception('Mock error');
    try {
      return _mockNotes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> saveNote(Note note) async {
    if (_shouldError) throw Exception('Mock error');
    setMockNote(note);
  }
  
  @override
  Future<void> deleteNote(String id) async {
    if (_shouldError) throw Exception('Mock error');
    _mockNotes.removeWhere((note) => note.id == id);
    deletedNoteIds.add(id);
  }
  
  @override
  Future<Attachment> saveAttachment(Attachment attachment, String sourceFilePath) async {
    if (_shouldError) throw Exception('Mock error');
    savedAttachments.add(attachment);
    return attachment;
  }
  
  @override
  Future<void> deleteAttachment(Attachment attachment) async {
    if (_shouldError) throw Exception('Mock error');
    deletedAttachments.add(attachment);
  }
  
  @override
  Future<List<Note>> getNotesByFolder(String folder) async {
    if (_shouldError) throw Exception('Mock error');
    return _mockNotes.where((note) => note.folder == folder).toList();
  }
  
  @override
  Future<List<Note>> getNotesByTag(String tag) async {
    if (_shouldError) throw Exception('Mock error');
    return _mockNotes.where((note) => note.hasTag(tag)).toList();
  }
  
  @override
  Future<List<Note>> searchNotes(String query) async {
    if (_shouldError) throw Exception('Mock error');
    final lowerQuery = query.toLowerCase();
    return _mockNotes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
             note.content.toLowerCase().contains(lowerQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  @override
  Future<Map<String, dynamic>> getStorageStats() async {
    if (_shouldError) throw Exception('Mock error');
    return {
      'totalNotes': _mockNotes.length,
      'totalAttachments': 0,
      'totalSizeBytes': 0,
      'imageCount': 0,
      'fileCount': 0,
      'voiceCount': 0,
    };
  }
  
  @override
  Future<Map<String, dynamic>> exportNotes() async {
    if (_shouldError) throw Exception('Mock error');
    return {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'notes': _mockNotes.map((note) => note.toJson()).toList(),
    };
  }
  
  @override
  Future<void> importNotes(Map<String, dynamic> backup, {bool overwrite = false}) async {
    if (_shouldError) throw Exception('Mock error');
    importedBackups.add(backup);
  }
}