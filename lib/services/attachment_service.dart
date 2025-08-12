import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/attachment.dart';

/// Service for managing file attachments
class AttachmentService {
  Directory? _attachmentsDirectory;

  /// Initialize the attachment service
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _attachmentsDirectory = Directory('${appDir.path}/attachments');
    
    if (!await _attachmentsDirectory!.exists()) {
      await _attachmentsDirectory!.create(recursive: true);
    }
  }

  /// Store a file and create an attachment
  Future<Attachment> storeFile(
    File sourceFile, 
    String noteId, {
    AttachmentType? typeHint,
    String? mimeType,
  }) async {
    await initialize();
    
    if (!await sourceFile.exists()) {
      throw ArgumentError('Source file does not exist: ${sourceFile.path}');
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = sourceFile.path.split('/').last;
    final extension = originalName.contains('.') ? originalName.split('.').last : '';
    final uniqueName = '${noteId}_$timestamp${extension.isNotEmpty ? '.$extension' : ''}';
    
    // Determine attachment type
    final attachmentType = typeHint ?? _determineTypeFromExtension(extension);
    
    // Copy file to attachments directory
    final targetPath = '${_attachmentsDirectory!.path}/$uniqueName';
    await sourceFile.copy(targetPath);
    
    // Get file size
    final fileSize = await File(targetPath).length();
    
    // Create attachment
    return Attachment(
      id: 'att_${timestamp}_${DateTime.now().microsecond}',
      name: originalName,
      relativePath: 'attachments/$uniqueName',
      mimeType: mimeType ?? _getMimeType(extension),
      sizeBytes: fileSize,
      type: attachmentType,
      createdAt: DateTime.now(),
    );
  }

  /// Delete an attachment file
  Future<void> deleteAttachment(Attachment attachment) async {
    await initialize();
    
    final filePath = '${_attachmentsDirectory!.path}/${attachment.relativePath.split('/').last}';
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get the absolute path for an attachment
  Future<String?> getAbsolutePath(Attachment attachment) async {
    await initialize();
    
    final filePath = '${_attachmentsDirectory!.path}/${attachment.relativePath.split('/').last}';
    final file = File(filePath);
    
    return await file.exists() ? filePath : null;
  }

  /// Check if an attachment file exists
  Future<bool> attachmentExists(Attachment attachment) async {
    final absolutePath = await getAbsolutePath(attachment);
    return absolutePath != null;
  }

  /// Get all attachment files in the directory
  Future<List<File>> getAllAttachmentFiles() async {
    await initialize();
    
    if (!await _attachmentsDirectory!.exists()) {
      return [];
    }
    
    final entities = await _attachmentsDirectory!.list().toList();
    return entities.whereType<File>().toList();
  }

  /// Clean up orphaned attachment files (files not referenced by any note)
  Future<List<String>> cleanupOrphanedFiles(List<String> referencedPaths) async {
    final allFiles = await getAllAttachmentFiles();
    final deletedPaths = <String>[];
    
    for (final file in allFiles) {
      final relativePath = 'attachments/${file.path.split('/').last}';
      
      if (!referencedPaths.contains(relativePath)) {
        try {
          await file.delete();
          deletedPaths.add(relativePath);
        } catch (e) {
          // Log error but continue cleanup
          debugPrint('Error deleting orphaned file $relativePath: $e');
        }
      }
    }
    
    return deletedPaths;
  }

  /// Determine attachment type from file extension
  AttachmentType _determineTypeFromExtension(String extension) {
    final imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'};
    
    if (imageExtensions.contains(extension.toLowerCase())) {
      return AttachmentType.image;
    }
    
    return AttachmentType.file;
  }

  /// Get MIME type from file extension
  String? _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'zip':
        return 'application/zip';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }
}