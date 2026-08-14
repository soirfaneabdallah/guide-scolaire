// frontend/lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../chat/domain/entities/message.dart';
import '../../../core/network/api_client.dart';

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

  Subject({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.isDefault = false,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? json['name']?.toLowerCase().replaceAll(' ', '_') ?? '',
      icon: json['icon'],
      color: json['color'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
    };
  }

  Subject copyWith({
    int? id,
    String? name,
    String? slug,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
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
    try {
      return _subjects.firstWhere((s) => s.slug == selectedSubjectSlug);
    } catch (_) {
      return _subjects.isNotEmpty ? _subjects.first : null;
    }
  }
  bool get isLoading => _isLoading;
  String? get error => _error;

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
          ));
        }

        _subjects = loadedSubjects;

        _subjectChats = {
          for (var s in _subjects) s.slug: [],
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
      for (var s in _subjects) s.slug: [],
    };

    if (_selectedSubjectSlug.isEmpty && _subjects.isNotEmpty) {
      _selectedSubjectSlug = _subjects.first.slug;
    }

    notifyListeners();
  }

  // ============================================================
  //  CHARGEMENT DE L'HISTORIQUE DES CHATS (CORRIGÉ)
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
      final String subjectSlug = data['subject_slug'] ?? ''; // 👈 Clé importante

      print('✅ loadChatHistory: subjectSlug = "$subjectSlug"');
      print('✅ loadChatHistory: ${messages.length} messages reçus');

      final List<Message> chatMessages = messages.map((m) {
        return Message(
          id: m['id'].toString(),
          content: m['content'],
          isUser: m['is_user'] ?? true,
          timestamp: DateTime.parse(m['created_at']),
          isError: m['is_error'] ?? false,
        );
      }).toList();

      // ✅ Stocker avec le bon slug
      _subjectChats[subjectSlug] = chatMessages;
      print('✅ _subjectChats["$subjectSlug"] = ${chatMessages.length} messages');
      
      _isLoading = false;
      notifyListeners();
    }
  } catch (e) {
    print('❌ Erreur loadChatHistory: $e');
    _isLoading = false;
    notifyListeners();
  }
}
  // ============================================================
  //  GESTION DES MATIÈRES (CRUD)
  // ============================================================

  Future<bool> addSubject({
    required String name,
    String? icon,
    String? color,
  }) async {
    if (apiClient == null) {
      final newSubject = Subject(
        id: _subjects.length + 100,
        name: name,
        slug: name.toLowerCase().replaceAll(' ', '_'),
        icon: icon,
        color: color,
        isDefault: false,
      );
      _subjects.add(newSubject);
      _subjectChats[newSubject.slug] = [];
      notifyListeners();
      return true;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await apiClient!.post(
        '/subjects/me',
        data: {
          'subject_id': 0,
          'custom_name': name,
          'custom_icon': icon,
          'custom_color': color,
        },
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
        final newSlug = name?.toLowerCase().replaceAll(' ', '_') ?? old.slug;
        _subjects[index] = old.copyWith(
          name: name ?? old.name,
          slug: newSlug,
          icon: icon ?? old.icon,
          color: color ?? old.color,
        );
        if (newSlug != old.slug) {
          final messages = _subjectChats[old.slug] ?? [];
          _subjectChats.remove(old.slug);
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

  Future<bool> deleteSubject(int subjectId) async {
    if (apiClient == null) {
      final index = _subjects.indexWhere((s) => s.id == subjectId);
      if (index != -1) {
        final slug = _subjects[index].slug;
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