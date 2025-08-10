import 'package:hive_flutter/hive_flutter.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  List<String> images;

  @HiveField(4)
  List<String> attachments;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  String? folderId;

  @HiveField(8)
  bool isPinned;

  @HiveField(9)
  List<String> tags;

  @HiveField(10)
  DateTime? deletedAt;

  @HiveField(11)
  String? noteType; // 'text', 'voice', 'drawing', 'template'

  @HiveField(12)
  bool hasReminder;

  @HiveField(13)
  DateTime? reminderAt;

  @HiveField(14)
  Map<String, dynamic>? metadata; // For additional data like voice memo paths, etc.

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.attachments = const [],
    this.folderId,
    this.isPinned = false,
    this.tags = const [],
    this.deletedAt,
    this.noteType = 'text',
    this.hasReminder = false,
    this.reminderAt,
    this.metadata,
  });

  // Factory constructor for creating from map (useful for cloud sync)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      images: List<String>.from(map['images'] ?? []),
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      folderId: map['folderId'] as String?,
      isPinned: map['isPinned'] as bool? ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      noteType: map['noteType'] as String? ?? 'text',
      hasReminder: map['hasReminder'] as bool? ?? false,
      reminderAt: map['reminderAt'] != null ? DateTime.parse(map['reminderAt'] as String) : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to map (useful for cloud sync)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'images': images,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'folderId': folderId,
      'isPinned': isPinned,
      'tags': tags,
      'deletedAt': deletedAt?.toIso8601String(),
      'noteType': noteType,
      'hasReminder': hasReminder,
      'reminderAt': reminderAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Get preview text (first 150 characters of content)
  String get preview {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  // Check if note is deleted
  bool get isDeleted => deletedAt != null;

  // Update the updatedAt timestamp
  void touch() {
    updatedAt = DateTime.now();
  }

  // Copy with method for updates
  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? images,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folderId,
    bool? isPinned,
    List<String>? tags,
    DateTime? deletedAt,
    String? noteType,
    bool? hasReminder,
    DateTime? reminderAt,
    Map<String, dynamic>? metadata,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      folderId: folderId ?? this.folderId,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      deletedAt: deletedAt ?? this.deletedAt,
      noteType: noteType ?? this.noteType,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderAt: reminderAt ?? this.reminderAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}