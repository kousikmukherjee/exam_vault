// lib/screens/study_notes/chapter_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/study_note.dart';
import '../../theme.dart';

class ChapterDetailScreen extends StatefulWidget {
  final StudyTopic topic;

  const ChapterDetailScreen({super.key, required this.topic});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  double _fontSize = 15.0;
  final ScrollController _scrollController = ScrollController();
  double _readProgress = 0.0;
  bool _showMarkedOnly = false;

  // Hive box for saving marked facts
  late Box<bool> _marksBox;

  @override
  void initState() {
    super.initState();
    _marksBox = Hive.box<bool>('marked_facts');
    _scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) {
        setState(() {
          _readProgress = (_scrollController.offset / max).clamp(0.0, 1.0);
        });
      }
    }
  }

  // Unique key for each fact
  String _factKey(int index) =>
      '${widget.topic.topicName}_${widget.topic.subject}_$index';

  bool _isMarked(int index) => _marksBox.get(_factKey(index)) ?? false;

  void _toggleMark(int index) {
    final key = _factKey(index);
    final current = _marksBox.get(key) ?? false;
    _marksBox.put(key, !current);
    setState(() {});
  }

  int get _markedCount {
    int count = 0;
    for (int i = 0; i < widget.topic.facts.length; i++) {
      if (_isMarked(i)) count++;
    }
    return count;
  }

  List<_IndexedFact> get _displayFacts {
    final all = widget.topic.facts
        .asMap()
        .entries
        .map((e) => _IndexedFact(index: e.key, fact: e.value))
        .toList();

    if (_showMarkedOnly) {
      return all.where((f) => _isMarked(f.index)).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.subjectColor(widget.topic.subject);
    final markedCount = _markedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic.topicName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.topic.facts.length} তথ্য  •  ~${widget.topic.readingTimeMin} min',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Marked only toggle
          if (markedCount > 0)
            GestureDetector(
              onTap: () => setState(() => _showMarkedOnly = !_showMarkedOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _showMarkedOnly
                      ? Colors.amber.shade600
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showMarkedOnly
                        ? Colors.amber.shade300
                        : Colors.white30,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: _showMarkedOnly ? Colors.black : Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$markedCount',
                      style: TextStyle(
                        color: _showMarkedOnly ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 4),

          // Font size buttons
          IconButton(
            icon: const Icon(
              Icons.text_decrease,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (_fontSize > 12) setState(() => _fontSize -= 1);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.text_increase,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (_fontSize < 22) setState(() => _fontSize += 1);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _readProgress,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              _showMarkedOnly ? Colors.amber : color,
            ),
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showMarkedOnly
                  ? Colors.amber.withOpacity(0.08)
                  : color.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(
                  color: _showMarkedOnly
                      ? Colors.amber.withOpacity(0.3)
                      : color.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _emoji(widget.topic.subject),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showMarkedOnly
                            ? '⭐ Important তথ্য'
                            : widget.topic.topicName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _showMarkedOnly
                              ? Colors.amber.shade700
                              : color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showMarkedOnly
                            ? '$markedCount টি marked তথ্য'
                            : '${widget.topic.facts.length} টি তথ্য',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Filter hint ──────────────────────────────
          if (_showMarkedOnly)
            Container(
              color: Colors.amber.withOpacity(0.06),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'শুধু Important দেখাচ্ছে — সব দেখতে ⭐ চাপুন',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // ── Facts list ───────────────────────────────
          Expanded(
            child: _displayFacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'এখনো কোনো তথ্য mark করা হয়নি',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'তথ্যের পাশে ⭐ চাপলে mark হবে',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: _displayFacts.length,
                    itemBuilder: (context, i) {
                      final item = _displayFacts[i];
                      return _FactCard(
                        fact: item.fact,
                        index: item.index,
                        isMarked: _isMarked(item.index),
                        onToggleMark: () => _toggleMark(item.index),
                        fontSize: _fontSize,
                        accentColor: color,
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Bottom progress ──────────────────────────────
      bottomNavigationBar: Container(
        height: 48,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(
              '${(_readProgress * 100).toInt()}% পড়া হয়েছে',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _readProgress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Marked count badge
            if (markedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$markedCount',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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

// ── Helper class ──────────────────────────────────────
class _IndexedFact {
  final int index;
  final StudyFact fact;
  _IndexedFact({required this.index, required this.fact});
}

// ── Fact Card ─────────────────────────────────────────

class _FactCard extends StatelessWidget {
  final StudyFact fact;
  final int index;
  final bool isMarked;
  final VoidCallback onToggleMark;
  final double fontSize;
  final Color accentColor;

  const _FactCard({
    required this.fact,
    required this.index,
    required this.isMarked,
    required this.onToggleMark,
    required this.fontSize,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isMarked ? Colors.amber.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMarked
              ? Colors.amber.withOpacity(0.5)
              : fact.importanceScore >= 8
              ? accentColor.withOpacity(0.25)
              : Colors.grey.shade200,
          width: isMarked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bullet dot
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isMarked
                      ? Colors.amber
                      : fact.importanceScore >= 8
                      ? accentColor
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Sentence text
            Expanded(child: _buildText(fact.sentence)),
            const SizedBox(width: 8),

            // Star mark button
            GestureDetector(
              onTap: onToggleMark,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isMarked
                      ? Colors.amber.withOpacity(0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMarked ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isMarked ? Colors.amber : Colors.grey.shade400,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    if (fact.highlightedNumbers.isEmpty && fact.highlightedNames.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          color: const Color(0xFF333333),
        ),
      );
    }

    final spans = <InlineSpan>[];
    final highlights = <_HL>[];

    for (final num in fact.highlightedNumbers) {
      int start = 0;
      while (true) {
        final idx = text.indexOf(num, start);
        if (idx == -1) break;
        highlights.add(
          _HL(text: num, start: idx, end: idx + num.length, isNum: true),
        );
        start = idx + num.length;
      }
    }

    for (final name in fact.highlightedNames) {
      int start = 0;
      while (true) {
        final idx = text.indexOf(name, start);
        if (idx == -1) break;
        final overlaps = highlights.any(
          (h) => idx < h.end && idx + name.length > h.start,
        );
        if (!overlaps) {
          highlights.add(
            _HL(text: name, start: idx, end: idx + name.length, isNum: false),
          );
        }
        start = idx + name.length;
      }
    }

    highlights.sort((a, b) => a.start.compareTo(b.start));

    int cursor = 0;
    for (final h in highlights) {
      if (h.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, h.start),
            style: TextStyle(
              fontSize: fontSize,
              height: 1.6,
              color: const Color(0xFF333333),
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: h.text,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.6,
            fontWeight: FontWeight.bold,
            color: h.isNum
                ? Colors.deepOrange.shade700
                : accentColor.withOpacity(0.9),
            backgroundColor: h.isNum
                ? Colors.orange.withOpacity(0.12)
                : accentColor.withOpacity(0.08),
          ),
        ),
      );
      cursor = h.end;
    }

    if (cursor < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: TextStyle(
            fontSize: fontSize,
            height: 1.6,
            color: const Color(0xFF333333),
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _HL {
  final String text;
  final int start;
  final int end;
  final bool isNum;
  _HL({
    required this.text,
    required this.start,
    required this.end,
    required this.isNum,
  });
}
