import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../models/note_model.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Color _noteColor = const Color(0xFF1E3A5F); // dark blue default

  // Note background colors
  final List<Map<String, dynamic>> _colorOptions = [
    {'color': const Color(0xFF1E3A5F), 'name': 'Blue'},
    {'color': const Color(0xFF1B4332), 'name': 'Green'},
    {'color': const Color(0xFF3D1A24), 'name': 'Red'},
    {'color': const Color(0xFF2D1B69), 'name': 'Purple'},
    {'color': const Color(0xFF3D2B00), 'name': 'Brown'},
    {'color': const Color(0xFF0D3D3D), 'name': 'Teal'},
    {'color': const Color(0xFF2C2C2C), 'name': 'Dark'},
    {'color': const Color(0xFF1A1A2E), 'name': 'Navy'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    if (widget.note != null) {
      _noteColor = Color(widget.note!.colorValue);
    }
  }

  void _saveNote() {
    final box = Hive.box<NoteModel>('notes_box');
    final now = DateTime.now();

    if (widget.note == null) {
      final newNote = NoteModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        colorValue: _noteColor.value,
        createdAt: now,
        updatedAt: now,
      );
      box.put(newNote.id, newNote);
    } else {
      widget.note!.title = _titleController.text.trim();
      widget.note!.content = _contentController.text.trim();
      widget.note!.colorValue = _noteColor.value;
      widget.note!.updatedAt = now;
      widget.note!.save();
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _noteColor,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Note', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton.icon(
            onPressed: _saveNote,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Color selector ───────────────────────────
          Container(
            height: 56,
            color: Colors.black26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _colorOptions.map((item) {
                final color = item['color'] as Color;
                final isSelected = _noteColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _noteColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white38,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Title field ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(
                  color: Colors.white38,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Divider(color: Colors.white.withOpacity(0.2), height: 1),
          ),

          // ── Content field ────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: TextField(
                controller: _contentController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.7,
                ),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'এখানে লিখুন...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
