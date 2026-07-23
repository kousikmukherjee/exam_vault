// lib/screens/study_notes/study_notes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question.dart';
import '../../models/question_set.dart';
import '../../models/study_note.dart';
import '../../providers/app_provider.dart';
import '../../services/notes_analyzer_service.dart';
import '../../theme.dart';
import 'chapter_detail_screen.dart';

class StudyNotesScreen extends StatefulWidget {
  const StudyNotesScreen({super.key});

  @override
  State<StudyNotesScreen> createState() => _StudyNotesScreenState();
}

class _StudyNotesScreenState extends State<StudyNotesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        automaticallyImplyLeading: false,
        title: const Text(
          '📖 Study Notes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final sets = provider.sets;

          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'কোনো MCQ Set নেই',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'প্রথমে MCQ tab থেকে Set import করুন',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              return _SetCard(
                questionSet: set,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SetAnalyzeScreen(questionSet: set),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Set Card ──────────────────────────────────────────

class _SetCard extends StatelessWidget {
  final QuestionSet questionSet;
  final VoidCallback onTap;

  const _SetCard({required this.questionSet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.subjectColor(questionSet.subject);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _emoji(questionSet.subject),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionSet.setName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _pill('${questionSet.totalQuestions} প্রশ্ন', color),
                        const SizedBox(width: 6),
                        _pill(
                          AppTheme.subjectLabel(questionSet.subject),
                          Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.menu_book_rounded, color: color, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    'পড়ুন',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );

  String _emoji(String subject) {
    const e = {
      'history': '🏛️',
      'geography': '🌍',
      'physics': '⚡',
      'chemistry': '🧪',
      'biology': '🧬',
      'economics': '💰',
      'mathematics': '📐',
      'reasoning': '🧠',
      'english': '📝',
      'current_affairs': '📰',
      'west_bengal': '🌺',
      'computer': '💻',
    };
    return e[subject] ?? '📚';
  }
}

// ── Set Analyze Screen ────────────────────────────────

class _SetAnalyzeScreen extends StatefulWidget {
  final QuestionSet questionSet;
  const _SetAnalyzeScreen({required this.questionSet});

  @override
  State<_SetAnalyzeScreen> createState() => _SetAnalyzeScreenState();
}

class _SetAnalyzeScreenState extends State<_SetAnalyzeScreen> {
  List<StudyTopic> _topics = [];
  bool _isLoading = true;
  String _loadingMessage = 'প্রশ্ন লোড হচ্ছে...';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // In-memory cache
  static final Map<String, List<StudyTopic>> _cache = {};

  @override
  void initState() {
    super.initState();
    _loadAndAnalyze();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAndAnalyze({bool forceReload = false}) async {
    final setId = widget.questionSet.setId;

    // Use cache if available
    if (!forceReload && _cache.containsKey(setId)) {
      setState(() {
        _topics = _cache[setId]!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'প্রশ্ন লোড হচ্ছে...';
    });

    try {
      final provider = context.read<AppProvider>();

      // ── KEY FIX: Load questions on main thread first ──
      // Then pass only plain List<Question> (no Hive objects)
      final rawQuestions = await provider.db.getQuestionsForSet(setId);

      if (rawQuestions.isEmpty) {
        setState(() {
          _topics = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _loadingMessage = 'বিশ্লেষণ চলছে...');

      // ── Convert to plain objects before passing ───────
      // Hive objects cannot be sent to isolate
      // So we create simple plain Question copies
      final plainQuestions = rawQuestions
          .map(
            (q) => Question(
              id: q.id,
              question: q.question,
              options: Map<String, String>.from(q.options),
              correctOption: q.correctOption,
              answer: q.answer,
              explanation: q.explanation,
              difficulty: q.difficulty,
              subject: q.subject,
              tags: List<String>.from(q.tags),
              setName: q.setName,
            ),
          )
          .toList();

      // ── Run analyze on main thread (no isolate) ───────
      // compute() causes issues with custom objects
      // For 100-200 questions this is fast enough
      setState(() => _loadingMessage = 'সাজানো হচ্ছে...');

      // Small delay to show loading UI
      await Future.delayed(const Duration(milliseconds: 50));

      final topics = NotesAnalyzerService.analyze(plainQuestions);

      // Cache result
      _cache[setId] = topics;

      if (mounted) {
        setState(() {
          _topics = topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<StudyTopic> get _filtered {
    if (_searchQuery.isEmpty) return _topics;
    return _topics
        .where(
          (t) =>
              t.topicName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.tags.any(
                (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.subjectColor(widget.questionSet.subject);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.questionSet.setName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (!_isLoading)
              Text(
                '${_topics.length} টি Topic পাওয়া গেছে',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
          ],
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => _loadAndAnalyze(forceReload: true),
              tooltip: 'পুনরায় বিশ্লেষণ',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _topics.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Topic খুঁজুন...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(
                        Icons.folder_rounded,
                        '${_filtered.length}',
                        'Topics',
                      ),
                      _vDiv(),
                      _stat(
                        Icons.lightbulb_rounded,
                        '${_filtered.fold(0, (s, t) => s + t.factCount)}',
                        'তথ্য',
                      ),
                      _vDiv(),
                      _stat(
                        Icons.timer_rounded,
                        '~${_filtered.fold(0, (s, t) => s + t.readingTimeMin)} min',
                        'পড়ার সময়',
                      ),
                    ],
                  ),
                ),

                // Topic list
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            '"$_searchQuery" পাওয়া যায়নি',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final topic = _filtered[index];
                            return _TopicCard(
                              topic: topic,
                              index: index + 1,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChapterDetailScreen(topic: topic),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            _loadingMessage,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'একটু অপেক্ষা করুন...',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'কোনো Topic পাওয়া যায়নি',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'JSON-এ explanation field থাকলে topic দেখাবে',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _loadAndAnalyze(forceReload: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('আবার চেষ্টা করুন'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, color: AppTheme.primary, size: 16),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppTheme.primary,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ],
  );

  Widget _vDiv() =>
      Container(width: 1, height: 32, color: Colors.grey.shade300);
}

// ── Topic Card ────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final StudyTopic topic;
  final int index;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.subjectColor(topic.subject);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.topicName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _pill('${topic.factCount} তথ্য', color),
                        const SizedBox(width: 6),
                        _pill('~${topic.readingTimeMin} min', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}
