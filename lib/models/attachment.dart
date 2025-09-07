import 'dart:convert';
import 'dart:ui';

/// Enum representing the type of attachment
enum AttachmentType {
  image,
  file,
  doodle,
  audio,
}

/// Extension for AttachmentType to provide string conversion
extension AttachmentTypeExtension on AttachmentType {
  String get value {
    switch (this) {
      case AttachmentType.image:
        return 'image';
      case AttachmentType.file:
        return 'file';
      case AttachmentType.doodle:
        return 'doodle';
      case AttachmentType.audio:
        return 'audio';
    }
  }

  static AttachmentType fromString(String value) {
    switch (value) {
      case 'image':
        return AttachmentType.image;
      case 'file':
        return AttachmentType.file;
      case 'doodle':
        return AttachmentType.doodle;
      case 'audio':
        return AttachmentType.audio;
      default:
        throw ArgumentError('Unknown AttachmentType: $value');
    }
  }
}

/// Model representing a file attachment in a note
class Attachment {
  final String id;
  final String name;
  final String relativePath;
  final String? mimeType;
  final int? sizeBytes;
  final AttachmentType type;
  final DateTime createdAt;
  
  // Doodle-specific fields
  final String? vectorData; // JSON string containing drawing strokes
  final String? thumbnailPath; // Path to PNG thumbnail for doodles
  final Map<String, dynamic>? metadata; // Additional metadata (canvas size, etc.)
  
  // Audio-specific fields
  final int? durationSeconds; // Duration for audio files

  const Attachment({
    required this.id,
    required this.name,
    required this.relativePath,
    this.mimeType,
    this.sizeBytes,
    required this.type,
    required this.createdAt,
    this.vectorData,
    this.thumbnailPath,
    this.metadata,
    this.durationSeconds,
  });

  /// Create a copy of the attachment with updated fields
  Attachment copyWith({
    String? id,
    String? name,
    String? relativePath,
    String? mimeType,
    int? sizeBytes,
    AttachmentType? type,
    DateTime? createdAt,
    String? vectorData,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
    int? durationSeconds,
  }) {
    return Attachment(
      id: id ?? this.id,
      name: name ?? this.name,
      relativePath: relativePath ?? this.relativePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      vectorData: vectorData ?? this.vectorData,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  /// Convert attachment to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relativePath': relativePath,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'type': type.value,
      'createdAt': createdAt.toIso8601String(),
      'vectorData': vectorData,
      'thumbnailPath': thumbnailPath,
      'metadata': metadata,
      'durationSeconds': durationSeconds,
    };
  }

  /// Create attachment from JSON
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      type: AttachmentTypeExtension.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      vectorData: json['vectorData'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  /// Convert attachment to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create attachment from JSON string
  factory Attachment.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Attachment.fromJson(json);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attachment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Attachment{id: $id, name: $name, relativePath: $relativePath, '
           'mimeType: $mimeType, sizeBytes: $sizeBytes, type: $type, '
           'createdAt: $createdAt, hasVectorData: ${vectorData != null}, '
           'hasThumbnail: ${thumbnailPath != null}, durationSeconds: $durationSeconds}';
  }

  /// Get a human-readable file size string
  String get fileSizeFormatted {
    if (sizeBytes == null) return 'Unknown size';
    
    final bytes = sizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if this is an image attachment
  bool get isImage => type == AttachmentType.image;

  /// Check if this is a file attachment
  bool get isFile => type == AttachmentType.file;

  /// Check if this is a doodle attachment
  bool get isDoodle => type == AttachmentType.doodle;

  /// Check if this is an audio attachment
  bool get isAudio => type == AttachmentType.audio;

  /// Get file extension from name
  String? get fileExtension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) return null;
    return name.substring(lastDot + 1).toLowerCase();
  }

  /// Check if doodle has vector data
  bool get hasVectorData => isDoodle && vectorData != null && vectorData!.isNotEmpty;

  /// Check if doodle has thumbnail
  bool get hasThumbnail => isDoodle && thumbnailPath != null && thumbnailPath!.isNotEmpty;

  /// Get canvas dimensions from metadata
  Size? get canvasSize {
    if (!isDoodle || metadata == null) return null;
    final width = metadata!['canvasWidth'] as double?;
    final height = metadata!['canvasHeight'] as double?;
    if (width == null || height == null) return null;
    return Size(width, height);
  }

  /// Get formatted duration for audio files
  String get formattedDuration {
    if (!isAudio || durationSeconds == null) return '';
    final duration = Duration(seconds: durationSeconds!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}