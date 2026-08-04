// frontend/lib/features/cahier/providers/cahier_provider.dart

import 'package:flutter/material.dart';

enum ToolType { pen, eraser, line, rectangle, circle, text, select }

class DrawingElement {
  final String id;
  final ToolType type;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isFilled;
  final Offset? position;
  final String? text;
  final double? fontSize;

  DrawingElement({
    required this.id,
    required this.type,
    this.points = const [],
    this.color = Colors.black,
    this.strokeWidth = 3.0,
    this.isFilled = false,
    this.position,
    this.text,
    this.fontSize,
  });

  DrawingElement copyWith({
    String? id,
    ToolType? type,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isFilled,
    Offset? position,
    String? text,
    double? fontSize,
  }) {
    return DrawingElement(
      id: id ?? this.id,
      type: type ?? this.type,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isFilled: isFilled ?? this.isFilled,
      position: position ?? this.position,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class PageData {
  final String id;
  final List<DrawingElement> elements;
  final DateTime createdAt;

  PageData({
    required this.id,
    this.elements = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PageData copyWith({
    String? id,
    List<DrawingElement>? elements,
    DateTime? createdAt,
  }) {
    return PageData(
      id: id ?? this.id,
      elements: elements ?? this.elements,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CahierProvider extends ChangeNotifier {
  // ===== Gestion des pages =====
  List<PageData> _pages = [];
  int _currentPageIndex = 0;

  // ===== État du dessin =====
  ToolType _currentTool = ToolType.pen;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isFilled = false;
  bool _showGrid = true;

  // ===== Éléments de la page courante =====
  List<DrawingElement> _elements = [];
  List<DrawingElement> _selectedElements = [];
  DrawingElement? _currentElement;
  Offset? _startPosition;

  // ===== Historique =====
  List<List<DrawingElement>> _history = [];
  int _historyIndex = -1;

  // ===== Constructeur =====
  CahierProvider() {
    // Page par défaut
    _pages.add(PageData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    ));
    _currentPageIndex = 0;
  }

  // ===== Getters Pages =====
  List<PageData> get pages => _pages;
  int get currentPageIndex => _currentPageIndex;
  int get pageCount => _pages.length;
  bool get canAddPage => _pages.length < 100; // Limite de 100 pages
  bool get canDeletePage => _pages.length > 1;

  // ===== Getters État =====
  ToolType get currentTool => _currentTool;
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  bool get isFilled => _isFilled;
  bool get showGrid => _showGrid;
  bool get isEraser => _currentTool == ToolType.eraser;
  List<DrawingElement> get elements => _elements;
  List<DrawingElement> get selectedElements => _selectedElements;
  DrawingElement? get currentElement => _currentElement;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  // ===== Gestion des pages =====
  void addPage() {
    if (canAddPage) {
      // Sauvegarder la page courante
      _saveCurrentPage();
      
      final newPage = PageData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _pages.add(newPage);
      _currentPageIndex = _pages.length - 1;
      _loadPage(_currentPageIndex);
      notifyListeners();
    }
  }

  void deletePage(int index) {
    if (canDeletePage && index >= 0 && index < _pages.length) {
      _pages.removeAt(index);
      if (_currentPageIndex >= _pages.length) {
        _currentPageIndex = _pages.length - 1;
      }
      _loadPage(_currentPageIndex);
      notifyListeners();
    }
  }

  void goToPage(int index) {
    if (index >= 0 && index < _pages.length && index != _currentPageIndex) {
      // Sauvegarder la page courante
      _saveCurrentPage();
      _currentPageIndex = index;
      _loadPage(index);
      notifyListeners();
    }
  }

  void goToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      goToPage(_currentPageIndex + 1);
    }
  }

  void goToPreviousPage() {
    if (_currentPageIndex > 0) {
      goToPage(_currentPageIndex - 1);
    }
  }

  void _saveCurrentPage() {
    if (_currentPageIndex >= 0 && _currentPageIndex < _pages.length) {
      _pages[_currentPageIndex] = _pages[_currentPageIndex].copyWith(
        elements: List.from(_elements),
      );
    }
  }

  void _loadPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _elements = List.from(_pages[index].elements);
      _selectedElements.clear();
      _currentElement = null;
      _history.clear();
      _historyIndex = -1;
      notifyListeners();
    }
  }

  // ===== Actions de dessin =====
  void setTool(ToolType tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void toggleFilled() {
    _isFilled = !_isFilled;
    notifyListeners();
  }

  void toggleGrid() {
    _showGrid = !_showGrid;
    notifyListeners();
  }

  void toggleEraser() {
    if (_currentTool == ToolType.eraser) {
      _currentTool = ToolType.pen;
    } else {
      _currentTool = ToolType.eraser;
    }
    notifyListeners();
  }

  void clearCanvas() {
    _elements.clear();
    _selectedElements.clear();
    _currentElement = null;
    _saveHistory();
    _saveCurrentPage();
    notifyListeners();
  }

  void clearAll() {
    _elements.clear();
    _selectedElements.clear();
    _currentElement = null;
    _saveHistory();
    _saveCurrentPage();
    notifyListeners();
  }

  void startDrawing(Offset position) {
    _startPosition = position;
    _currentElement = DrawingElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _currentTool,
      points: [position],
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      isFilled: _isFilled,
    );
  }

  void continueDrawing(Offset position) {
    if (_currentElement != null) {
      _currentElement!.points.add(position);
      notifyListeners();
    }
  }

  void endDrawing() {
    if (_currentElement != null && _currentElement!.points.isNotEmpty) {
      _elements.add(_currentElement!);
      _saveHistory();
      _saveCurrentPage();
      _currentElement = null;
      _startPosition = null;
      notifyListeners();
    }
  }

  void addShape(Offset position, Offset endPosition) {
    final element = DrawingElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _currentTool,
      points: [position, endPosition],
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      isFilled: _isFilled,
    );
    _elements.add(element);
    _saveHistory();
    _saveCurrentPage();
    notifyListeners();
  }

  void addText(Offset position, String text, double fontSize) {
    final element = DrawingElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: ToolType.text,
      position: position,
      color: _selectedColor,
      text: text,
      fontSize: fontSize,
    );
    _elements.add(element);
    _saveHistory();
    _saveCurrentPage();
    notifyListeners();
  }

  void deleteSelected() {
    if (_selectedElements.isNotEmpty) {
      _elements.removeWhere((e) => _selectedElements.contains(e));
      _selectedElements.clear();
      _saveHistory();
      _saveCurrentPage();
      notifyListeners();
    }
  }

  void selectElement(DrawingElement element) {
    if (_selectedElements.contains(element)) {
      _selectedElements.remove(element);
    } else {
      _selectedElements.add(element);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedElements.clear();
    notifyListeners();
  }

  // ===== Historique =====
  void _saveHistory() {
    if (_historyIndex < _history.length - 1) {
      _history = _history.sublist(0, _historyIndex + 1);
    }
    _history.add(List.from(_elements));
    _historyIndex = _history.length - 1;
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void undo() {
    if (canUndo) {
      _historyIndex--;
      _elements = List.from(_history[_historyIndex]);
      _selectedElements.clear();
      _saveCurrentPage();
      notifyListeners();
    }
  }

  void redo() {
    if (canRedo) {
      _historyIndex++;
      _elements = List.from(_history[_historyIndex]);
      _selectedElements.clear();
      _saveCurrentPage();
      notifyListeners();
    }
  }

  void reset() {
    _elements.clear();
    _selectedElements.clear();
    _currentElement = null;
    _history.clear();
    _historyIndex = -1;
    _saveCurrentPage();
    notifyListeners();
  }
}