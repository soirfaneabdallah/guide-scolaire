// frontend/lib/features/videos/data/models/video_request_model.dart

class VideoRequestModel {
  final String prompt;
  final int subjectId;
  final String? level;
  final int durationSeconds;
  final String language;

  const VideoRequestModel({
    required this.prompt,
    required this.subjectId,
    this.level,
    this.durationSeconds = 180,
    this.language = 'fr',
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'subject_id': subjectId,
      if (level != null) 'level': level,
      'duration_seconds': durationSeconds,
      'language': language,
    };
  }
}