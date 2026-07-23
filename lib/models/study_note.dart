// lib/models/study_note.dart

class StudyFact {
  final String sentence;
  final int importanceScore;
  final List<String> highlightedNumbers; // dates, years, numbers
  final List<String> highlightedNames; // person names, place names
  final String sourceTopic;
  final String subject;

  const StudyFact({
    required this.sentence,
    required this.importanceScore,
    required this.highlightedNumbers,
    required this.highlightedNames,
    required this.sourceTopic,
    required this.subject,
  });
}

class StudyTopic {
  final String topicName;
  final String subject;
  final List<StudyFact> facts;
  final List<String> tags;

  StudyTopic({
    required this.topicName,
    required this.subject,
    required this.facts,
    required this.tags,
  });

  int get factCount => facts.length;

  // Reading time: ~50 words per minute for Bengali
  int get readingTimeMin {
    final totalWords = facts
        .map((f) => f.sentence.split(' ').length)
        .fold(0, (a, b) => a + b);
    return (totalWords / 50).ceil().clamp(1, 99);
  }

  // Average importance
  double get avgImportance {
    if (facts.isEmpty) return 0;
    return facts.map((f) => f.importanceScore).fold(0, (a, b) => a + b) /
        facts.length;
  }
}
