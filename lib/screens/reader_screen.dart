import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';
import '../models/question_set.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'question_editor_screen.dart';

class ReaderScreen extends StatefulWidget {
  final QuestionSet questionSet;
  const ReaderScreen({super.key, required this.questionSet});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  List<Question> _questions = [];
  List<String> _questionKeys = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int _readCount = 0;

  String? _selectedOption;
  bool _isAnswered = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isReadMode = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final provider = context.read<AppProvider>();
    final questions = await provider.db.getQuestionsForSet(
      widget.questionSet.setId,
    );
    final keys = await provider.db.getQuestionKeys(widget.questionSet.setId);
    final savedIndex = provider.db.getProgress(widget.questionSet.setId);

    setState(() {
      _questions = questions;
      _questionKeys = keys;
      _currentIndex = savedIndex.clamp(
        0,
        questions.isEmpty ? 0 : questions.length - 1,
      );
      _readCount = widget.questionSet.readCount;
      _isLoading = false;
    });

    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _selectedOption = null;
      _isAnswered = false;
      if (index > _readCount) _readCount = index;
    });
    if (index % 5 == 0) _saveProgress();
  }

  void _onOptionTapped(String optionKey, String correctOption) {
    if (_isAnswered || _isReadMode) return;
    setState(() {
      _selectedOption = optionKey;
      _isAnswered = true;
      if (optionKey == correctOption) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });
  }

  Future<void> _saveProgress() async {
    final provider = context.read<AppProvider>();
    await provider.updateProgress(
      widget.questionSet.setId,
      _currentIndex,
      _readCount,
    );
  }

  void _goNext() {
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProgress();
      _showCompletionDialog();
    }
  }

  void _goPrev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleReadMode() {
    setState(() {
      _isReadMode = !_isReadMode;
      _selectedOption = null;
      _isAnswered = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isReadMode ? Icons.menu_book_rounded : Icons.quiz_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isReadMode
                  ? 'Read Mode ON — সব উত্তর দেখা যাচ্ছে'
                  : 'Test Mode ON — নিজে উত্তর দিন',
            ),
          ],
        ),
        backgroundColor: _isReadMode ? Colors.amber.shade700 : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Delete current question ──────────────────────
  void _deleteCurrentQuestion() {
    if (_questions.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('প্রশ্ন মুছবেন?'),
          ],
        ),
        content: Text(
          'Q.${_currentIndex + 1} মুছে দেওয়া হবে।\nএই কাজ পূর্বাবস্থায় ফেরানো যাবে না।',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AppProvider>();
              final key = _questionKeys[_currentIndex];
              await provider.deleteQuestion(widget.questionSet.setId, key);

              // Reload
              await _loadQuestions();
              setState(() {
                if (_currentIndex >= _questions.length && _currentIndex > 0) {
                  _currentIndex = _questions.length - 1;
                }
                _selectedOption = null;
                _isAnswered = false;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ প্রশ্ন মুছে গেছে'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
  }

  // ── Add new question ─────────────────────────────
  void _addNewQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          setId: widget.questionSet.setId,
          setName: widget.questionSet.setName,
          subject: widget.questionSet.subject,
        ),
      ),
    ).then((result) {
      if (result == true) _loadQuestions();
    });
  }

  // ── Edit current question ────────────────────────
  void _editCurrentQuestion() {
    if (_questions.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          setId: widget.questionSet.setId,
          setName: widget.questionSet.setName,
          subject: widget.questionSet.subject,
          question: _questions[_currentIndex],
          questionKey: _questionKeys[_currentIndex],
        ),
      ),
    ).then((result) {
      if (result == true) _loadQuestions();
    });
  }

  // ── Export set as JSON ───────────────────────────
  Future<void> _exportSet() async {
    setState(() => _isExporting = true);
    try {
      final provider = context.read<AppProvider>();
      final jsonString = await provider.exportSet(widget.questionSet.setId);

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final fileName =
          '${widget.questionSet.setName.replaceAll(' ', '_')}_export.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString, encoding: utf8);

      // Share
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/json'),
      ], subject: '${widget.questionSet.setName} — Exported Questions');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isExporting = false);
  }

  void _jumpToQuestion() {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Jump to Question'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '1 - ${_questions.length}',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final n = int.tryParse(ctrl.text);
                if (n != null && n >= 1 && n <= _questions.length) {
                  Navigator.pop(ctx);
                  _pageController.jumpToPage(n - 1);
                }
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _showScoreDialog() {
    final total = _correctCount + _wrongCount;
    final percent = total > 0
        ? ((_correctCount / total) * 100).toStringAsFixed(0)
        : '0';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Session Score',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: _scoreColor(int.parse(percent)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _scoreChip('Correct', _correctCount, AppTheme.successLight),
                _scoreChip('Wrong', _wrongCount, AppTheme.error),
                _scoreChip('Skipped', _currentIndex + 1 - total, Colors.grey),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int percent) {
    if (percent >= 75) return AppTheme.successLight;
    if (percent >= 50) return AppTheme.accent;
    return AppTheme.error;
  }

  Widget _scoreChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.questionSet.setName)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading questions...'),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.questionSet.setName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No questions found'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addNewQuestion,
                icon: const Icon(Icons.add),
                label: const Text('প্রশ্ন যোগ করুন'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = AppTheme.subjectColor(widget.questionSet.subject);
    final progress = (_currentIndex + 1) / _questions.length;

    return PopScope(
      canPop: true,
      onPopInvoked: (_) => _saveProgress(),
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.questionSet.setName,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Q.${_currentIndex + 1} of ${_questions.length}   •   ${(progress * 100).toStringAsFixed(0)}% done',
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
          actions: [
            // ── Read Mode Toggle ──────────────────
            GestureDetector(
              onTap: _toggleReadMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _isReadMode
                      ? Colors.amber.shade600
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isReadMode ? Colors.amber.shade300 : Colors.white30,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isReadMode
                          ? Icons.menu_book_rounded
                          : Icons.quiz_rounded,
                      color: _isReadMode ? Colors.black : Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isReadMode ? 'Read' : 'Test',
                      style: TextStyle(
                        color: _isReadMode ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // ── More options menu ─────────────────
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFF16213E),
              onSelected: (val) {
                switch (val) {
                  case 'add':
                    _addNewQuestion();
                    break;
                  case 'edit':
                    _editCurrentQuestion();
                    break;
                  case 'delete':
                    _deleteCurrentQuestion();
                    break;
                  case 'export':
                    _exportSet();
                    break;
                  case 'jump':
                    _jumpToQuestion();
                    break;
                  case 'score':
                    _showScoreDialog();
                    break;
                }
              },
              itemBuilder: (_) => [
                _menuItem(
                  'add',
                  Icons.add_circle_outline,
                  'নতুন প্রশ্ন যোগ',
                  Colors.green,
                ),
                _menuItem(
                  'edit',
                  Icons.edit_outlined,
                  'এই প্রশ্ন সম্পাদনা',
                  Colors.blue,
                ),
                _menuItem(
                  'delete',
                  Icons.delete_outline,
                  'এই প্রশ্ন মুছুন',
                  Colors.red,
                ),
                const PopupMenuDivider(),
                _menuItem(
                  'export',
                  Icons.upload_file_rounded,
                  'Set Export করুন',
                  Colors.orange,
                ),
                const PopupMenuDivider(),
                _menuItem(
                  'jump',
                  Icons.search_rounded,
                  'প্রশ্নে যান',
                  Colors.purple,
                ),
                if (!_isReadMode)
                  _menuItem(
                    'score',
                    Icons.emoji_events_rounded,
                    'Score দেখুন',
                    Colors.amber,
                  ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isReadMode ? Colors.amber : AppTheme.accentLight,
              ),
              minHeight: 3,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Mode hint bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _isReadMode
                    ? Colors.amber.withOpacity(0.12)
                    : color.withOpacity(0.06),
                padding: const EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isReadMode
                          ? Icons.menu_book_rounded
                          : Icons.touch_app_rounded,
                      size: 14,
                      color: _isReadMode ? Colors.amber.shade700 : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isReadMode
                          ? 'Read Mode — সব উত্তর ও ব্যাখ্যা দেখা যাচ্ছে'
                          : 'Tap an option to answer  •  Swipe to navigate',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isReadMode ? Colors.amber.shade700 : color,
                        fontWeight: _isReadMode
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Export loading
              if (_isExporting)
                LinearProgressIndicator(
                  backgroundColor: Colors.orange.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                ),

              // Question PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    final selected = index == _currentIndex
                        ? _selectedOption
                        : null;
                    final answered = index == _currentIndex
                        ? _isAnswered
                        : false;
                    return _QuestionCard(
                      question: q,
                      questionNumber: index + 1,
                      selectedOption: selected,
                      isAnswered: answered,
                      isReadMode: _isReadMode,
                      onOptionTapped: (key) =>
                          _onOptionTapped(key, q.correctOption),
                      subjectColor: AppTheme.subjectColor(q.subject),
                    );
                  },
                ),
              ),

              // Bottom nav
              _buildBottomNav(color),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Color color) {
    final bool canGoNext = _isReadMode || _isAnswered;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _navBtn(
            icon: Icons.arrow_back_rounded,
            enabled: _currentIndex > 0,
            color: _isReadMode ? Colors.amber.shade700 : color,
            onTap: _goPrev,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: canGoNext
                ? ElevatedButton.icon(
                    onPressed: _goNext,
                    icon: Icon(
                      _currentIndex < _questions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.emoji_events_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentIndex < _questions.length - 1
                          ? 'Next Question'
                          : 'Complete!',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isReadMode
                          ? Colors.amber.shade600
                          : color,
                      foregroundColor: _isReadMode
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.touch_app_rounded, size: 18),
                    label: const Text('Tap an Option Above'),
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          _navBtn(
            icon: Icons.arrow_forward_rounded,
            enabled: _currentIndex < _questions.length - 1,
            color: _isReadMode ? Colors.amber.shade700 : color,
            onTap: _goNext,
          ),
        ],
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required bool enabled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: enabled ? color : Colors.grey.shade300),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  void _showCompletionDialog() {
    final total = _correctCount + _wrongCount;
    final percent = total > 0
        ? ((_correctCount / total) * 100).toStringAsFixed(0)
        : '0';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🏆  ', style: TextStyle(fontSize: 24)),
            Text(
              'Set Completed!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You finished all ${_questions.length} questions!',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _scoreChip('Correct', _correctCount, AppTheme.successLight),
                  _scoreChip('Wrong', _wrongCount, AppTheme.error),
                  _scoreChip(
                    'Score %',
                    int.parse(percent),
                    _scoreColor(int.parse(percent)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Vault'),
          ),
        ],
      ),
    );
  }
}

// ── Question Card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final String? selectedOption;
  final bool isAnswered;
  final bool isReadMode;
  final void Function(String) onOptionTapped;
  final Color subjectColor;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.selectedOption,
    required this.isAnswered,
    required this.isReadMode,
    required this.onOptionTapped,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool showAnswer = isAnswered || isReadMode;
    final bool isCorrectAnswer =
        isAnswered && selectedOption == question.correctOption;
    final bool isWrongAnswer =
        isAnswered && selectedOption != question.correctOption;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _pill('Q.$questionNumber', subjectColor),
                      const SizedBox(width: 8),
                      _pill(
                        AppTheme.subjectLabel(question.subject),
                        subjectColor,
                      ),
                      const Spacer(),
                      if (isReadMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            '📖 Read',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          AppTheme.difficultyLabel(question.difficulty),
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          ...question.options.entries.map(
            (e) => _OptionTile(
              optionKey: e.key,
              optionText: e.value,
              isAnswered: isAnswered,
              isReadMode: isReadMode,
              isCorrect: e.key == question.correctOption,
              isSelected: selectedOption == e.key,
              onTap: () => onOptionTapped(e.key),
            ),
          ),

          const SizedBox(height: 14),

          if (showAnswer) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isReadMode
                    ? Colors.green.withOpacity(0.08)
                    : isCorrectAnswer
                    ? AppTheme.successLight.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isReadMode
                      ? Colors.green.withOpacity(0.4)
                      : isCorrectAnswer
                      ? AppTheme.successLight.withOpacity(0.5)
                      : AppTheme.error.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isReadMode
                          ? AppTheme.successLight
                          : isCorrectAnswer
                          ? AppTheme.successLight
                          : AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReadMode
                          ? Icons.check_rounded
                          : isCorrectAnswer
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReadMode
                              ? 'সঠিক উত্তর 📖'
                              : isCorrectAnswer
                              ? 'CORRECT! 🎉'
                              : 'WRONG ❌',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isReadMode
                                ? AppTheme.successLight
                                : isCorrectAnswer
                                ? AppTheme.successLight
                                : AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (!isReadMode && isWrongAnswer)
                          Text(
                            'Correct: (${question.correctOption}) ${question.answer}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successLight,
                            ),
                          )
                        else
                          Text(
                            '(${question.correctOption}) ${question.answer}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          color: AppTheme.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'EXPLANATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        if (isReadMode) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '📖 Read Mode',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.explanation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.65,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    if (question.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: question.tags
                            .map(
                              (tag) => Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: subjectColor.withOpacity(0.08),
                                side: BorderSide(
                                  color: subjectColor.withOpacity(0.2),
                                ),
                                labelStyle: TextStyle(color: subjectColor),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}

// ── Option Tile ───────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String optionKey;
  final String optionText;
  final bool isAnswered;
  final bool isReadMode;
  final bool isCorrect;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.optionKey,
    required this.optionText,
    required this.isAnswered,
    required this.isReadMode,
    required this.isCorrect,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool showResult = isAnswered || isReadMode;

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);
    Color textColor = const Color(0xFF333333);
    Color keyBgColor = const Color(0xFFF0F0F0);
    Color keyTextColor = Colors.grey.shade700;
    Widget? trailingIcon;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppTheme.successLight.withOpacity(0.08);
        borderColor = AppTheme.successLight.withOpacity(0.5);
        textColor = AppTheme.success;
        keyBgColor = AppTheme.successLight;
        keyTextColor = Colors.white;
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppTheme.successLight,
          size: 22,
        );
      } else if (!isReadMode && isSelected) {
        bgColor = AppTheme.error.withOpacity(0.07);
        borderColor = AppTheme.error.withOpacity(0.4);
        textColor = AppTheme.error;
        keyBgColor = AppTheme.error;
        keyTextColor = Colors.white;
        trailingIcon = const Icon(
          Icons.cancel_rounded,
          color: AppTheme.error,
          size: 22,
        );
      } else {
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade200;
        textColor = Colors.grey.shade400;
        keyBgColor = Colors.grey.shade200;
        keyTextColor = Colors.grey.shade400;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: (showResult && (isCorrect || isSelected)) ? 1.5 : 1,
        ),
        boxShadow: !showResult
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showResult ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppTheme.primary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: keyBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      optionKey,
                      style: TextStyle(
                        color: keyTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: (showResult && (isCorrect || isSelected))
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  trailingIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
