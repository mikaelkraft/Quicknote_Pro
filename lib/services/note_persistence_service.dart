import 'dart:async';
import '../models/note.dart';
import '../models/attachment.dart';
import '../repositories/notes_repository.dart';
import '../models/note_model.dart' as legacy;

/// Service for persisting notes with the new Note model while bridging to existing repository
class NotePersistenceService {
  final NotesRepository _repository;
  
  NotePersistenceService(this._repository);

  /// Initialize the service
  Future<void> initialize() async {
    await _repository.initialize();
  }

  /// Save or update a note
  Future<void> upsertNote(Note note) async {
    // Convert new Note model to legacy model for repository
    final legacyNote = _convertToLegacyNote(note);
    await _repository.saveNote(legacyNote);
  }

  /// Update an existing note
  Future<void> updateNote(Note note) async {
    await upsertNote(note);
  }

  /// Get a note by ID
  Future<Note?> getNoteById(String id) async {
    final legacyNote = await _repository.getNoteById(id);
    return legacyNote != null ? _convertFromLegacyNote(legacyNote) : null;
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    final legacyNotes = await _repository.getAllNotes();
    return legacyNotes.map(_convertFromLegacyNote).toList();
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
  }

  /// Search notes
  Future<List<Note>> searchNotes(String query) async {
    final legacyNotes = await _repository.searchNotes(query);
    return legacyNotes.map(_convertFromLegacyNote).toList();
  }

  /// Convert new Note model to legacy Note model
  legacy.Note _convertToLegacyNote(Note note) {
    // Extract attachment paths by type
    final imagePaths = note.attachments
        .where((attachment) => attachment.isImage)
        .map((attachment) => attachment.relativePath)
        .toList();
    
    final attachmentPaths = note.attachments
        .where((attachment) => attachment.isFile)
        .map((attachment) => attachment.relativePath)
        .toList();

    final voiceNotePaths = note.attachments
        .where((attachment) => attachment.isAudio)
        .map((attachment) => attachment.relativePath)
        .toList();

    return legacy.Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      folder: 'General', // Default folder for now
      tags: [], // Tags not implemented in new model yet
      imagePaths: imagePaths,
      attachmentPaths: attachmentPaths,
      voiceNotePaths: voiceNotePaths,
    );
  }

  /// Convert legacy Note model to new Note model
  Note _convertFromLegacyNote(legacy.Note legacyNote) {
    final attachments = <Attachment>[];
    
    // Convert image paths to image attachments
    for (int i = 0; i < legacyNote.imagePaths.length; i++) {
      final path = legacyNote.imagePaths[i];
      final fileName = path.split('/').last;
      attachments.add(Attachment(
        id: '${legacyNote.id}_img_$i',
        name: fileName,
        relativePath: path,
        mimeType: _getMimeTypeFromPath(path),
        type: AttachmentType.image,
        createdAt: legacyNote.createdAt,
      ));
    }

    // Convert attachment paths to file attachments
    for (int i = 0; i < legacyNote.attachmentPaths.length; i++) {
      final path = legacyNote.attachmentPaths[i];
      final fileName = path.split('/').last;
      attachments.add(Attachment(
        id: '${legacyNote.id}_file_$i',
        name: fileName,
        relativePath: path,
        mimeType: _getMimeTypeFromPath(path),
        type: AttachmentType.file,
        createdAt: legacyNote.createdAt,
      ));
    }

    // Convert voice note paths to audio attachments
    for (int i = 0; i < legacyNote.voiceNotePaths.length; i++) {
      final path = legacyNote.voiceNotePaths[i];
      final fileName = path.split('/').last;
      attachments.add(Attachment(
        id: '${legacyNote.id}_audio_$i',
        name: fileName,
        relativePath: path,
        mimeType: _getMimeTypeFromPath(path),
        type: AttachmentType.audio,
        createdAt: legacyNote.createdAt,
        // Try to extract duration from file metadata if available
        // For now, we'll leave it null and the player will determine it
      ));
    }

    return Note(
      id: legacyNote.id,
      title: legacyNote.title,
      content: legacyNote.content,
      attachments: attachments,
      createdAt: legacyNote.createdAt,
      updatedAt: legacyNote.updatedAt,
    );
  }

  /// Get MIME type from file path
  String? _getMimeTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'm4a':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mpeg';
      case 'aac':
        return 'audio/aac';
      default:
        return null;
    }
  }

  /// Add an audio attachment to a note
  Future<Note> addAudioAttachment(
    Note note, 
    String audioPath, 
    int durationSeconds, {
    int? fileSizeBytes,
  }) async {
    final fileName = audioPath.split('/').last;
    final audioAttachment = Attachment(
      id: 'audio_${DateTime.now().millisecondsSinceEpoch}',
      name: fileName,
      relativePath: audioPath,
      mimeType: _getMimeTypeFromPath(audioPath),
      sizeBytes: fileSizeBytes,
      type: AttachmentType.audio,
      createdAt: DateTime.now(),
      durationSeconds: durationSeconds,
    );

    final updatedNote = note.addAttachment(audioAttachment);
    await upsertNote(updatedNote);
    return updatedNote;
  }

  /// Remove an attachment from a note
  Future<Note> removeAttachment(Note note, String attachmentId) async {
    final updatedNote = note.removeAttachment(attachmentId);
    await upsertNote(updatedNote);
    return updatedNote;
  }
}