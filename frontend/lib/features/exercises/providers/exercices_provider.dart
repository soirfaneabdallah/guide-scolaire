// frontend/lib/features/exercices/providers/exercices_provider.dart

import 'package:flutter/material.dart';
import '../data/models/exercice.dart';

class ExercicesProvider extends ChangeNotifier {
  // Données
  List<Exercice> _allExercices = [];
  List<Exercice> _filteredExercices = [];

  // Filtres
  String _selectedSubject = 'Toutes';
  String _selectedLevel = 'Tous';
  String _selectedDifficulty = 'Toutes';
  String _searchQuery = '';

  // État
  Exercice? _selectedExercice;
  bool _isLoading = true;

  // Getters
  List<Exercice> get exercices => _filteredExercices;
  List<Exercice> get allExercices => _allExercices;
  Exercice? get selectedExercice => _selectedExercice;
  bool get isLoading => _isLoading;
  bool get hasExercices => _filteredExercices.isNotEmpty;

  String get selectedSubject => _selectedSubject;
  String get selectedLevel => _selectedLevel;
  String get selectedDifficulty => _selectedDifficulty;
  String get searchQuery => _searchQuery;

  // Statistiques
  int get totalExercices => _allExercices.length;
  int get completedExercices =>
      _allExercices.where((e) => e.isCompleted).length;
  int get inProgressExercices =>
      _allExercices.where((e) => e.status == ExerciceStatus.in_progress).length;
  double get completionRate =>
      totalExercices > 0 ? completedExercices / totalExercices : 0;

  // Options de filtrage
  List<String> get subjects {
    final subjects = _allExercices.map((e) => e.subject).toSet().toList();
    subjects.sort();
    return ['Toutes', ...subjects];
  }

  List<String> get levels {
    final levels = _allExercices.map((e) => e.level).toSet().toList();
    levels.sort((a, b) {
      final order = ['6ème', '5ème', '4ème', '3ème', 'Seconde', 'Première', 'Terminale'];
      return order.indexOf(a).compareTo(order.indexOf(b));
    });
    return ['Tous', ...levels];
  }

  List<String> get difficulties => ['Toutes', 'Facile', 'Moyen', 'Difficile'];

  // ===== Initialisation =====
  Future<void> loadExercices() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Appel API pour récupérer les exercices
      // Pour l'instant, données simulées
      await Future.delayed(const Duration(seconds: 1));
      _allExercices = _getMockExercices();
      _applyFilters();
    } catch (e) {
      debugPrint('Erreur lors du chargement des exercices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== Filtres =====
  void setSubject(String subject) {
    _selectedSubject = subject;
    _applyFilters();
  }

  void setLevel(String level) {
    _selectedLevel = level;
    _applyFilters();
  }

  void setDifficulty(String difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void resetFilters() {
    _selectedSubject = 'Toutes';
    _selectedLevel = 'Tous';
    _selectedDifficulty = 'Toutes';
    _searchQuery = '';
    _applyFilters();
  }

  void _applyFilters() {
    _filteredExercices = _allExercices.where((exercice) {
      // Filtre matière
      if (_selectedSubject != 'Toutes' && exercice.subject != _selectedSubject) {
        return false;
      }

      // Filtre niveau
      if (_selectedLevel != 'Tous' && exercice.level != _selectedLevel) {
        return false;
      }

      // Filtre difficulté
      if (_selectedDifficulty != 'Toutes' &&
          exercice.difficultyLabel != _selectedDifficulty) {
        return false;
      }

      // Filtre recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = exercice.title.toLowerCase().contains(query);
        final descMatch = exercice.description.toLowerCase().contains(query);
        final subjectMatch = exercice.subject.toLowerCase().contains(query);
        if (!titleMatch && !descMatch && !subjectMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Trier par statut (en cours d'abord)
    _filteredExercices.sort((a, b) {
      if (a.status == ExerciceStatus.in_progress && b.status != ExerciceStatus.in_progress) {
        return -1;
      }
      if (b.status == ExerciceStatus.in_progress && a.status != ExerciceStatus.in_progress) {
        return 1;
      }
      return 0;
    });

    notifyListeners();
  }

  // ===== Sélection =====
  void selectExercice(String id) {
    _selectedExercice = _allExercices.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('Exercice non trouvé'),
    );
    notifyListeners();
  }

  void clearSelectedExercice() {
    _selectedExercice = null;
    notifyListeners();
  }

  // ===== Données simulées =====
  List<Exercice> _getMockExercices() {
    return [
      Exercice(
        id: '1',
        title: 'Résolution d\'équation du premier degré',
        subject: 'Mathématiques',
        subjectSlug: 'mathematiques',
        description:
            'Résoudre des équations du type ax + b = c. Exercice d\'algèbre de base.',
        question:
            'Résoudre les équations suivantes :\n1) 2x + 3 = 7\n2) 5x - 2 = 13\n3) 3x + 4 = 2x - 1',
        correction: '1) x = 2\n2) x = 3\n3) x = -5',
        hints: ['Isole le terme en x', 'Pense à équilibrer les deux membres'],
        difficulty: ExerciceDifficulty.easy,
        level: '4ème',
        points: 10,
        timeLimit: 300,
        status: ExerciceStatus.in_progress,
      ),
      Exercice(
        id: '2',
        title: 'Théorème de Pythagore',
        subject: 'Mathématiques',
        subjectSlug: 'mathematiques',
        description:
            'Utiliser le théorème de Pythagore pour calculer des longueurs dans un triangle rectangle.',
        question:
            'Dans un triangle rectangle ABC, rectangle en A, AB = 3 cm et AC = 4 cm.\nCalculer la longueur BC.',
        correction: 'BC = 5 cm (3² + 4² = 9 + 16 = 25, √25 = 5)',
        hints: ['Utilise la formule a² + b² = c²', 'Identifie l\'hypoténuse'],
        difficulty: ExerciceDifficulty.easy,
        level: '4ème',
        points: 15,
        timeLimit: 360,
        isCompleted: true,
        status: ExerciceStatus.completed,
        successRate: 0.85,
        lastAttempt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Exercice(
        id: '3',
        title: 'Conjugaison des verbes du premier groupe',
        subject: 'Français',
        subjectSlug: 'francais',
        description:
            'Conjuguer les verbes du premier groupe aux temps de l\'indicatif.',
        question:
            'Conjuguez le verbe "manger" au passé composé, à toutes les personnes.',
        correction: 'j\'ai mangé, tu as mangé, il/elle/on a mangé...',
        hints: ['N\'oublie pas l\'auxiliaire avoir', 'Le participe passé se termine par -é'],
        difficulty: ExerciceDifficulty.medium,
        level: '5ème',
        points: 20,
        timeLimit: 480,
        status: ExerciceStatus.not_started,
      ),
      Exercice(
        id: '4',
        title: 'Loi d\'Ohm',
        subject: 'Physique-Chimie',
        subjectSlug: 'physique',
        description: 'Application de la loi d\'Ohm dans un circuit électrique.',
        question:
            'Un circuit électrique contient une résistance de 220 Ω traversée par un courant de 0,5 A.\nQuelle est la tension aux bornes de la résistance ?',
        correction: 'U = R × I = 220 × 0,5 = 110 V',
        hints: ['Utilise la formule U = R × I', 'Les unités doivent être cohérentes'],
        difficulty: ExerciceDifficulty.medium,
        level: '3ème',
        points: 20,
        timeLimit: 420,
        status: ExerciceStatus.in_progress,
      ),
      Exercice(
        id: '5',
        title: 'Analyser une phrase complexe',
        subject: 'Français',
        subjectSlug: 'francais',
        description: 'Identifier les propositions dans une phrase complexe.',
        question:
            'Analyse la phrase suivante :\n"Le chat que j\'ai adopté est très joueur et il aime courir dans le jardin."',
        correction: 'Phrase complexe avec 3 propositions...',
        hints: ['Identifie les verbes conjugués', 'Les propositions sont reliées par des connecteurs'],
        difficulty: ExerciceDifficulty.hard,
        level: 'Seconde',
        points: 30,
        timeLimit: 600,
        status: ExerciceStatus.not_started,
      ),
      Exercice(
        id: '6',
        title: 'La digestion',
        subject: 'SVT',
        subjectSlug: 'svt',
        description: 'Comprendre le processus de digestion des aliments.',
        question:
            'Décris le trajet des aliments dans le tube digestif et les principales étapes de la digestion.',
        correction:
            'Le trajet des aliments commence par la bouche, puis le pharynx, l\'œsophage, l\'estomac...',
        hints: [
          'Commence par la bouche',
          'Il y a plusieurs organes impliqués',
        ],
        difficulty: ExerciceDifficulty.medium,
        level: '5ème',
        points: 15,
        timeLimit: 360,
        isCompleted: true,
        status: ExerciceStatus.completed,
        successRate: 0.75,
        lastAttempt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}