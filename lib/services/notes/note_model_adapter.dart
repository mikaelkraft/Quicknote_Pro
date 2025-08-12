import '../../models/note.dart' as NewNote;
import '../../models/attachment.dart';
import '../../models/note_model.dart' as OldNote;

/// Service for converting between old and new note model formats
class NoteModelAdapter {
  /// Convert old note model to new structured note model
  static NewNote.Note fromOldNote(OldNote.Note oldNote) {
    final attachments = <Attachment>[];
    
    // Convert image paths to image attachments
    for (int i = 0; i < oldNote.imagePaths.length; i++) {
      final imagePath = oldNote.imagePaths[i];
      attachments.add(Attachment(
        id: 'img_${oldNote.id}_$i',
        name: _extractFileName(imagePath),
        relativePath: imagePath,
        mimeType: _getMimeTypeFromPath(imagePath),
        type: AttachmentType.image,
        createdAt: oldNote.createdAt,
      ));
    }
    
    // Convert attachment paths to file attachments
    for (int i = 0; i < oldNote.attachmentPaths.length; i++) {
      final attachmentPath = oldNote.attachmentPaths[i];
      attachments.add(Attachment(
        id: 'file_${oldNote.id}_$i',
        name: _extractFileName(attachmentPath),
        relativePath: attachmentPath,
        mimeType: _getMimeTypeFromPath(attachmentPath),
        type: AttachmentType.file,
        createdAt: oldNote.createdAt,
      ));
    }
    
    // Convert voice note paths to voice attachments
    for (int i = 0; i < oldNote.voiceNotePaths.length; i++) {
      final voicePath = oldNote.voiceNotePaths[i];
      attachments.add(Attachment(
        id: 'voice_${oldNote.id}_$i',
        name: _extractFileName(voicePath),
        relativePath: voicePath,
        mimeType: 'audio/mp4', // Default voice note format
        type: AttachmentType.voice,
        createdAt: oldNote.createdAt,
      ));
    }
    
    return NewNote.Note(
      id: oldNote.id,
      title: oldNote.title,
      content: oldNote.content,
      attachments: attachments,
      createdAt: oldNote.createdAt,
      updatedAt: oldNote.updatedAt,
      folder: oldNote.folder,
      tags: List.from(oldNote.tags),
    );
  }
  
  /// Convert new structured note model to old note model
  static OldNote.Note toOldNote(NewNote.Note newNote) {
    final imagePaths = <String>[];
    final attachmentPaths = <String>[];
    final voiceNotePaths = <String>[];
    
    for (final attachment in newNote.attachments) {
      switch (attachment.type) {
        case AttachmentType.image:
          imagePaths.add(attachment.relativePath);
          break;
        case AttachmentType.file:
          attachmentPaths.add(attachment.relativePath);
          break;
        case AttachmentType.voice:
          voiceNotePaths.add(attachment.relativePath);
          break;
      }
    }
    
    return OldNote.Note(
      id: newNote.id,
      title: newNote.title,
      content: newNote.content,
      createdAt: newNote.createdAt,
      updatedAt: newNote.updatedAt,
      folder: newNote.folder,
      tags: List.from(newNote.tags),
      imagePaths: imagePaths,
      attachmentPaths: attachmentPaths,
      voiceNotePaths: voiceNotePaths,
    );
  }
  
  /// Extract filename from path
  static String _extractFileName(String path) {
    final segments = path.split('/');
    return segments.isNotEmpty ? segments.last : path;
  }
  
  /// Get MIME type from file path
  static String? _getMimeTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      default:
        return null;
    }
  }
  
  /// Create a new note with both model compatibility
  static Map<String, dynamic> createCompatibleNote({
    required String id,
    required String title,
    required String content,
    String folder = 'General',
    List<String> tags = const [],
    List<Attachment> attachments = const [],
  }) {
    final newNote = NewNote.Note(
      id: id,
      title: title,
      content: content,
      folder: folder,
      tags: tags,
      attachments: attachments,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final oldNote = toOldNote(newNote);
    
    return {
      'newModel': newNote,
      'oldModel': oldNote,
      'json': newNote.toJson(),
    };
  }
}