/// Note model for the application
class Note {
  final int id;
  final String title;
  final String content;
  final String preview;
  final String type; // text, voice, drawing, template
  final String? folder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool hasReminder;
  final List<String> tags;
  
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.preview,
    required this.type,
    this.folder,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.hasReminder = false,
    this.tags = const [],
  });
  
  /// Create a copy of this note with some fields updated
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? preview,
    String? type,
    String? folder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? hasReminder,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      preview: preview ?? this.preview,
      type: type ?? this.type,
      folder: folder ?? this.folder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      hasReminder: hasReminder ?? this.hasReminder,
      tags: tags ?? this.tags,
    );
  }
  
  /// Convert from Map (useful for JSON or database)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      preview: map['preview'] ?? '',
      type: map['type'] ?? 'text',
      folder: map['folder'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isPinned: map['isPinned'] ?? false,
      hasReminder: map['hasReminder'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
  
  /// Convert to Map (useful for JSON or database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'preview': preview,
      'type': type,
      'folder': folder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'hasReminder': hasReminder,
      'tags': tags,
    };
  }
  
  /// Get formatted creation date
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
  
  /// Get icon name for note type
  String get typeIcon {
    switch (type) {
      case 'voice':
        return 'mic';
      case 'drawing':
        return 'brush';
      case 'template':
        return 'description';
      default:
        return 'note';
    }
  }
  
  /// Check if note matches search query
  bool matches(String query) {
    if (query.isEmpty) return true;
    
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
           content.toLowerCase().contains(lowerQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }
  
  /// Get shareable content
  String get shareableContent {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln();
    buffer.writeln(content);
    
    if (tags.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Tags: ${tags.join(', ')}');
    }
    
    return buffer.toString();
  }
}