import 'dart:convert';
import 'attachment.dart';

/// Model representing a note with text content and structured attachments
class Note {
  final String id;
  final String title;
  final String content;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of the note with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<Attachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? List.from(this.attachments),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert note to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((attachmentJson) => Attachment.fromJson(attachmentJson as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
           'attachments: ${attachments.length}, createdAt: $createdAt, '
           'updatedAt: $updatedAt}';
  }

  /// Check if note has any content
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  /// Check if note has unsaved changes compared to another note
  bool hasChangesFrom(Note other) {
    return title != other.title ||
           content != other.content ||
           !_attachmentListEquals(attachments, other.attachments);
  }

  /// Helper method to compare attachment lists
  bool _attachmentListEquals(List<Attachment> a, List<Attachment> b) {
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

  /// Check if note has any attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Get all image attachments
  List<Attachment> get imageAttachments => 
      attachments.where((attachment) => attachment.isImage).toList();

  /// Get all file attachments
  List<Attachment> get fileAttachments => 
      attachments.where((attachment) => attachment.isFile).toList();

  /// Get total size of all attachments
  int get totalAttachmentSize {
    return attachments
        .where((attachment) => attachment.sizeBytes != null)
        .fold(0, (total, attachment) => total + attachment.sizeBytes!);
  }

  /// Add an attachment to the note
  Note addAttachment(Attachment attachment) {
    final newAttachments = List<Attachment>.from(attachments)..add(attachment);
    return copyWith(
      attachments: newAttachments,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove an attachment from the note
  Note removeAttachment(String attachmentId) {
    final newAttachments = attachments
        .where((attachment) => attachment.id != attachmentId)
        .toList();
    return copyWith(
      attachments: newAttachments,
      updatedAt: DateTime.now(),
    );
  }

  /// Replace an attachment in the note
  Note replaceAttachment(String attachmentId, Attachment newAttachment) {
    final newAttachments = attachments
        .map((attachment) => attachment.id == attachmentId ? newAttachment : attachment)
        .toList();
    return copyWith(
      attachments: newAttachments,
      updatedAt: DateTime.now(),
    );
  }
}