// frontend/lib/features/videos/presentation/providers/video_provider.dart

import 'package:flutter/material.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/entities/video_script.dart';

class VideoProvider extends ChangeNotifier {
  VideoProvider({
    required VideoRepository videoRepository,
    required AuthProvider authProvider,
  })  : _repository = videoRepository,
        _authProvider = authProvider;

  final VideoRepository _repository;
  final AuthProvider _authProvider;

  // ============================================================
  // ÉTAT
  // ============================================================

  // Vidéos par matière
  List<VideoScript> _videos = [];
  bool _isLoading = false;
  String? _error;
  int _totalVideos = 0;
  int _currentPage = 1;
  int _pageSize = 20;
  String? _currentLevel;

  // Vidéos recommandées
  List<VideoScript> _recommended = [];
  bool _isLoadingRecommended = false;

  // Vidéos populaires
  List<VideoScript> _popular = [];
  bool _isLoadingPopular = false;

  // Vidéos en cours
  List<VideoScript> _inProgress = [];
  bool _isLoadingInProgress = false;

  // Chapitres
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoadingChapters = false;

  // ============================================================
  // GETTERS
  // ============================================================

  List<VideoScript> get videos => List.unmodifiable(_videos);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalVideos => _totalVideos;
  bool get hasMore => _videos.length < _totalVideos;

  List<VideoScript> get recommended => List.unmodifiable(_recommended);
  bool get isLoadingRecommended => _isLoadingRecommended;

  List<VideoScript> get popular => List.unmodifiable(_popular);
  bool get isLoadingPopular => _isLoadingPopular;

  List<VideoScript> get inProgress => List.unmodifiable(_inProgress);
  bool get isLoadingInProgress => _isLoadingInProgress;

  List<Map<String, dynamic>> get chapters => List.unmodifiable(_chapters);
  bool get isLoadingChapters => _isLoadingChapters;

  // ============================================================
  // CHARGER LES VIDÉOS D'UNE MATIÈRE
  // ============================================================

  Future<void> loadVideosBySubject({
    required int subjectId,
    String? level,
    String? chapter,
    bool refresh = false,
  }) async {
    if (refresh || level != _currentLevel) {
      _videos = [];
      _currentPage = 1;
      _currentLevel = level;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _repository.getVideosBySubject(
        subjectId: subjectId,
        level: level,
        chapter: chapter,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final videosJson = data['videos'] as List<dynamic>? ?? [];
      final newVideos = videosJson
          .map((json) => VideoScript.fromJson(json as Map<String, dynamic>))
          .toList();

      if (refresh || _currentPage == 1) {
        _videos = newVideos;
      } else {
        _videos = [..._videos, ...newVideos];
      }

      _totalVideos = data['total'] ?? 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Erreur chargement vidéos: $e');
    }
  }

  // ============================================================
  // CHARGER LES VIDÉOS RECOMMANDÉES
  // ============================================================

  Future<void> loadRecommended() async {
    _isLoadingRecommended = true;
    notifyListeners();

    try {
      _recommended = await _repository.getRecommendedVideos(limit: 10);
      _isLoadingRecommended = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRecommended = false;
      notifyListeners();
      debugPrint('❌ Erreur recommandations: $e');
    }
  }

  // ============================================================
  // CHARGER LES VIDÉOS POPULAIRES
  // ============================================================

  Future<void> loadPopular() async {
    _isLoadingPopular = true;
    notifyListeners();

    try {
      _popular = await _repository.getPopularVideos(limit: 10);
      _isLoadingPopular = false;
      notifyListeners();
    } catch (e) {
      _isLoadingPopular = false;
      notifyListeners();
      debugPrint('❌ Erreur populaires: $e');
    }
  }

  // ============================================================
  // CHARGER LES VIDÉOS EN COURS
  // ============================================================

  Future<void> loadInProgress() async {
    _isLoadingInProgress = true;
    notifyListeners();

    try {
      _inProgress = await _repository.getInProgressVideos(limit: 5);
      _isLoadingInProgress = false;
      notifyListeners();
    } catch (e) {
      _isLoadingInProgress = false;
      notifyListeners();
      debugPrint('❌ Erreur en cours: $e');
    }
  }

  // ============================================================
  // CHARGER LES CHAPITRES
  // ============================================================

  Future<void> loadChapters({
    required int subjectId,
    String? level,
  }) async {
    _isLoadingChapters = true;
    notifyListeners();

    try {
      _chapters = await _repository.getChaptersBySubject(
        subjectId: subjectId,
        level: level,
      );
      _isLoadingChapters = false;
      notifyListeners();
    } catch (e) {
      _isLoadingChapters = false;
      notifyListeners();
      debugPrint('❌ Erreur chapitres: $e');
    }
  }

  // ============================================================
  // METTRE À JOUR LA PROGRESSION
  // ============================================================

  Future<void> updateProgress({
    required String scriptId,
    required double lastPosition,
    required double watchedSeconds,
    bool? completed,
  }) async {
    try {
      await _repository.updateProgress(
        scriptId: scriptId,
        lastPosition: lastPosition,
        watchedSeconds: watchedSeconds,
        completed: completed,
      );

      // Mettre à jour localement
      final index = _videos.indexWhere((v) => v.id == scriptId);
      if (index != -1) {
        _videos[index] = _videos[index].copyWith(
          userProgress: UserVideoProgress(
            scriptId: scriptId,
            lastPositionSeconds: lastPosition,
            watchedSeconds: watchedSeconds,
            completed: completed ?? _videos[index].userProgress?.completed ?? false,
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur mise à jour progression: $e');
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _videos = [];
    _error = null;
    _currentPage = 1;
    _totalVideos = 0;
    _currentLevel = null;
    notifyListeners();
  }
}