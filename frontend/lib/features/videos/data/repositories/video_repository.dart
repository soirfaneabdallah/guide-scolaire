// frontend/lib/features/videos/data/repositories/video_repository.dart

import '../../../../core/network/api_client.dart';
import '../../domain/entities/video_script.dart';

class VideoRepository {
  VideoRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============================================================
  // LISTER LES VIDÉOS PAR MATIÈRE
  // ============================================================

  Future<Map<String, dynamic>> getVideosBySubject({
    required int subjectId,
    String? level,
    String? chapter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '/videos/by-subject/$subjectId',
      queryParameters: {
        if (level != null) 'level': level,
        if (chapter != null) 'chapter': chapter,
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data;
  }

  // ============================================================
  // DÉTAIL D'UNE VIDÉO
  // ============================================================

  Future<VideoScript> getVideoById(String scriptId) async {
    final response = await _apiClient.get('/videos/$scriptId');
    return VideoScript.fromJson(response.data);
  }

  // ============================================================
  // VIDÉOS RECOMMANDÉES
  // ============================================================

  Future<List<VideoScript>> getRecommendedVideos({
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      '/videos/recommended',
      queryParameters: {'limit': limit},
    );
    final list = response.data['videos'] as List<dynamic>? ?? [];
    return list
        .map((json) => VideoScript.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // VIDÉOS POPULAIRES
  // ============================================================

  Future<List<VideoScript>> getPopularVideos({
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      '/videos/popular',
      queryParameters: {'limit': limit},
    );
    final list = response.data['videos'] as List<dynamic>? ?? [];
    return list
        .map((json) => VideoScript.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // VIDÉOS EN COURS (reprendre)
  // ============================================================

  Future<List<VideoScript>> getInProgressVideos({
    int limit = 5,
  }) async {
    final response = await _apiClient.get(
      '/videos/in-progress',
      queryParameters: {'limit': limit},
    );
    final list = response.data['videos'] as List<dynamic>? ?? [];
    return list
        .map((json) => VideoScript.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // CHAPITRES
  // ============================================================

  Future<List<Map<String, dynamic>>> getChaptersBySubject({
    required int subjectId,
    String? level,
  }) async {
    final response = await _apiClient.get(
      '/videos/chapters/$subjectId',
      queryParameters: {
        if (level != null) 'level': level,
      },
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ============================================================
  // PROGRESSION
  // ============================================================

  Future<void> updateProgress({
    required String scriptId,
    required double lastPosition,
    required double watchedSeconds,
    bool? completed,
  }) async {
    await _apiClient.post(
      '/videos/$scriptId/progress',
      data: {
        'last_position_seconds': lastPosition,
        'watched_seconds': watchedSeconds,
        if (completed != null) 'completed': completed,
      },
    );
  }
}