// lib/services/notes_analyzer_service.dart

import '../models/question.dart';
import '../models/study_note.dart';

class NotesAnalyzerService {
  static final _numberPattern = RegExp(
    r'(\d{4}|\d+\s*সালে|\d+\s*সাল|\d+\s*শতক|\d+\s*বছর|\d+\s*জন|\d+\s*টি)',
  );

  static final _namePattern = RegExp(
    r'(গান্ধীজি|নেহরু|আকবর|বাবর|শিবাজী|তিলক|বিবেকানন্দ'
    r'|রবীন্দ্রনাথ|বঙ্কিমচন্দ্র|বিদ্যাসাগর|আম্বেডকর'
    r'|সুভাষচন্দ্র|নেতাজি|ভগৎ সিং|প্যাটেল|রামমোহন'
    r'|অশোক|চন্দ্রগুপ্ত|মহাবীর|বুদ্ধ|ক্লাইভ)',
  );

  static const _importantKeywords = [
    'প্রথম',
    'শেষ',
    'বৃহত্তম',
    'প্রতিষ্ঠা',
    'প্রতিষ্ঠাতা',
    'যুদ্ধ',
    'সন্ধি',
    'চুক্তি',
    'আইন',
    'আন্দোলন',
    'স্বাধীনতা',
    'রাজধানী',
    'সর্বোচ্চ',
    'একমাত্র',
  ];

  // ── Main analyze ─────────────────────────────────
  static List<StudyTopic> analyze(List<Question> questions) {
    // Step 1: Extract sentences — limit per question
    final allSentences = <_SentenceData>[];
    for (final q in questions) {
      if (q.explanation.trim().isEmpty) continue;
      final sentences = _splitSentences(q.explanation);

      // Max 3 sentences per question to avoid memory issues
      for (final s in sentences.take(3)) {
        final cleaned = s.trim();
        if (cleaned.length < 15 || cleaned.length > 300) continue;
        allSentences.add(
          _SentenceData(
            sentence: cleaned,
            tags: List<String>.from(q.tags),
            subject: q.subject,
          ),
        );
      }
    }

    // Step 2: Remove duplicates
    final unique = _removeDuplicates(allSentences);

    // Step 3: Score & group
    final grouped = <String, List<StudyFact>>{};
    final groupSubject = <String, String>{};

    for (final data in unique) {
      final fact = _score(data);
      final key = data.tags.isNotEmpty
          ? data.tags.first
          : _subjectLabel(data.subject);

      grouped.putIfAbsent(key, () => []).add(fact);
      groupSubject.putIfAbsent(key, () => data.subject);
    }

    // Step 4: Build topics — min 2 facts per topic
    final topics = <StudyTopic>[];
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;

      // Sort by importance
      final facts = List<StudyFact>.from(entry.value)
        ..sort((a, b) => b.importanceScore.compareTo(a.importanceScore));

      // Max 30 facts per topic
      final limited = facts.take(30).toList();

      topics.add(
        StudyTopic(
          topicName: entry.key,
          subject: groupSubject[entry.key] ?? 'general',
          facts: limited,
          tags: [entry.key],
        ),
      );
    }

    // Sort topics by fact count
    topics.sort((a, b) => b.factCount.compareTo(a.factCount));

    // Max 100 topics total
    return topics.take(100).toList();
  }

  static List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[।\.!\?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<_SentenceData> _removeDuplicates(List<_SentenceData> sentences) {
    final unique = <_SentenceData>[];
    final seen = <String>{};

    for (final candidate in sentences) {
      // Fast exact check first
      final key = candidate.sentence.replaceAll(' ', '').toLowerCase();
      if (seen.contains(key)) continue;

      // Near-duplicate check (only against last 50)
      bool isDuplicate = false;
      final checkAgainst = unique.length > 50
          ? unique.sublist(unique.length - 50)
          : unique;

      for (final existing in checkAgainst) {
        if (_similarity(candidate.sentence, existing.sentence) >= 0.70) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        unique.add(candidate);
        seen.add(key);
      }
    }

    return unique;
  }

  static double _similarity(String a, String b) {
    final wordsA = a.split(' ').toSet();
    final wordsB = b.split(' ').toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return 0;
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    return intersection / union;
  }

  static StudyFact _score(_SentenceData data) {
    int score = 0;
    final sentence = data.sentence;

    final numbers = _numberPattern
        .allMatches(sentence)
        .map((m) => m.group(0)!)
        .toList();
    score += numbers.length * 3;

    final names = _namePattern
        .allMatches(sentence)
        .map((m) => m.group(0)!)
        .toList();
    score += names.length * 3;

    for (final kw in _importantKeywords) {
      if (sentence.contains(kw)) score += 2;
    }

    final wordCount = sentence.split(' ').length;
    if (wordCount >= 8 && wordCount <= 40) score += 1;

    return StudyFact(
      sentence: sentence,
      importanceScore: score.clamp(0, 20),
      highlightedNumbers: numbers,
      highlightedNames: names,
      sourceTopic: data.tags.isNotEmpty ? data.tags.first : '',
      subject: data.subject,
    );
  }

  static String _subjectLabel(String subject) {
    const labels = {
      'history': 'ইতিহাস',
      'geography': 'ভূগোল',
      'physics': 'পদার্থবিজ্ঞান',
      'chemistry': 'রসায়ন',
      'biology': 'জীববিজ্ঞান',
      'economics': 'অর্থনীতি',
      'mathematics': 'গণিত',
      'reasoning': 'যুক্তিবিদ্যা',
      'english': 'ইংরেজি',
      'current_affairs': 'সমসাময়িক',
      'west_bengal': 'পশ্চিমবঙ্গ',
      'computer': 'কম্পিউটার',
    };
    return labels[subject] ?? 'সাধারণ';
  }
}

class _SentenceData {
  final String sentence;
  final List<String> tags;
  final String subject;
  _SentenceData({
    required this.sentence,
    required this.tags,
    required this.subject,
  });
}
