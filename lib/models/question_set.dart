import 'package:hive/hive.dart';

part 'question_set.g.dart';

@HiveType(typeId: 1)
class QuestionSet extends HiveObject {
  @HiveField(0)
  String setId;

  @HiveField(1)
  String setName;

  @HiveField(2)
  String subject;

  @HiveField(3)
  String uploadedOn;

  @HiveField(4)
  int totalQuestions;

  @HiveField(5)
  int readCount;

  @HiveField(6)
  int lastReadIndex;

  @HiveField(7)
  DateTime importedAt;

  QuestionSet({
    required this.setId,
    required this.setName,
    required this.subject,
    required this.uploadedOn,
    required this.totalQuestions,
    this.readCount = 0,
    this.lastReadIndex = 0,
    required this.importedAt,
  });
}
