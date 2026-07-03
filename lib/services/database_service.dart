import 'package:hive_flutter/hive_flutter.dart';
import '../models/question.dart';
import '../models/question_set.dart';

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
}
