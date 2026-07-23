import 'package:hive_flutter/hive_flutter.dart';
import '../models/question.dart';
import '../models/question_set.dart';
import 'dart:convert';

class DatabaseService {
  static const String questionsBoxPrefix = 'questions_';
  static const String setsBox = 'question_sets';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(QuestionAdapter());
    Hive.registerAdapter(QuestionSetAdapter());
    await Hive.openBox<QuestionSet>(setsBox);
    await Hive.openBox(settingsBox);
  }

  Box<QuestionSet> get _setsBox => Hive.box<QuestionSet>(setsBox);
  Box get _settingsBox => Hive.box(settingsBox);

  // ── SETS ──────────────────────────────────

  List<QuestionSet> getAllSets() {
    return _setsBox.values.toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  Future<void> saveSet(QuestionSet qs) async {
    await _setsBox.put(qs.setId, qs);
  }

  Future<void> deleteSet(String setId) async {
    await _setsBox.delete(setId);
    final boxName = questionsBoxPrefix + setId;
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<Question>(boxName).deleteFromDisk();
      } else {
        final box = await Hive.openBox<Question>(boxName);
        await box.deleteFromDisk();
      }
    } catch (_) {}
  }

  QuestionSet? getSet(String setId) => _setsBox.get(setId);

  // ── QUESTIONS ─────────────────────────────

  Future<Box<Question>> _openQuestionsBox(String setId) async {
    final boxName = questionsBoxPrefix + setId;
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Question>(boxName);
    }
    return Hive.box<Question>(boxName);
  }

  Future<void> saveQuestions(String setId, List<Question> questions) async {
    final box = await _openQuestionsBox(setId);
    final Map<String, Question> batch = {};
    for (int i = 0; i < questions.length; i++) {
      batch['$i'] = questions[i];
    }
    await box.putAll(batch);
  }

  Future<List<Question>> getQuestionsForSet(String setId) async {
    final box = await _openQuestionsBox(setId);
    return box.values.toList();
  }

  // ── PROGRESS ──────────────────────────────

  Future<void> saveProgress(String setId, int index) async {
    await _settingsBox.put('progress_$setId', index);
    final qs = getSet(setId);
    if (qs != null) {
      qs.lastReadIndex = index;
      await qs.save();
    }
  }

  int getProgress(String setId) {
    return _settingsBox.get('progress_$setId', defaultValue: 0) as int;
  }

  Future<void> updateReadCount(String setId, int count) async {
    final qs = getSet(setId);
    if (qs != null) {
      qs.readCount = count;
      await qs.save();
    }
  }

  // ── STATS ─────────────────────────────────

  Map<String, int> getOverallStats() {
    final sets = getAllSets();
    int total = 0;
    int read = 0;
    for (final s in sets) {
      total += s.totalQuestions;
      read += s.readCount;
    }
    return {'total': total, 'read': read, 'sets': sets.length};
  }

  // ── QUESTION CRUD ─────────────────────────

  // Question delete
  Future<void> deleteQuestion(String setId, String questionKey) async {
    final box = await _openQuestionsBox(setId);
    await box.delete(questionKey);

    // Update total count
    final qs = getSet(setId);
    if (qs != null) {
      qs.totalQuestions = box.length;
      await qs.save();
    }
  }

  // New question add
  Future<void> addQuestion(String setId, Question question) async {
    final box = await _openQuestionsBox(setId);
    final key = box.length.toString();
    await box.put(key, question);

    // Update total count
    final qs = getSet(setId);
    if (qs != null) {
      qs.totalQuestions = box.length;
      await qs.save();
    }
  }

  // Question update (edit)
  Future<void> updateQuestion(
    String setId,
    String questionKey,
    Question question,
  ) async {
    final box = await _openQuestionsBox(setId);
    await box.put(questionKey, question);
  }

  // Get question keys (for delete/update)
  Future<List<String>> getQuestionKeys(String setId) async {
    final box = await _openQuestionsBox(setId);
    return box.keys.map((k) => k.toString()).toList();
  }

  // ── EXPORT ────────────────────────────────

  // Export set as JSON string
  Future<String> exportSetAsJson(String setId) async {
    final qs = getSet(setId);
    if (qs == null) return '';

    final box = await _openQuestionsBox(setId);
    final questions = box.values.toList();

    final questionList = questions
        .map(
          (q) => {
            'id': q.id,
            'question': q.question,
            'options': q.options,
            'correct_option': q.correctOption,
            'answer': q.answer,
            'explanation': q.explanation,
            'difficulty': q.difficulty,
            'subject': q.subject,
            'tags': q.tags,
          },
        )
        .toList();

    final exportData = {
      'set_name': qs.setName,
      'subject': qs.subject,
      'uploaded_on': qs.uploadedOn,
      'questions': questionList,
    };

    // Pretty JSON
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }
}
