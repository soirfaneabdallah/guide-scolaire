// frontend/lib/features/videos/data/models/video_quota_model.dart

class VideoQuotaModel {
  final int id;
  final int userId;
  final String tier;
  final int dailyLimitSeconds;
  final int usedSecondsToday;
  final int remainingSeconds;
  final double usedPercentage;
  final bool canGenerate;

  const VideoQuotaModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.dailyLimitSeconds,
    required this.usedSecondsToday,
    required this.remainingSeconds,
    required this.usedPercentage,
    required this.canGenerate,
  });

  factory VideoQuotaModel.fromJson(Map<String, dynamic> json) {
  return VideoQuotaModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    userId: (json['user_id'] as num?)?.toInt() ?? 0,
    tier: json['tier']?.toString() ?? 'free',
    dailyLimitSeconds: (json['daily_limit_seconds'] as num?)?.toInt() ?? 1800,
    usedSecondsToday: (json['used_seconds_today'] as num?)?.toInt() ?? 0,
    remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ?? 1800,
    usedPercentage: (json['used_percentage'] as num?)?.toDouble() ?? 0.0,
    canGenerate: json['can_generate'] as bool? ?? true,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tier': tier,
      'daily_limit_seconds': dailyLimitSeconds,
      'used_seconds_today': usedSecondsToday,
      'remaining_seconds': remainingSeconds,
      'used_percentage': usedPercentage,
      'can_generate': canGenerate,
    };
  }

  // Helpers
  int get remainingMinutes => (remainingSeconds / 60).ceil();
  int get dailyLimitMinutes => (dailyLimitSeconds / 60).ceil();
  int get usedMinutes => (usedSecondsToday / 60).ceil();
}