// frontend/lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../chat/domain/entities/message.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/icon_utils.dart';

// ============================================================
//  MODÈLE MATIÈRE
// ============================================================

class Subject {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final bool isDefault;
  final bool isActive;

  Subject({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.isDefault = false,
    this.isActive = true,
  });

  String get displayName => name;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? json['name']?.toLowerCase().replaceAll(' ', '_') ?? '',
      icon: json['icon'],
      color: json['color'],
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'is_active': isActive,
    };
  }

  Subject copyWith({
    int? id,
    String? name,
    String? slug,
    String? icon,
    String? color,
    bool? isDefault,
    bool? isActive,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }

  Color get colorValue => color != null
      ? Color(int.parse(color!.replaceFirst('#', '0xFF')))
      : const Color(0xFF2E7D32);
}

// ============================================================
//  PROVIDER
// ============================================================

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({this.apiClient});

  final ApiClient? apiClient;

  List<Subject> _subjects = [];
  int _selectedIndex = 0;
  String _selectedSubjectSlug = '';
  Map<String, List<Message>> _subjectChats = {};
  bool _isLoading = false;
  String? _error;

  // ============================================================
  //  GETTERS
  // ============================================================

  List<Subject> get subjects => _subjects;
  int get selectedIndex => _selectedIndex;
  String get selectedSubjectSlug => _selectedSubjectSlug.isNotEmpty
      ? _selectedSubjectSlug
      : (_subjects.isNotEmpty ? _subjects.first.slug : '');
  
  Subject? get selectedSubject {
    if (_selectedSubjectSlug.isNotEmpty) {
      try {
        return _subjects.firstWhere((s) => s.slug == _selectedSubjectSlug);
      } catch (_) {
        return _subjects.isNotEmpty ? _subjects.first : null;
      }
    }
    return _subjects.isNotEmpty ? _subjects.first : null;
  }
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================
  //  NORMALISATION DES SLUGS
  // ============================================================

  String _normalizeSlug(String slug) {
    if (slug.isEmpty) return '';
    return slug
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll(' ', '_');
  }

  // ============================================================
  //  MÉTHODES DE NAVIGATION
  // ============================================================

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
    final normalizedSlug = _normalizeSlug(slug);
    return _subjectChats[normalizedSlug] ?? [];
  }

  void addMessage(String slug, Message message) {
    final normalizedSlug = _normalizeSlug(slug);
    if (!_subjectChats.containsKey(normalizedSlug)) {
      _subjectChats[normalizedSlug] = [];
    }
    _subjectChats[normalizedSlug]!.add(message);
    notifyListeners();
  }

  void clearSubjectHistory(String slug) {
    final normalizedSlug = _normalizeSlug(slug);
    if (_subjectChats.containsKey(normalizedSlug)) {
      _subjectChats[normalizedSlug] = [];
      notifyListeners();
    }
  }

  // ============================================================
  //  CHARGEMENT DES MATIÈRES
  // ============================================================

  Future<void> loadSubjects() async {
    if (apiClient == null) {
      _loadMockSubjects();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient!.get('/subjects/me');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> defaultSubjects = data['default_subjects'] ?? [];
        final List<dynamic> customSubjects = data['custom_subjects'] ?? [];

        List<Subject> loadedSubjects = [];

        for (var item in defaultSubjects) {
          loadedSubjects.add(Subject.fromJson(item));
        }

        for (var item in customSubjects) {
          final subjectData = item['subject'] as Map<String, dynamic>;
          loadedSubjects.add(Subject(
            id: subjectData['id'] ?? 0,
            name: item['custom_name'] ?? subjectData['name'] ?? '',
            slug: subjectData['slug'] ?? subjectData['name']?.toLowerCase().replaceAll(' ', '_') ?? '',
            icon: item['custom_icon'] ?? subjectData['icon'],
            color: item['custom_color'] ?? subjectData['color'],
            isDefault: false,
            isActive: item['is_active'] ?? true,
          ));
        }

        _subjects = loadedSubjects;

        _subjectChats = {
          for (var s in _subjects) _normalizeSlug(s.slug): [],
        };

        if (_selectedSubjectSlug.isEmpty && _subjects.isNotEmpty) {
          _selectedSubjectSlug = _subjects.first.slug;
        }

        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Erreur lors du chargement des matières';
        _isLoading = false;
        notifyListeners();
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      _loadMockSubjects();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      _loadMockSubjects();
    }
  }

  void _loadMockSubjects() {
    _subjects = [
      Subject(id: 1, name: 'Mathématiques', slug: 'mathematiques', icon: '📐', color: '#4CAF50', isDefault: true),
      Subject(id: 2, name: 'Français', slug: 'francais', icon: '📖', color: '#2196F3', isDefault: true),
      Subject(id: 3, name: 'Physique-Chimie', slug: 'physique', icon: '⚡', color: '#FF9800', isDefault: true),
      Subject(id: 4, name: 'SVT', slug: 'svt', icon: '🧬', color: '#9C27B0', isDefault: true),
      Subject(id: 5, name: 'Histoire-Géographie', slug: 'histoire', icon: '🏛️', color: '#795548', isDefault: true),
      Subject(id: 6, name: 'Anglais', slug: 'anglais', icon: '🗣️', color: '#F44336', isDefault: true),
    ];

    _subjectChats = {
      for (var s in _subjects) _normalizeSlug(s.slug): [],
    };

    if (_selectedSubjectSlug.isEmpty && _subjects.isNotEmpty) {
      _selectedSubjectSlug = _subjects.first.slug;
    }

    notifyListeners();
  }

  // ============================================================
  //  CHARGEMENT DE L'HISTORIQUE
  // ============================================================

  Future<void> loadChatHistory(int subjectId) async {
    if (apiClient == null) return;
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient!.get('/chat/history/$subjectId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List messages = data['messages'] ?? [];
        final String subjectSlug = data['subject_slug'] ?? '';
        
        final normalizedSlug = _normalizeSlug(subjectSlug);
        
        final List<Message> chatMessages = messages.map((m) {
          return Message(
            id: m['id'].toString(),
            content: m['content'] ?? '',
            isUser: m['is_user'] ?? true,
            timestamp: m['created_at'] != null 
                ? DateTime.parse(m['created_at']) 
                : DateTime.now(),
            isError: m['is_error'] ?? false,
          );
        }).toList();

        _subjectChats[normalizedSlug] = chatMessages;
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Erreur lors du chargement de l\'historique';
        _isLoading = false;
        notifyListeners();
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshChatHistory(int subjectId) async {
    if (apiClient == null) return;

    final subject = _subjects.firstWhere((s) => s.id == subjectId, orElse: () => _subjects.first);
    final normalizedSlug = _normalizeSlug(subject.slug);
    _subjectChats[normalizedSlug] = [];
    
    await loadChatHistory(subjectId);
  }

  // ============================================================
  //  GESTION DES MATIÈRES (CRUD)
  // ============================================================

  // ✅ CRÉER UNE NOUVELLE MATIÈRE
  Future<bool> createSubject({
    required String name,
    String? icon,
    String? color,
  }) async {
    if (apiClient == null) {
      // Mode hors ligne
      final newSubject = Subject(
        id: _subjects.length + 100,
        name: name,
        slug: _normalizeSlug(name),
        icon: icon ?? '📚',
        color: color ?? '#4CAF50',
        isDefault: false,
        isActive: true,
      );
      _subjects.add(newSubject);
      _subjectChats[_normalizeSlug(newSubject.slug)] = [];
      notifyListeners();
      return true;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await apiClient!.post(
        '/subjects/me',
        data: {
          'name': name,
          'icon': icon ?? '📚',
          'color': color ?? '#4CAF50',
        },
      );

      if (response.statusCode == 201) {
        await loadSubjects();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la création de la matière';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ AJOUTER UNE MATIÈRE EXISTANTE À L'UTILISATEUR
  Future<bool> addExistingSubjectToUser(int subjectId) async {
    if (apiClient == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await apiClient!.post(
        '/subjects/me',
        data: {'subject_id': subjectId},
      );

      if (response.statusCode == 201) {
        await loadSubjects();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de l\'ajout de la matière';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ MODIFIER UNE MATIÈRE
  Future<bool> updateSubject({
    required int subjectId,
    String? name,
    String? icon,
    String? color,
  }) async {
    if (apiClient == null) {
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        final old = _subjects[index];
        final newSlug = _normalizeSlug(name ?? old.name);
        _subjects[index] = old.copyWith(
          name: name ?? old.name,
          slug: newSlug,
          icon: icon ?? old.icon,
          color: color ?? old.color,
        );
        if (newSlug != old.slug) {
          final messages = _subjectChats[_normalizeSlug(old.slug)] ?? [];
          _subjectChats.remove(_normalizeSlug(old.slug));
          _subjectChats[newSlug] = messages;
        }
        notifyListeners();
        return true;
      }
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await apiClient!.put(
        '/subjects/me/$subjectId',
        data: {
          'custom_name': name,
          'custom_icon': icon,
          'custom_color': color,
        },
      );

      if (response.statusCode == 200) {
        await loadSubjects();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la modification de la matière';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ SUPPRIMER UNE MATIÈRE
  Future<bool> deleteSubject(int subjectId) async {
    if (apiClient == null) {
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        final slug = _normalizeSlug(_subjects[index].slug);
        _subjects.removeAt(index);
        _subjectChats.remove(slug);
        notifyListeners();
        return true;
      }
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await apiClient!.delete(
        '/subjects/me/$subjectId',
      );

      if (response.statusCode == 204) {
        await loadSubjects();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la suppression de la matière';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}