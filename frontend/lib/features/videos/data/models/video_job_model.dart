// frontend/lib/features/videos/data/models/video_job_model.dart

import '../../domain/entities/video_script.dart';

/// Modèle de données pour un job de génération vidéo.
/// Fait le pont entre l'API et les entités métier.
class VideoJobModel {
  final String id;
  final int userId;
  final String promptContext;
  final String? concept;
  final String status;
  final int progress;
  final int estimatedDurationSeconds;
  final int? actualDurationSeconds;
  final int elapsedSeconds;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? errorMessage;
  final bool fallbackUsed;
  final bool isCached;
  final DateTime createdAt;
  final DateTime? completedAt;

  const VideoJobModel({
    required this.id,
    required this.userId,
    required this.promptContext,
    this.concept,
    required this.status,
    this.progress = 0,
    this.estimatedDurationSeconds = 360,
    this.actualDurationSeconds,
    this.elapsedSeconds = 0,
    this.videoUrl,
    this.thumbnailUrl,
    this.errorMessage,
    this.fallbackUsed = false,
    this.isCached = false,
    required this.createdAt,
    this.completedAt,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory VideoJobModel.fromJson(Map<String, dynamic> json) {
    return VideoJobModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? 0,
      promptContext: json['prompt_context'] ?? '',
      concept: json['concept'],
      status: json['status'] ?? 'pending',
      progress: json['progress'] ?? 0,
      estimatedDurationSeconds: json['estimated_duration_seconds'] ?? 360,
      actualDurationSeconds: json['actual_duration_seconds'],
      elapsedSeconds: json['elapsed_seconds'] ?? 0,
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
      errorMessage: json['error_message'],
      fallbackUsed: json['fallback_used'] ?? false,
      isCached: json['is_cached'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'prompt_context': promptContext,
      'concept': concept,
      'status': status,
      'progress': progress,
      'estimated_duration_seconds': estimatedDurationSeconds,
      'actual_duration_seconds': actualDurationSeconds,
      'elapsed_seconds': elapsedSeconds,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'error_message': errorMessage,
      'fallback_used': fallbackUsed,
      'is_cached': isCached,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  VideoJobModel copyWith({
    String? id,
    int? userId,
    String? promptContext,
    String? concept,
    String? status,
    int? progress,
    int? estimatedDurationSeconds,
    int? actualDurationSeconds,
    int? elapsedSeconds,
    String? videoUrl,
    String? thumbnailUrl,
    String? errorMessage,
    bool? fallbackUsed,
    bool? isCached,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return VideoJobModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      promptContext: promptContext ?? this.promptContext,
      concept: concept ?? this.concept,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      fallbackUsed: fallbackUsed ?? this.fallbackUsed,
      isCached: isCached ?? this.isCached,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}