// frontend/lib/features/cahier/presentation/widgets/cahier_canvas.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cahier_provider.dart';

class CahierCanvas extends StatefulWidget {
  const CahierCanvas({super.key});

  @override
  State<CahierCanvas> createState() => _CahierCanvasState();
}

class _CahierCanvasState extends State<CahierCanvas> {
  Offset? _startPosition;
  Offset? _endPosition;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CahierProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onPanStart: (details) {
            _startPosition = details.localPosition;
            if (provider.currentTool == ToolType.pen ||
                provider.currentTool == ToolType.eraser) {
              provider.startDrawing(details.localPosition);
            }
          },
          onPanUpdate: (details) {
            if (provider.currentTool == ToolType.pen ||
                provider.currentTool == ToolType.eraser) {
              provider.continueDrawing(details.localPosition);
            }
            _endPosition = details.localPosition;
            setState(() {});
          },
          onPanEnd: (details) {
            if (provider.currentTool == ToolType.pen ||
                provider.currentTool == ToolType.eraser) {
              provider.endDrawing();
            } else if (provider.currentTool == ToolType.line ||
                provider.currentTool == ToolType.rectangle ||
                provider.currentTool == ToolType.circle) {
              if (_startPosition != null && _endPosition != null) {
                provider.addShape(_startPosition!, _endPosition!);
              }
            }
            _startPosition = null;
            _endPosition = null;
          },
          onTapDown: (details) {
            if (provider.currentTool == ToolType.select) {
              // Sélection d'un élément (simplifié)
              provider.clearSelection();
            }
          },
          child: CustomPaint(
            painter: _CanvasPainter(
              elements: provider.elements,
              currentElement: provider.currentElement,
              showGrid: provider.showGrid,
              isDark: isDark,
              startPosition: _startPosition,
              endPosition: _endPosition,
              currentTool: provider.currentTool,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({
    required this.elements,
    required this.currentElement,
    required this.showGrid,
    required this.isDark,
    required this.startPosition,
    required this.endPosition,
    required this.currentTool,
  });

  final List<DrawingElement> elements;
  final DrawingElement? currentElement;
  final bool showGrid;
  final bool isDark;
  final Offset? startPosition;
  final Offset? endPosition;
  final ToolType currentTool;

  @override
  void paint(Canvas canvas, Size size) {
    // Fond
    canvas.drawColor(
      isDark ? Colors.grey[900]! : Colors.white,
      BlendMode.srcOver,
    );

    // Lignes du cahier
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Dessiner tous les éléments
    for (var element in elements) {
      _drawElement(canvas, element);
    }

    // Dessiner l'élément en cours
    if (currentElement != null) {
      _drawElement(canvas, currentElement!);
    }

    // Aperçu des formes
    if (startPosition != null && endPosition != null && currentTool != ToolType.pen) {
      _drawShapePreview(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.blue.withOpacity(0.08);

    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Lignes horizontales (type cahier Seyès)
    for (double y = 0; y < size.height; y += 8) {
      final isMainLine = y % 40 == 0;
      paint.color = isMainLine
          ? (isDark ? Colors.white.withOpacity(0.1) : Colors.blue.withOpacity(0.15))
          : gridColor;
      paint.strokeWidth = isMainLine ? 1.5 : 1.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Lignes verticales (marges)
    paint.color = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.blue.withOpacity(0.05);
    paint.strokeWidth = 1.0;
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
    );

    // Marge gauche (type cahier)
    paint.color = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.blue.withOpacity(0.1);
    paint.strokeWidth = 2.0;
    canvas.drawLine(
      Offset(20, 0),
      Offset(20, size.height),
      paint,
    );

    // Marge droite
    paint.color = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.blue.withOpacity(0.1);
    paint.strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width - 20, 0),
      Offset(size.width - 20, size.height),
      paint,
    );
  }

  void _drawElement(Canvas canvas, DrawingElement element) {
    final paint = Paint()
      ..color = element.color
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = element.isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    switch (element.type) {
      case ToolType.pen:
      case ToolType.eraser:
        _drawPath(canvas, element.points, paint);
        break;
      case ToolType.line:
        if (element.points.length >= 2) {
          canvas.drawLine(element.points[0], element.points[1], paint);
        }
        break;
      case ToolType.rectangle:
        if (element.points.length >= 2) {
          final rect = Rect.fromPoints(element.points[0], element.points[1]);
          canvas.drawRect(rect, paint);
        }
        break;
      case ToolType.circle:
        if (element.points.length >= 2) {
          final center = Offset(
            (element.points[0].dx + element.points[1].dx) / 2,
            (element.points[0].dy + element.points[1].dy) / 2,
          );
          final radius = (element.points[0] - element.points[1]).distance / 2;
          canvas.drawCircle(center, radius, paint);
        }
        break;
      case ToolType.text:
        if (element.text != null && element.position != null) {
          final textSpan = TextSpan(
            text: element.text,
            style: TextStyle(
              color: element.color,
              fontSize: element.fontSize ?? 16,
              fontWeight: FontWeight.w500,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, element.position!);
        }
        break;
      default:
        break;
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawShapePreview(Canvas canvas) {
    if (startPosition == null || endPosition == null) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (currentTool) {
      case ToolType.line:
        canvas.drawLine(startPosition!, endPosition!, paint);
        break;
      case ToolType.rectangle:
        final rect = Rect.fromPoints(startPosition!, endPosition!);
        canvas.drawRect(rect, paint);
        break;
      case ToolType.circle:
        final center = Offset(
          (startPosition!.dx + endPosition!.dx) / 2,
          (startPosition!.dy + endPosition!.dy) / 2,
        );
        final radius = (startPosition! - endPosition!).distance / 2;
        canvas.drawCircle(center, radius, paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.elements != elements ||
        oldDelegate.currentElement != currentElement ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.startPosition != startPosition ||
        oldDelegate.endPosition != endPosition ||
        oldDelegate.currentTool != currentTool;
  }
}