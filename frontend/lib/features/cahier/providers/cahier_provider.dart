// frontend/lib/features/cahier/providers/cahier_provider.dart

import 'package:flutter/material.dart';

class CahierProvider extends ChangeNotifier {
  // ===== État du dessin =====
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;

  // ===== Historique =====
  List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;

  // ===== Getters =====
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  bool get isEraser => _isEraser;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  // ===== Actions =====
  void setColor(Color color) {
    _selectedColor = color;
    _isEraser = false;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void toggleEraser() {
    _isEraser = !_isEraser;
    notifyListeners();
  }

  void clearCanvas() {
    _history.clear();
    _historyIndex = -1;
    notifyListeners();
  }

  void addToHistory(Map<String, dynamic> state) {
    // Supprimer les états futurs si on est au milieu
    if (_historyIndex < _history.length - 1) {
      _history = _history.sublist(0, _historyIndex + 1);
    }
    _history.add(state);
    _historyIndex = _history.length - 1;
    notifyListeners();
  }

  void undo() {
    if (canUndo) {
      _historyIndex--;
      notifyListeners();
    }
  }

  void redo() {
    if (canRedo) {
      _historyIndex++;
      notifyListeners();
    }
  }

  Map<String, dynamic>? getCurrentState() {
    if (_historyIndex >= 0 && _historyIndex < _history.length) {
      return _history[_historyIndex];
    }
    return null;
  }

  // ===== Reset =====
  void reset() {
    _selectedColor = Colors.black;
    _strokeWidth = 3.0;
    _isEraser = false;
    _history.clear();
    _historyIndex = -1;
    notifyListeners();
  }
}