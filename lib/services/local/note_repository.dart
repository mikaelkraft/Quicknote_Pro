import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/note.dart';
import 'hive_initializer.dart';

class NoteRepository {
  static final NoteRepository _instance = NoteRepository._internal();
  factory NoteRepository() => _instance;
  NoteRepository._internal();

  Box<Note> get _box => HiveInitializer.notesBox;

  // Stream controller for notes changes
  final _notesController = StreamController<List<Note>>.broadcast();

  /// Stream of all non-deleted notes
  Stream<List<Note>> get notesStream => _notesController.stream;

  /// Initialize the repository and emit initial data
  void init() {
    _emitNotes();
    
    // Listen to box changes and emit updates
    _box.watch().listen((_) {
      _emitNotes();
    });
  }

  /// Emit current notes to stream
  void _emitNotes() {
    final notes = getAllNotes();
    _notesController.add(notes);
  }

  /// Get all non-deleted notes sorted by updatedAt descending
  List<Note> getAllNotes() {
    return _box.values
        .where((note) => note.deletedAt == null)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Get note by ID
  Note? getNoteById(String id) {
    return _box.values.firstWhere(
      (note) => note.id == id && note.deletedAt == null,
      orElse: () => null,
    );
  }

  /// Create a new note
  Future<Note> createNote({
    String? title,
    String? content,
    String? folderId,
    String? noteType,
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _generateId(),
      title: title ?? '',
      content: content ?? '',
      createdAt: now,
      updatedAt: now,
      folderId: folderId,
      noteType: noteType ?? 'text',
      tags: tags ?? [],
    );

    await _box.put(note.id, note);
    return note;
  }

  /// Update an existing note
  Future<Note> updateNote(Note note) async {
    note.touch(); // Update the updatedAt timestamp
    await _box.put(note.id, note);
    return note;
  }

  /// Upsert a note (update if exists, create if doesn't)
  Future<Note> upsertNote(Note note) async {
    note.touch();
    await _box.put(note.id, note);
    return note;
  }

  /// Soft delete a note (set deletedAt)
  Future<void> deleteNote(String id) async {
    final note = getNoteById(id);
    if (note != null) {
      note.deletedAt = DateTime.now();
      await _box.put(id, note);
    }
  }

  /// Permanently delete a note
  Future<void> permanentlyDeleteNote(String id) async {
    await _box.delete(id);
  }

  /// Restore a deleted note
  Future<void> restoreNote(String id) async {
    final note = _box.get(id);
    if (note != null) {
      note.deletedAt = null;
      await _box.put(id, note);
    }
  }

  /// Pin or unpin a note
  Future<void> togglePinNote(String id) async {
    final note = getNoteById(id);
    if (note != null) {
      note.isPinned = !note.isPinned;
      await updateNote(note);
    }
  }

  /// Duplicate a note
  Future<Note> duplicateNote(String id) async {
    final originalNote = getNoteById(id);
    if (originalNote == null) {
      throw Exception('Note not found');
    }

    final now = DateTime.now();
    final duplicatedNote = Note(
      id: _generateId(),
      title: '${originalNote.title} (Copy)',
      content: originalNote.content,
      images: List.from(originalNote.images),
      attachments: List.from(originalNote.attachments),
      createdAt: now,
      updatedAt: now,
      folderId: originalNote.folderId,
      isPinned: false, // Don't pin duplicates by default
      tags: List.from(originalNote.tags),
      noteType: originalNote.noteType,
      hasReminder: false, // Don't copy reminders
      metadata: originalNote.metadata != null 
        ? Map<String, dynamic>.from(originalNote.metadata!)
        : null,
    );

    await _box.put(duplicatedNote.id, duplicatedNote);
    return duplicatedNote;
  }

  /// Search notes by title or content
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();

    final lowercaseQuery = query.toLowerCase();
    return getAllNotes().where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
             note.content.toLowerCase().contains(lowercaseQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Filter notes by folder
  List<Note> getNotesByFolder(String? folderId) {
    return getAllNotes().where((note) => note.folderId == folderId).toList();
  }

  /// Filter notes by type
  List<Note> getNotesByType(String noteType) {
    return getAllNotes().where((note) => note.noteType == noteType).toList();
  }

  /// Get pinned notes
  List<Note> getPinnedNotes() {
    return getAllNotes().where((note) => note.isPinned).toList();
  }

  /// Get notes with reminders
  List<Note> getNotesWithReminders() {
    return getAllNotes().where((note) => note.hasReminder).toList();
  }

  /// Get notes by tag
  List<Note> getNotesByTag(String tag) {
    return getAllNotes().where((note) => note.tags.contains(tag)).toList();
  }

  /// Get all unique tags
  List<String> getAllTags() {
    final allTags = <String>{};
    for (final note in getAllNotes()) {
      allTags.addAll(note.tags);
    }
    return allTags.toList()..sort();
  }

  /// Get all unique folders
  List<String> getAllFolders() {
    final allFolders = <String>{};
    for (final note in getAllNotes()) {
      if (note.folderId != null) {
        allFolders.add(note.folderId!);
      }
    }
    return allFolders.toList()..sort();
  }

  /// Get deleted notes (for trash/recycle bin)
  List<Note> getDeletedNotes() {
    return _box.values
        .where((note) => note.deletedAt != null)
        .toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  }

  /// Get notes count
  int getNotesCount() {
    return getAllNotes().length;
  }

  /// Get notes count by folder
  Map<String?, int> getNotesCountByFolder() {
    final counts = <String?, int>{};
    for (final note in getAllNotes()) {
      counts[note.folderId] = (counts[note.folderId] ?? 0) + 1;
    }
    return counts;
  }

  /// Clear all notes (for testing)
  Future<void> clearAllNotes() async {
    await _box.clear();
  }

  /// Generate a unique ID for notes
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Dispose the repository
  void dispose() {
    _notesController.close();
  }

  /// Backup all notes to a map (for cloud sync)
  Map<String, dynamic> exportAllNotes() {
    final notes = _box.values.map((note) => note.toMap()).toList();
    return {
      'notes': notes,
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Import notes from a map (for cloud sync)
  Future<void> importNotes(Map<String, dynamic> data, {bool replaceExisting = false}) async {
    if (replaceExisting) {
      await _box.clear();
    }

    final notesList = data['notes'] as List<dynamic>?;
    if (notesList != null) {
      for (final noteMap in notesList) {
        final note = Note.fromMap(noteMap as Map<String, dynamic>);
        await _box.put(note.id, note);
      }
    }
  }
}