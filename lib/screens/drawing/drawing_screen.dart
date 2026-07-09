import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme.dart';

// পরে (যোগ করুন):
import 'package:gal/gal.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final DrawingController _drawingController = DrawingController();
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isSaving = false;

  final List<Color> _colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Colors.cyan,
  ];

  // Color পরিবর্তন
  void _changeColor(Color color) {
    setState(() => _selectedColor = color);
    _drawingController.setStyle(color: color);
  }

  // Stroke width পরিবর্তন
  void _changeStrokeWidth(double width) {
    setState(() => _strokeWidth = width);
    _drawingController.setStyle(strokeWidth: width);
  }

  Future<void> _saveDrawing() async {
    setState(() => _isSaving = true);

    try {
      final Uint8List? imageData = (await _drawingController.getImageData())
          ?.buffer
          .asUint8List();

      if (imageData != null) {
        // Permission check
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }

        // Save to gallery
        await Gal.putImageBytes(
          imageData,
          album: 'drawing_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gallery-তে save হয়েছে!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  Future<bool> _requestPermission() async {
    if (await Permission.storage.isGranted) return true;
    if (await Permission.photos.isGranted) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    final photosStatus = await Permission.photos.request();
    return photosStatus.isGranted;
  }

  // Canvas clear
  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('সব মুছবেন?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Canvas সম্পূর্ণ পরিষ্কার হয়ে যাবে।',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _drawingController.clear();
            },
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Drawing Board',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Undo
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: () => _drawingController.undo(),
            tooltip: 'Undo',
          ),
          // Redo
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.white),
            onPressed: () => _drawingController.redo(),
            tooltip: 'Redo',
          ),
          // Clear
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _clearCanvas,
            tooltip: 'Clear All',
          ),
          // Save
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save_alt, color: Colors.greenAccent),
                  onPressed: _saveDrawing,
                  tooltip: 'Gallery-তে Save',
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Toolbar ─────────────────────────────────
          Container(
            color: AppTheme.primaryDark,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color picker row
                const Text(
                  'Color:',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _colors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => _changeColor(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          width: isSelected ? 32 : 26,
                          height: isSelected ? 32 : 26,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Stroke width row
                Row(
                  children: [
                    const Text(
                      'Size:',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        activeColor: _selectedColor,
                        inactiveColor: Colors.white24,
                        onChanged: _changeStrokeWidth,
                      ),
                    ),
                    // Preview dot
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3460),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: Container(
                          width: _strokeWidth.clamp(2, 24),
                          height: _strokeWidth.clamp(2, 24),
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Eraser button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeColor(Colors.white),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedColor == Colors.white
                              ? Colors.white
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cleaning_services_rounded,
                              size: 14,
                              color: _selectedColor == Colors.white
                                  ? Colors.black
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Eraser',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedColor == Colors.white
                                    ? Colors.black
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _changeColor(Colors.black),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedColor == Colors.black
                              ? Colors.black
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: _selectedColor == Colors.black
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pen',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedColor == Colors.black
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Drawing Canvas ───────────────────────────
          Expanded(
            child: DrawingBoard(
              controller: _drawingController,
              background: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }
}
