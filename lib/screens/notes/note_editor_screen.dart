import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:uuid/uuid.dart';
import '../../models/note_model.dart';
import 'package:hive/hive.dart';
import '../../theme.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Color _selectedColor = Colors.blueAccent;
  bool _isEdited = false;

  final List<Color> _quickColors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    if (widget.note != null) {
      _selectedColor = Color(widget.note!.colorValue);
    }
  }

  void _saveNote() {
    final box = Hive.box<NoteModel>('notes_box');
    final now = DateTime.now();

    if (widget.note == null) {
      // নতুন নোট
      final newNote = NoteModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        colorValue: _selectedColor.value,
        createdAt: now,
        updatedAt: now,
      );
      box.put(newNote.id, newNote);
    } else {
      // Update existing
      widget.note!.title = _titleController.text.trim();
      widget.note!.content = _contentController.text.trim();
      widget.note!.colorValue = _selectedColor.value;
      widget.note!.updatedAt = now;
      widget.note!.save();
    }

    Navigator.pop(context);
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('রং বেছে নিন', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick colors
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Full color picker
            ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() => _selectedColor = color);
              },
              pickerAreaHeightPercent: 0.5,
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: Text(
          widget.note == null ? 'New Note' : 'Edit Note',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Color picker button
          GestureDetector(
            onTap: _showColorPicker,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Save button
          TextButton.icon(
            onPressed: _saveNote,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Color indicator bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title field
            TextField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Title...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() => _isEdited = true),
            ),

            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 8),

            // Content field
            Expanded(
              child: TextField(
                controller: _contentController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'এখানে লিখুন...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() => _isEdited = true),
              ),
            ),
          ],
        ),
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
