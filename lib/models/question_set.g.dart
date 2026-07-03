// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_set.dart';

class QuestionSetAdapter extends TypeAdapter<QuestionSet> {
  @override
  final int typeId = 1;

  @override
  QuestionSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionSet(
      setId: fields[0] as String,
      setName: fields[1] as String,
      subject: fields[2] as String,
      uploadedOn: fields[3] as String,
      totalQuestions: fields[4] as int,
      readCount: fields[5] as int,
      lastReadIndex: fields[6] as int,
      importedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionSet obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.setId)
      ..writeByte(1)
      ..write(obj.setName)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.uploadedOn)
      ..writeByte(4)
      ..write(obj.totalQuestions)
      ..writeByte(5)
      ..write(obj.readCount)
      ..writeByte(6)
      ..write(obj.lastReadIndex)
      ..writeByte(7)
      ..write(obj.importedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
