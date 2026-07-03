import 'package:hive/hive.dart';

part 'question.g.dart';

@HiveType(typeId: 0)
class Question extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String question;

  @HiveField(2)
  Map<String, String> options;

  @HiveField(3)
  String correctOption;

  @HiveField(4)
  String answer;

  @HiveField(5)
  String explanation;

  @HiveField(6)
  String difficulty;

  @HiveField(7)
  String subject;

  @HiveField(8)
  List<String> tags;

  @HiveField(9)
  String setName;

  @HiveField(10)
  bool isRead;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.answer,
    required this.explanation,
    this.difficulty = 'medium',
    this.subject = 'general',
    this.tags = const [],
    this.setName = '',
    this.isRead = false,
  });

  factory Question.fromJson(Map<String, dynamic> json, String setName) {
    Map<String, String> opts = {};
    if (json['options'] != null) {
      (json['options'] as Map<String, dynamic>).forEach((k, v) {
        opts[k] = v.toString();
      });
    }
    return Question(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: opts,
      correctOption: json['correct_option']?.toString() ?? 'A',
      answer: json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      subject: json['subject']?.toString() ?? 'general',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      setName: setName,
      isRead: false,
    );
  }
}
