// frontend/lib/features/library/providers/library_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/book.dart';
import '../models/book_comment.dart';

class LibraryProvider extends ChangeNotifier {
  LibraryProvider({this.apiClient});

  final ApiClient? apiClient;

  List<Book> _books = [];
  Book? _selectedBook;
  List<BookComment> _comments = [];
  bool _isLoading = false;
  bool _isLoadingComments = false;  // ✅ Séparer le chargement des commentaires
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMore = true;

  String? _selectedLevel;
  int? _selectedSubjectId;
  String? _searchQuery;

  // ============================================================
  //  GETTERS
  // ============================================================

  List<Book> get books => _books;
  Book? get selectedBook => _selectedBook;
  List<BookComment> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isLoadingComments => _isLoadingComments;  // ✅ Nouveau getter
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get selectedLevel => _selectedLevel;
  int? get selectedSubjectId => _selectedSubjectId;
  String? get searchQuery => _searchQuery;

  // ============================================================
  //  CHARGEMENT DES LIVRES
  // ============================================================

  Future<void> loadBooks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _books = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient!.get(
        '/books',
        queryParameters: {
          'skip': _currentPage * 20,
          'limit': 20,
          if (_selectedLevel != null) 'level': _selectedLevel,
          if (_selectedSubjectId != null) 'subject_id': _selectedSubjectId,
          if (_searchQuery != null && _searchQuery!.isNotEmpty) 'search': _searchQuery,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> booksData = data['books'] ?? [];
        final List<Book> newBooks = booksData.map((json) => Book.fromJson(json)).toList();

        _books.addAll(newBooks);
        _totalPages = data['total_pages'] ?? 0;
        _hasMore = _currentPage + 1 < _totalPages;
        _currentPage++;

        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Erreur lors du chargement des livres';
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

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    await loadBooks();
    _isLoadingMore = false;
    notifyListeners();
  }

  // ============================================================
  //  LIVRE INDIVIDUEL
  // ============================================================

  Future<Book?> loadBookDetails(int bookId) async {
    try {
      final response = await apiClient!.get('/books/$bookId');
      if (response.statusCode == 200) {
        final book = Book.fromJson(response.data);
        return book;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleLike(int bookId) async {
    try {
      final response = await apiClient!.post('/books/$bookId/like');
      if (response.statusCode == 200) {
        final isLiked = response.data as bool;
        final index = _books.indexWhere((b) => b.id == bookId);
        if (index != -1) {
          _books[index] = _books[index].copyWith(
            isLiked: isLiked,
            likesCount: _books[index].likesCount + (isLiked ? 1 : -1),
          );
          notifyListeners();
        }
        return isLiked;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  //  COMMENTAIRES - VERSION CORRIGÉE
  // ============================================================

  // frontend/lib/features/library/providers/library_provider.dart

Future<void> loadComments(int bookId) async {
  try {
    _isLoadingComments = true;
    _error = null;
    notifyListeners();

    print('📥 Chargement des commentaires pour le livre $bookId');
    
    final response = await apiClient!.get('/books/$bookId/comments');
    
    print('📥 Statut: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List ? response.data : [];
      print('📥 ${data.length} commentaires reçus');
      
      // ✅ Vérifier la structure des données
      if (data.isNotEmpty) {
        print('📥 Premier commentaire: ${data[0]}');
      }
      
      _comments = data.map((json) {
        try {
          return BookComment.fromJson(json);
        } catch (e) {
          print('❌ Erreur mapping commentaire: $e');
          print('📄 JSON: $json');
          // Retourner un commentaire vide en cas d'erreur
          return BookComment(
            id: 0,
            content: 'Erreur de chargement',
            bookId: bookId,
            userId: 0,
            userName: 'Erreur',
            createdAt: DateTime.now(),
            replies: [],
          );
        }
      }).toList();
      
      // ✅ Filtrer les commentaires invalides
      _comments = _comments.where((c) => c.id != 0).toList();
      
      print('✅ ${_comments.length} commentaires chargés avec succès');
      _isLoadingComments = false;
      notifyListeners();
    } else {
      _error = 'Erreur lors du chargement des commentaires';
      _isLoadingComments = false;
      notifyListeners();
    }
  } catch (e) {
    print('❌ Erreur loadComments: $e');
    _error = e.toString();
    _isLoadingComments = false;
    notifyListeners();
  }
}
// frontend/lib/features/library/providers/library_provider.dart

Future<bool> toggleCommentLike(int commentId) async {
  try {
    final response = await apiClient!.post('/books/comments/$commentId/like');
    if (response.statusCode == 200) {
      final isLiked = response.data as bool;
      
      // Mettre à jour le commentaire localement
      _updateCommentLike(commentId, isLiked);
      notifyListeners();
      return isLiked;
    }
    return false;
  } catch (e) {
    return false;
  }
}

void _updateCommentLike(int commentId, bool isLiked) {
  void updateRecursive(List<BookComment> comments) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        comments[i] = comments[i].copyWith(
          isLiked: isLiked,
          likesCount: comments[i].likesCount + (isLiked ? 1 : -1),
        );
        return;
      }
      if (comments[i].replies.isNotEmpty) {
        updateRecursive(comments[i].replies);
      }
    }
  }
  updateRecursive(_comments);
}
  Future<BookComment?> addComment(int bookId, String content, {int? parentId}) async {
    try {
      _isLoadingComments = true;
      notifyListeners();

      final response = await apiClient!.post(
        '/books/$bookId/comments',
        data: {
          'content': content,
          'parent_id': parentId,
        },
      );

      if (response.statusCode == 201) {
        final comment = BookComment.fromJson(response.data);
        
        if (parentId == null) {
          // Commentaire principal - ajouter en haut
          _comments.insert(0, comment);
        } else {
          // Réponse - trouver le commentaire parent
          final parentIndex = _comments.indexWhere((c) => c.id == parentId);
          if (parentIndex != -1) {
            final parent = _comments[parentIndex];
            _comments[parentIndex] = parent.copyWith(
              replies: [...parent.replies, comment],
            );
          }
        }
        
        // Incrémenter le compteur de commentaires du livre
        final bookIndex = _books.indexWhere((b) => b.id == bookId);
        if (bookIndex != -1) {
          _books[bookIndex] = _books[bookIndex].copyWith(
            commentsCount: _books[bookIndex].commentsCount + 1,
          );
        }
        
        _isLoadingComments = false;
        notifyListeners();
        return comment;
      }
      
      _isLoadingComments = false;
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoadingComments = false;
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  //  FILTRES
  // ============================================================

  void setLevelFilter(String? level) {
    _selectedLevel = level;
    _resetAndLoad();
  }

  void setSubjectFilter(int? subjectId) {
    _selectedSubjectId = subjectId;
    _resetAndLoad();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    _resetAndLoad();
  }

  void clearFilters() {
    _selectedLevel = null;
    _selectedSubjectId = null;
    _searchQuery = null;
    _resetAndLoad();
  }

  void _resetAndLoad() {
    _currentPage = 0;
    _books = [];
    _hasMore = true;
    loadBooks();
  }

  // ============================================================
  //  CRÉATION DE LIVRE
  // ============================================================

  Future<bool> createBook({
    required String title,
    required String description,
    required String author,
    String? coverImage,
    String? fileUrl,
    String? level,
    int? subjectId,
    bool isPublic = true,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await apiClient!.post(
        '/books',
        data: {
          'title': title,
          'description': description,
          'author': author,
          'cover_image': coverImage,
          'file_url': fileUrl,
          'level': level,
          'subject_id': subjectId,
          'is_public': isPublic,
        },
      );

      if (response.statusCode == 201) {
        await loadBooks(refresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la création du livre';
        _isLoading = false;
        notifyListeners();
        return false;
      }
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