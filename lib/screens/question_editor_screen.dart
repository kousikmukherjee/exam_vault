import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';

class QuestionEditorScreen extends StatefulWidget {
  final String setId;
  final String setName;
  final String subject;
  final Question? question; // null = new question, not null = edit
  final String? questionKey; // Hive key (for edit/delete)

  const QuestionEditorScreen({
    super.key,
    required this.setId,
    required this.setName,
    required this.subject,
    this.question,
    this.questionKey,
  });

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _questionController;
  late TextEditingController _optionAController;
  late TextEditingController _optionBController;
  late TextEditingController _optionCController;
  late TextEditingController _optionDController;
  late TextEditingController _answerController;
  late TextEditingController _explanationController;
  late TextEditingController _tagsController;

  String _correctOption = 'A';
  String _difficulty = 'medium';
  bool _isSaving = false;

  final List<String> _difficultyOptions = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    final q = widget.question;

    _idController = TextEditingController(
      text: q?.id ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
    );
    _questionController = TextEditingController(text: q?.question ?? '');
    _optionAController = TextEditingController(text: q?.options['A'] ?? '');
    _optionBController = TextEditingController(text: q?.options['B'] ?? '');
    _optionCController = TextEditingController(text: q?.options['C'] ?? '');
    _optionDController = TextEditingController(text: q?.options['D'] ?? '');
    _answerController = TextEditingController(text: q?.answer ?? '');
    _explanationController = TextEditingController(text: q?.explanation ?? '');
    _tagsController = TextEditingController(text: q?.tags.join(', ') ?? '');

    _correctOption = q?.correctOption ?? 'A';
    _difficulty = q?.difficulty ?? 'medium';
  }

  @override
  void dispose() {
    _idController.dispose();
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final newQuestion = Question(
      id: _idController.text.trim(),
      question: _questionController.text.trim(),
      options: {
        'A': _optionAController.text.trim(),
        'B': _optionBController.text.trim(),
        'C': _optionCController.text.trim(),
        'D': _optionDController.text.trim(),
      },
      correctOption: _correctOption,
      answer: _answerController.text.trim(),
      explanation: _explanationController.text.trim(),
      difficulty: _difficulty,
      subject: widget.subject,
      tags: tags,
      setName: widget.setName,
    );

    final provider = context.read<AppProvider>();

    if (widget.question == null) {
      // New question
      await provider.addQuestion(widget.setId, newQuestion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ প্রশ্ন যোগ হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      // Edit question
      await provider.updateQuestion(
        widget.setId,
        widget.questionKey!,
        newQuestion,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ প্রশ্ন আপডেট হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.question == null;
    final color = AppTheme.subjectColor(widget.subject);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isNew ? 'নতুন প্রশ্ন যোগ করুন' : 'প্রশ্ন সম্পাদনা করুন',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Question ID ───────────────────────────
            _sectionTitle('Question ID'),
            _inputField(
              controller: _idController,
              hint: 'q_001',
              validator: (v) => v!.isEmpty ? 'ID দিন' : null,
            ),
            const SizedBox(height: 16),

            // ── Question Text ─────────────────────────
            _sectionTitle('প্রশ্ন *'),
            _inputField(
              controller: _questionController,
              hint: 'এখানে প্রশ্ন লিখুন...',
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'প্রশ্ন লিখুন' : null,
            ),
            const SizedBox(height: 16),

            // ── Options ───────────────────────────────
            _sectionTitle('অপশন *'),
            _optionField('A', _optionAController, color),
            _optionField('B', _optionBController, color),
            _optionField('C', _optionCController, color),
            _optionField('D', _optionDController, color),
            const SizedBox(height: 16),

            // ── Correct Option ────────────────────────
            _sectionTitle('সঠিক উত্তর *'),
            Row(
              children: ['A', 'B', 'C', 'D'].map((opt) {
                final isSelected = _correctOption == opt;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _correctOption = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Answer ────────────────────────────────
            _sectionTitle('সঠিক উত্তরের নাম *'),
            _inputField(
              controller: _answerController,
              hint: 'সংক্ষিপ্ত উত্তর...',
              validator: (v) => v!.isEmpty ? 'উত্তর লিখুন' : null,
            ),
            const SizedBox(height: 16),

            // ── Explanation ───────────────────────────
            _sectionTitle('ব্যাখ্যা *'),
            _inputField(
              controller: _explanationController,
              hint: 'বিস্তারিত ব্যাখ্যা লিখুন...',
              maxLines: 5,
              validator: (v) => v!.isEmpty ? 'ব্যাখ্যা লিখুন' : null,
            ),
            const SizedBox(height: 16),

            // ── Difficulty ────────────────────────────
            _sectionTitle('কঠিনতা'),
            Row(
              children: _difficultyOptions.map((d) {
                final isSelected = _difficulty == d;
                final dColor = d == 'easy'
                    ? Colors.green
                    : d == 'medium'
                    ? Colors.orange
                    : Colors.red;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _difficulty = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? dColor.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? dColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          d == 'easy'
                              ? 'সহজ'
                              : d == 'medium'
                              ? 'মাঝারি'
                              : 'কঠিন',
                          style: TextStyle(
                            color: isSelected ? dColor : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Tags ──────────────────────────────────
            _sectionTitle('Tags (comma separated)'),
            _inputField(
              controller: _tagsController,
              hint: 'ইতিহাস, মুঘল, আকবর',
            ),
            const SizedBox(height: 32),

            // ── Save Button ───────────────────────────
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(
                isNew ? 'প্রশ্ন যোগ করুন' : 'আপডেট করুন',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF37474F),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _optionField(
    String key,
    TextEditingController controller,
    Color color,
  ) {
    final isCorrect = _correctOption == key;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect ? color : Colors.grey.shade300,
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Key badge
          GestureDetector(
            onTap: () => setState(() => _correctOption = key),
            child: Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: isCorrect ? color : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  bottomLeft: Radius.circular(9),
                ),
              ),
              child: Center(
                child: Text(
                  key,
                  style: TextStyle(
                    color: isCorrect ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          // Text field
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: (v) => v!.isEmpty ? 'Option $key দিন' : null,
              decoration: InputDecoration(
                hintText: 'Option $key...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          // Correct indicator
          if (isCorrect)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle_rounded, color: color, size: 20),
            ),
        ],
      ),
    );
  }
}
