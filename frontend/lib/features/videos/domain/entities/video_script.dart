// frontend/lib/features/videos/domain/entities/video_script.dart

import 'package:equatable/equatable.dart';

/// Entité métier d'un script vidéo.
/// Représente une vidéo pédagogique (code + narration).
class VideoScript extends Equatable {
  const VideoScript({
    required this.id,
    required this.title,
    this.description,
    required this.subjectId,
    required this.level,
    this.chapter,
    this.tags = const [],
    this.thumbnailUrl,
    this.thumbnailPrompt,
    required this.sceneCount,
    required this.estimatedDurationSeconds,
    this.viewsCount = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.isValidated = false,
    this.isGenerated = true,
    this.version = 1,
    this.createdAt,
    this.userProgress,
  });

  final String id;
  final String title;
  final String? description;

  // Classification
  final int subjectId;
  final String level;
  final String? chapter;
  final List<String> tags;

  // Miniature
  final String? thumbnailUrl;
  final String? thumbnailPrompt;

  // Métadonnées
  final int sceneCount;
  final int estimatedDurationSeconds;

  // Statistiques
  final int viewsCount;
  final double ratingAverage;
  final int ratingCount;
  final bool isValidated;
  final bool isGenerated;
  final int version;

  // Timestamps
  final DateTime? createdAt;

  // Progression utilisateur (optionnel)
  final UserVideoProgress? userProgress;

  // ============================================================
  // GETTERS UTILES
  // ============================================================

  /// Durée formatée (ex: "5:32" ou "45s")
  String get formattedDuration {
    final minutes = estimatedDurationSeconds ~/ 60;
    final seconds = estimatedDurationSeconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Le pourcentage de progression (0.0 à 1.0)
  double get progressPercentage {
    if (userProgress == null) return 0.0;
    if (estimatedDurationSeconds == 0) return 0.0;
    return (userProgress!.watchedSeconds / estimatedDurationSeconds).clamp(0.0, 1.0);
  }

  /// Est-ce que la vidéo a été commencée ?
  bool get isStarted => userProgress != null && userProgress!.watchedSeconds > 0;

  /// Est-ce que la vidéo a été terminée ?
  bool get isCompleted => userProgress?.completed ?? false;

  // ============================================================
  // COPY WITH
  // ============================================================

  VideoScript copyWith({
    String? id,
    String? title,
    String? description,
    int? subjectId,
    String? level,
    String? chapter,
    List<String>? tags,
    String? thumbnailUrl,
    String? thumbnailPrompt,
    int? sceneCount,
    int? estimatedDurationSeconds,
    int? viewsCount,
    double? ratingAverage,
    int? ratingCount,
    bool? isValidated,
    bool? isGenerated,
    int? version,
    DateTime? createdAt,
    UserVideoProgress? userProgress,
  }) {
    return VideoScript(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      level: level ?? this.level,
      chapter: chapter ?? this.chapter,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      thumbnailPrompt: thumbnailPrompt ?? this.thumbnailPrompt,
      sceneCount: sceneCount ?? this.sceneCount,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
      viewsCount: viewsCount ?? this.viewsCount,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      isValidated: isValidated ?? this.isValidated,
      isGenerated: isGenerated ?? this.isGenerated,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      userProgress: userProgress ?? this.userProgress,
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory VideoScript.fromJson(Map<String, dynamic> json) {
    return VideoScript(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sans titre',
      description: json['description'],
      subjectId: json['subject_id'] ?? 0,
      level: json['level'] ?? '3ème',
      chapter: json['chapter'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : const [],
      thumbnailUrl: json['thumbnail_url'],
      thumbnailPrompt: json['thumbnail_prompt'],
      sceneCount: json['scene_count'] ?? 0,
      estimatedDurationSeconds: json['estimated_duration_seconds'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      ratingAverage: (json['rating_average'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      isValidated: json['is_validated'] ?? false,
      isGenerated: json['is_generated'] ?? true,
      version: json['version'] ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      userProgress: json['user_progress'] != null
          ? UserVideoProgress.fromJson(json['user_progress'])
          : null,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'level': level,
      'chapter': chapter,
      'tags': tags,
      'thumbnail_url': thumbnailUrl,
      'thumbnail_prompt': thumbnailPrompt,
      'scene_count': sceneCount,
      'estimated_duration_seconds': estimatedDurationSeconds,
      'views_count': viewsCount,
      'rating_average': ratingAverage,
      'rating_count': ratingCount,
      'is_validated': isValidated,
      'is_generated': isGenerated,
      'version': version,
      'created_at': createdAt?.toIso8601String(),
      'user_progress': userProgress?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subjectId,
        level,
        chapter,
        thumbnailUrl,
        estimatedDurationSeconds,
        userProgress,
      ];
}

// ============================================================
// PROGRESSION UTILISATEUR SUR UNE VIDÉO
// ============================================================

class UserVideoProgress extends Equatable {
  const UserVideoProgress({
    required this.scriptId,
    this.lastPositionSeconds = 0.0,
    this.watchedSeconds = 0.0,
    this.completed = false,
    this.liked,
    this.rating,
  });

  final String scriptId;
  final double lastPositionSeconds;
  final double watchedSeconds;
  final bool completed;
  final bool? liked;
  final int? rating;

  /// Pourcentage de progression (0.0 à 1.0)
  double get percentage {
    if (watchedSeconds <= 0) return 0.0;
    return (watchedSeconds / lastPositionSeconds).clamp(0.0, 1.0);
  }

  UserVideoProgress copyWith({
    String? scriptId,
    double? lastPositionSeconds,
    double? watchedSeconds,
    bool? completed,
    bool? liked,
    int? rating,
  }) {
    return UserVideoProgress(
      scriptId: scriptId ?? this.scriptId,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      completed: completed ?? this.completed,
      liked: liked ?? this.liked,
      rating: rating ?? this.rating,
    );
  }

  factory UserVideoProgress.fromJson(Map<String, dynamic> json) {
    return UserVideoProgress(
      scriptId: json['script_id'] ?? '',
      lastPositionSeconds:
          (json['last_position_seconds'] ?? 0.0).toDouble(),
      watchedSeconds: (json['watched_seconds'] ?? 0.0).toDouble(),
      completed: json['completed'] ?? false,
      liked: json['liked'],
      rating: json['rating'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'script_id': scriptId,
      'last_position_seconds': lastPositionSeconds,
      'watched_seconds': watchedSeconds,
      'completed': completed,
      'liked': liked,
      'rating': rating,
    };
  }

  @override
  List<Object?> get props => [
        scriptId,
        lastPositionSeconds,
        watchedSeconds,
        completed,
        liked,
        rating,
      ];
}