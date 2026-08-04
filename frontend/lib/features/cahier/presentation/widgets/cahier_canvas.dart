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
  List<Map<String, dynamic>> _paths = [];
  Map<String, dynamic>? _currentPath;

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
            final localPosition = details.localPosition;
            _currentPath = {
              'points': [localPosition],
              'color': provider.selectedColor.value,
              'strokeWidth': provider.strokeWidth,
              'isEraser': provider.isEraser,
            };
          },
          onPanUpdate: (details) {
            if (_currentPath != null) {
              (_currentPath!['points'] as List).add(details.localPosition);
              setState(() {});
            }
          },
          onPanEnd: (details) {
            if (_currentPath != null) {
              setState(() {
                _paths.add(_currentPath!);
                _currentPath = null;
              });
              // Sauvegarder pour l'historique
              provider.addToHistory({
                'paths': List.from(_paths),
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
            }
          },
          child: CustomPaint(
            painter: _CanvasPainter(
              paths: _paths,
              currentPath: _currentPath,
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
    required this.paths,
    required this.currentPath,
  });

  final List<Map<String, dynamic>> paths;
  final Map<String, dynamic>? currentPath;

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner les chemins existants
    for (var pathData in paths) {
      _drawPath(canvas, pathData);
    }

    // Dessiner le chemin actuel
    if (currentPath != null) {
      _drawPath(canvas, currentPath!);
    }
  }

  void _drawPath(Canvas canvas, Map<String, dynamic> pathData) {
    final points = pathData['points'] as List<Offset>;
    if (points.isEmpty) return;

    final color = Color(pathData['color'] as int);
    final strokeWidth = pathData['strokeWidth'] as double;
    final isEraser = pathData['isEraser'] as bool;

    final paint = Paint()
      ..color = isEraser ? Colors.transparent : color
      ..strokeWidth = isEraser ? 30.0 : strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.paths != paths || oldDelegate.currentPath != currentPath;
  }
}