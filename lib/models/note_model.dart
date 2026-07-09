import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 6)
class NoteModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late int colorValue;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });
}
