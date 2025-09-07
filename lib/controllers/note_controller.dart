import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/attachment.dart';
import '../services/note_persistence_service.dart';
import '../services/attachment_service.dart';

/// Controller for managing note editing state and operations
class NoteController extends ChangeNotifier {
  final NotePersistenceService _persistenceService;
  final AttachmentService _attachmentService;

  Note? _currentNote;
  bool _isSaving = false;
  String? _error;
  Timer? _autosaveTimer;
  
  // Text editing controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  
  // Stream controller for note updates
  final StreamController<Note?> _noteStreamController = StreamController<Note?>.broadcast();

  NoteController(this._persistenceService, this._attachmentService) {
    _setupTextListeners();
  }

  // Getters
  Note? get currentNote => _currentNote;
  List<Attachment> get attachments => _currentNote?.attachments ?? [];
  bool get isSaving => _isSaving;
  String? get error => _error;
  
  Stream<Note?> get noteStream => _noteStreamController.stream;

  /// Set up text change listeners for autosave
  void _setupTextListeners() {
    titleController.addListener(_onTextChanged);
    contentController.addListener(_onTextChanged);
  }

  /// Handle text changes and trigger debounced autosave
  void _onTextChanged() {
    if (_currentNote != null) {
      _scheduleAutosave();
    }
  }

  /// Schedule autosave with debouncing (500ms)
  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 500), () {
      debouncedAutosave();
    });
  }

  /// Watch a note by ID and stream updates
  void watchNote(String id) async {
    try {
      _setError(null);
      
      final note = await _persistenceService.getNoteById(id);
      if (note != null) {
        _setCurrentNote(note);
        _noteStreamController.add(note);
      } else {
        _setError('Note not found');
      }
    } catch (e) {
      _setError('Failed to load note: $e');
    }
  }

  /// Create a new note
  void createNew({String title = '', String content = ''}) {
    final newNote = Note.create(title: title, content: content);
    _setCurrentNote(newNote);
    _noteStreamController.add(newNote);
  }

  /// Set current note and update controllers
  void _setCurrentNote(Note note) {
    _currentNote = note;
    
    // Update text controllers without triggering listeners
    titleController.removeListener(_onTextChanged);
    contentController.removeListener(_onTextChanged);
    
    titleController.text = note.title;
    contentController.text = note.content;
    
    titleController.addListener(_onTextChanged);
    contentController.addListener(_onTextChanged);
    
    notifyListeners();
  }

  /// Perform debounced autosave
  Future<void> debouncedAutosave() async {
    if (_currentNote == null || _isSaving) return;

    await _saveCurrentState();
  }

  /// Save the current state of the note
  Future<void> _saveCurrentState() async {
    if (_currentNote == null) return;

    _setSaving(true);
    _setError(null);

    try {
      final updatedNote = _currentNote!.copyWith(
        title: titleController.text,
        content: contentController.text,
        updatedAt: DateTime.now(),
      );

      await _persistenceService.upsertNote(updatedNote);
      
      _currentNote = updatedNote;
      _noteStreamController.add(updatedNote);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to save note: $e');
    } finally {
      _setSaving(false);
    }
  }

  /// Add an attachment to the current note
  Future<void> addAttachment(
    File file, {
    AttachmentType? typeHint,
    String? mimeType,
  }) async {
    if (_currentNote == null) {
      throw StateError('No current note to add attachment to');
    }

    _setSaving(true);
    _setError(null);

    try {
      // Store the file and create attachment
      final attachment = await _attachmentService.storeFile(
        file,
        _currentNote!.id,
        typeHint: typeHint,
        mimeType: mimeType,
      );

      // Add attachment to note
      final updatedNote = _currentNote!.addAttachment(attachment);
      
      // Save updated note
      await _persistenceService.upsertNote(updatedNote);
      
      _currentNote = updatedNote;
      _noteStreamController.add(updatedNote);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add attachment: $e');
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  /// Remove an attachment from the current note
  Future<void> removeAttachment(String attachmentId) async {
    if (_currentNote == null) return;

    _setSaving(true);
    _setError(null);

    try {
      // Find the attachment to remove
      final attachmentToRemove = _currentNote!.attachments
          .where((attachment) => attachment.id == attachmentId)
          .firstOrNull;

      if (attachmentToRemove != null) {
        // Delete the attachment file
        await _attachmentService.deleteAttachment(attachmentToRemove);
        
        // Remove attachment from note
        final updatedNote = _currentNote!.removeAttachment(attachmentId);
        
        // Save updated note
        await _persistenceService.upsertNote(updatedNote);
        
        _currentNote = updatedNote;
        _noteStreamController.add(updatedNote);
        
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to remove attachment: $e');
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  /// Add an audio recording to the current note
  Future<void> addAudioRecording(String audioPath, int durationSeconds) async {
    if (_currentNote == null) {
      throw StateError('No current note to add audio to');
    }

    _setSaving(true);
    _setError(null);

    try {
      // Get file size
      final file = File(audioPath);
      final fileSizeBytes = await file.exists() ? await file.length() : null;

      // Use the persistence service to add audio attachment
      final updatedNote = await _persistenceService.addAudioAttachment(
        _currentNote!,
        audioPath,
        durationSeconds,
        fileSizeBytes: fileSizeBytes,
      );
      
      _currentNote = updatedNote;
      _noteStreamController.add(updatedNote);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add audio recording: $e');
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  /// Get all audio attachments for the current note
  List<Attachment> get audioAttachments => 
      _currentNote?.audioAttachments ?? [];

  /// Flush any pending save operations
  Future<void> flushPendingSave() async {
    _autosaveTimer?.cancel();
    await _saveCurrentState();
  }

  /// Force save the current note
  Future<void> saveNote() async {
    await _saveCurrentState();
  }

  /// Delete the current note
  Future<void> deleteCurrentNote() async {
    if (_currentNote == null) return;

    _setSaving(true);
    _setError(null);

    try {
      // Delete all attachments
      for (final attachment in _currentNote!.attachments) {
        await _attachmentService.deleteAttachment(attachment);
      }

      // Delete the note
      await _persistenceService.deleteNote(_currentNote!.id);
      
      _currentNote = null;
      _noteStreamController.add(null);
      
      // Clear text controllers
      titleController.clear();
      contentController.clear();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete note: $e');
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  /// Set saving state
  void _setSaving(bool saving) {
    if (_isSaving != saving) {
      _isSaving = saving;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  /// Get absolute path for an attachment
  Future<String?> getAttachmentPath(Attachment attachment) async {
    return await _attachmentService.getAbsolutePath(attachment);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _noteStreamController.close();
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }
}