// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfDocumentAdapter extends TypeAdapter<PdfDocument> {
  @override
  final int typeId = 5;

  @override
  PdfDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfDocument(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      dateAdded: fields[3] as DateTime,
      lastPage: fields[4] as int,
      bookmarkedPages: (fields[5] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, PdfDocument obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.dateAdded)
      ..writeByte(4)
      ..write(obj.lastPage)
      ..writeByte(5)
      ..write(obj.bookmarkedPages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
