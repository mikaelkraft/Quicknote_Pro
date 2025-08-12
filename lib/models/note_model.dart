import 'dart:convert';

/// Model representing a note with text content and media attachments
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String folder;
  final List<String> tags;
  final List<String> imagePaths;
  final List<String> attachmentPaths;
  final List<String> voiceNotePaths;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.folder = 'General',
    this.tags = const [],
    this.imagePaths = const [],
    this.attachmentPaths = const [],
    this.voiceNotePaths = const [],
  });

  /// Create a copy of the note with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folder,
    List<String>? tags,
    List<String>? imagePaths,
    List<String>? attachmentPaths,
    List<String>? voiceNotePaths,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folder: folder ?? this.folder,
      tags: tags ?? List.from(this.tags),
      imagePaths: imagePaths ?? List.from(this.imagePaths),
      attachmentPaths: attachmentPaths ?? List.from(this.attachmentPaths),
      voiceNotePaths: voiceNotePaths ?? List.from(this.voiceNotePaths),
    );
  }

  /// Convert note to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'folder': folder,
      'tags': tags,
      'imagePaths': imagePaths,
      'attachmentPaths': attachmentPaths,
      'voiceNotePaths': voiceNotePaths,
    };
  }

  /// Create note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      folder: json['folder'] as String? ?? 'General',
      tags: List<String>.from(json['tags'] as List? ?? []),
      imagePaths: List<String>.from(json['imagePaths'] as List? ?? []),
      attachmentPaths: List<String>.from(json['attachmentPaths'] as List? ?? []),
      voiceNotePaths: List<String>.from(json['voiceNotePaths'] as List? ?? []),
    );
  }

  /// Convert note to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create note from JSON string
  factory Note.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Note.fromJson(json);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Note{id: $id, title: $title, content: ${content.length} chars, '
           'createdAt: $createdAt, updatedAt: $updatedAt, '
           'folder: $folder, tags: $tags, '
           'images: ${imagePaths.length}, attachments: ${attachmentPaths.length}, '
           'voiceNotes: ${voiceNotePaths.length}}';
  }

  /// Check if note has any content
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  /// Check if note has unsaved changes compared to another note
  bool hasChangesFrom(Note other) {
    return title != other.title ||
           content != other.content ||
           folder != other.folder ||
           !_listEquals(tags, other.tags) ||
           !_listEquals(imagePaths, other.imagePaths) ||
           !_listEquals(attachmentPaths, other.attachmentPaths) ||
           !_listEquals(voiceNotePaths, other.voiceNotePaths);
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Get display text for preview (truncated content)
  String get previewText {
    if (content.trim().isEmpty) return 'No content';
    final cleanContent = content.trim().replaceAll('\n', ' ');
    return cleanContent.length > 100 
        ? '${cleanContent.substring(0, 100)}...'
        : cleanContent;
  }

  /// Get word count
  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  /// Check if note has any media attachments
  bool get hasAttachments => 
      imagePaths.isNotEmpty || 
      attachmentPaths.isNotEmpty || 
      voiceNotePaths.isNotEmpty;
}