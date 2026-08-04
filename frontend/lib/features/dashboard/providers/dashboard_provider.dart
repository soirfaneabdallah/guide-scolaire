// frontend/lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import '../../chat/domain/entities/message.dart';

// Model des matières (pour la base de données)
class Subject {
  final int id;
  final String name;
  final String slug;
  final String? iconName;
  final String? colorHex;

  Subject({
    required this.id,
    required this.name,
    required this.slug,
    this.iconName,
    this.colorHex,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      iconName: json['icon'],
      colorHex: json['color'],
    );
  }

  Color get color => colorHex != null 
      ? Color(int.parse(colorHex!.replaceFirst('#', '0xFF')))
      : const Color(0xFF2E7D32);
}

class DashboardProvider extends ChangeNotifier {
  DashboardProvider() {
    // Pour l'instant, données statiques
    // Plus tard, on chargera depuis l'API
    _subjects = [
      Subject(id: 1, name: 'Mathématiques', slug: 'mathematiques'),
      Subject(id: 2, name: 'Français', slug: 'francais'),
      Subject(id: 3, name: 'Physique-Chimie', slug: 'physique'),
      Subject(id: 4, name: 'SVT', slug: 'svt'),
      Subject(id: 5, name: 'Histoire-Géographie', slug: 'histoire'),
      Subject(id: 6, name: 'Anglais', slug: 'anglais'),
    ];

    _subjectChats = {
      for (var s in _subjects) s.slug: [],
    };
  }

  // Données
  List<Subject> _subjects = [];
  int _selectedIndex = 0;           // 0=accueil, 1=cours, 2=exercices, 3=cahier
  String _selectedSubjectSlug = ''; // Slug de la matière sélectionnée
  Map<String, List<Message>> _subjectChats = {};

  // Getters
  List<Subject> get subjects => _subjects;
  int get selectedIndex => _selectedIndex;
  String get selectedSubjectSlug => _selectedSubjectSlug.isNotEmpty 
      ? _selectedSubjectSlug 
      : (_subjects.isNotEmpty ? _subjects.first.slug : '');
  Subject? get selectedSubject {
    try {
      return _subjects.firstWhere((s) => s.slug == selectedSubjectSlug);
    } catch (_) {
      return _subjects.isNotEmpty ? _subjects.first : null;
    }
  }

  // Méthodes
  void selectTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void selectSubject(String slug) {
    _selectedSubjectSlug = slug;
    _selectedIndex = 0;
    notifyListeners();
  }

  List<Message> getMessagesForSubject(String slug) {
    return _subjectChats[slug] ?? [];
  }

  void addMessage(String slug, Message message) {
    if (_subjectChats.containsKey(slug)) {
      _subjectChats[slug]!.add(message);
      notifyListeners();
    }
  }

  void clearSubjectHistory(String slug) {
    if (_subjectChats.containsKey(slug)) {
      _subjectChats[slug] = [];
      notifyListeners();
    }
  }

  // Pour l'avenir : charger depuis l'API
  Future<void> loadSubjectsFromApi() async {
    // TODO: Appel API GET /subjects
    // Puis mettre à jour _subjects et _subjectChats
  }
}