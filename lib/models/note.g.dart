// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      images: (fields[3] as List).cast<String>(),
      attachments: (fields[4] as List).cast<String>(),
      folderId: fields[7] as String?,
      isPinned: fields[8] as bool,
      tags: (fields[9] as List).cast<String>(),
      deletedAt: fields[10] as DateTime?,
      noteType: fields[11] as String?,
      hasReminder: fields[12] as bool,
      reminderAt: fields[13] as DateTime?,
      metadata: (fields[14] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.images)
      ..writeByte(4)
      ..write(obj.attachments)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.folderId)
      ..writeByte(8)
      ..write(obj.isPinned)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.noteType)
      ..writeByte(12)
      ..write(obj.hasReminder)
      ..writeByte(13)
      ..write(obj.reminderAt)
      ..writeByte(14)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
