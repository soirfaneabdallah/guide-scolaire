// frontend/lib/features/videos/data/services/video_generation_service.dart

import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/video_job_model.dart';
import '../models/video_quota_model.dart';
import '../models/video_request_model.dart';

class VideoGenerationService {
  VideoGenerationService({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============================================================
  // LANCER UNE GÉNÉRATION
  // ============================================================

  Future<Map<String, dynamic>> startGeneration(VideoRequestModel request) async {
    debugPrint('📤 [VideoService] Démarrage génération...');
    debugPrint('   Request: ${request.toJson()}');

    final response = await _apiClient.post(
      '/videos/generate',
      data: request.toJson(),
    );

    debugPrint('📥 [VideoService] Réponse génération : ${response.data}');
    return response.data;
  }

  // ============================================================
  // STATUT D'UN JOB
  // ============================================================

  Future<VideoJobModel> getJobStatus(String jobId) async {
    final response = await _apiClient.get('/videos/status/$jobId');

    debugPrint('📥 [VideoService] Statut job $jobId : ${response.data}');

    return VideoJobModel.fromJson(response.data);
  }

  // ============================================================
  // QUOTA
  // ============================================================

  Future<VideoQuotaModel> getQuota() async {
    final response = await _apiClient.get('/videos/quota');

    final quota = VideoQuotaModel.fromJson(response.data);

    return quota;
  }

  // ============================================================
  // ANNULER UN JOB
  // ============================================================

  Future<void> cancelJob(String jobId) async {
    debugPrint('🚫 [VideoService] Annulation job $jobId');
    await _apiClient.delete('/videos/job/$jobId');
  }
}