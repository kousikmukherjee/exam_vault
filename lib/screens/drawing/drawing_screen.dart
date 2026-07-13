import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

// ─── Drawing Point Model ────────────────────────────
class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint(this.offset, this.paint);
}

// ─── Shape Type ─────────────────────────────────────
enum ShapeType { pen, line, rectangle, circle, eraser }

// ─── Drawing Action (for undo) ───────────────────────
class DrawingAction {
  final ShapeType shapeType;
  final List<DrawingPoint> points;
  final Offset? startPoint;
  final Offset? endPoint;
  final Paint paint;

  DrawingAction({
    required this.shapeType,
    required this.points,
    required this.paint,
    this.startPoint,
    this.endPoint,
  });
}

// ─── Custom Painter ──────────────────────────────────
class DrawingPainter extends CustomPainter {
  final List<DrawingAction> actions;
  final DrawingAction? currentAction;

  DrawingPainter({required this.actions, this.currentAction});

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw completed actions
    for (final action in actions) {
      _drawAction(canvas, action);
    }

    // Draw current action (live preview)
    if (currentAction != null) {
      _drawAction(canvas, currentAction!);
    }
  }

  void _drawAction(Canvas canvas, DrawingAction action) {
    switch (action.shapeType) {
      case ShapeType.pen:
      case ShapeType.eraser:
        for (int i = 0; i < action.points.length - 1; i++) {
          canvas.drawLine(
            action.points[i].offset,
            action.points[i + 1].offset,
            action.points[i].paint,
          );
        }
        if (action.points.length == 1) {
          canvas.drawCircle(
            action.points[0].offset,
            action.points[0].paint.strokeWidth / 2,
            action.points[0].paint,
          );
        }
        break;

      case ShapeType.line:
        if (action.startPoint != null && action.endPoint != null) {
          canvas.drawLine(action.startPoint!, action.endPoint!, action.paint);
        }
        break;

      case ShapeType.rectangle:
        if (action.startPoint != null && action.endPoint != null) {
          canvas.drawRect(
            Rect.fromPoints(action.startPoint!, action.endPoint!),
            action.paint,
          );
        }
        break;

      case ShapeType.circle:
        if (action.startPoint != null && action.endPoint != null) {
          canvas.drawOval(
            Rect.fromPoints(action.startPoint!, action.endPoint!),
            action.paint,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

// ─── Main Drawing Screen ─────────────────────────────
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  // Drawing state
  final List<DrawingAction> _actions = [];
  DrawingAction? _currentAction;
  Offset? _startPoint;

  // Tool state
  ShapeType _selectedShape = ShapeType.pen;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isSaving = false;

  // Colors
  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.yellow,
    Colors.brown,
    Colors.cyan,
    Colors.indigo,
  ];

  // Build paint
  Paint _buildPaint() {
    return Paint()
      ..color = _selectedShape == ShapeType.eraser
          ? Colors.white
          : _selectedColor
      ..strokeWidth = _selectedShape == ShapeType.eraser
          ? _strokeWidth * 3
          : _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style =
          (_selectedShape == ShapeType.rectangle ||
              _selectedShape == ShapeType.circle)
          ? PaintingStyle.stroke
          : PaintingStyle.fill;
  }

  // ── Touch handlers ───────────────────────────────
  void _onPanStart(DragStartDetails details) {
    final paint = _buildPaint();
    _startPoint = details.localPosition;

    if (_selectedShape == ShapeType.pen || _selectedShape == ShapeType.eraser) {
      _currentAction = DrawingAction(
        shapeType: _selectedShape,
        points: [DrawingPoint(details.localPosition, paint)],
        paint: paint,
      );
    } else {
      _currentAction = DrawingAction(
        shapeType: _selectedShape,
        points: [],
        paint: paint,
        startPoint: _startPoint,
        endPoint: _startPoint,
      );
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentAction == null) return;

    if (_selectedShape == ShapeType.pen || _selectedShape == ShapeType.eraser) {
      final paint = _buildPaint();
      setState(() {
        _currentAction = DrawingAction(
          shapeType: _currentAction!.shapeType,
          points: [
            ..._currentAction!.points,
            DrawingPoint(details.localPosition, paint),
          ],
          paint: paint,
        );
      });
    } else {
      setState(() {
        _currentAction = DrawingAction(
          shapeType: _currentAction!.shapeType,
          points: [],
          paint: _currentAction!.paint,
          startPoint: _startPoint,
          endPoint: details.localPosition,
        );
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentAction != null) {
      setState(() {
        _actions.add(_currentAction!);
        _currentAction = null;
        _startPoint = null;
      });
    }
  }

  // ── Undo ────────────────────────────────────────
  void _undo() {
    if (_actions.isNotEmpty) {
      setState(() => _actions.removeLast());
    }
  }

  // ── Clear ───────────────────────────────────────
  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('সব মুছবেন?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Canvas সম্পূর্ণ পরিষ্কার হবে।',
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
              setState(() => _actions.clear());
            },
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Save to gallery ──────────────────────────────
  Future<void> _saveDrawing() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Canvas not found');
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) await Gal.requestAccess();
        await Gal.putImageBytes(pngBytes);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        automaticallyImplyLeading: false,
        title: const Text(
          'Drawing Board',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Undo
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: _actions.isNotEmpty ? _undo : null,
            tooltip: 'Undo',
          ),
          // Clear
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _clearCanvas,
            tooltip: 'Clear',
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
                  tooltip: 'Save',
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Toolbar ────────────────────────────────
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shape tools
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ShapeButton(
                        icon: Icons.edit_rounded,
                        label: 'Pen',
                        isSelected: _selectedShape == ShapeType.pen,
                        onTap: () =>
                            setState(() => _selectedShape = ShapeType.pen),
                      ),
                      _ShapeButton(
                        icon: Icons.remove,
                        label: 'Line',
                        isSelected: _selectedShape == ShapeType.line,
                        onTap: () =>
                            setState(() => _selectedShape = ShapeType.line),
                      ),
                      _ShapeButton(
                        icon: Icons.crop_square_rounded,
                        label: 'Rect',
                        isSelected: _selectedShape == ShapeType.rectangle,
                        onTap: () => setState(
                          () => _selectedShape = ShapeType.rectangle,
                        ),
                      ),
                      _ShapeButton(
                        icon: Icons.circle_outlined,
                        label: 'Circle',
                        isSelected: _selectedShape == ShapeType.circle,
                        onTap: () =>
                            setState(() => _selectedShape = ShapeType.circle),
                      ),
                      _ShapeButton(
                        icon: Icons.cleaning_services_rounded,
                        label: 'Eraser',
                        isSelected: _selectedShape == ShapeType.eraser,
                        onTap: () =>
                            setState(() => _selectedShape = ShapeType.eraser),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Color row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _colors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          width: isSelected ? 32 : 26,
                          height: isSelected ? 32 : 26,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white30,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Stroke size
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
                        onChanged: (val) => setState(() => _strokeWidth = val),
                      ),
                    ),
                    // Preview dot
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Center(
                        child: Container(
                          width: _strokeWidth.clamp(1.0, 26.0),
                          height: _strokeWidth.clamp(1.0, 26.0),
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Canvas ─────────────────────────────────
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: DrawingPainter(
                    actions: _actions,
                    currentAction: _currentAction,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shape Button Widget ─────────────────────────────
class _ShapeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShapeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
