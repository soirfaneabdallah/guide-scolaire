// frontend/lib/features/chat/repositories/chat_repository.dart

import '../../../../core/network/api_client.dart';
import '../domain/entities/message.dart';

class ChatRepository {
  ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============================================================
  // CHARGER L'HISTORIQUE
  // ============================================================

  /// Charge l'historique des messages pour une matière donnée.
  Future<List<Message>> getHistory({
    required int subjectId,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/chat/history/$subjectId',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final data = response.data;
    final messagesJson = data['messages'] as List<dynamic>? ?? [];

    return messagesJson.map((json) {
      return Message(
        id: json['id']?.toString() ?? '',
        content: json['content'] ?? '',
        isUser: json['is_user'] ?? false,
        timestamp: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        isError: json['is_error'] ?? false,
      );
    }).toList();
  }

  // ============================================================
  // ENVOYER UN MESSAGE
  // ============================================================

  Future<Message> sendMessage({
    required String question,
    required int subjectId,
  }) async {
    final response = await _apiClient.post(
      '/chat/ask',
      data: {
        'question': question,
        'subject_id': subjectId,
      },
    );

    final data = response.data;
    final answer = data['answer'] ?? 'Pas de réponse';

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: answer,
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: data['suggestions'] != null
          ? List<String>.from(data['suggestions'])
          : const [],
    );
  }

  // ============================================================
  // DEMANDER UNE VIDÉO
  // ============================================================

  Future<Message> requestVideo({
    required String prompt,
    required int subjectId,
  }) async {
    final response = await _apiClient.post(
      '/videos/generate',
      data: {
        'prompt': prompt,
        'subject_id': subjectId,
      },
    );

    final data = response.data;
    final jobId = data['job_id'] ?? 'inconnu';

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '✅ Demande de vidéo enregistrée !\n\n'
          '🔖 ID de génération : $jobId\n\n'
          '⏳ Vous recevrez une notification dès que la vidéo sera prête.',
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  // ============================================================
  // EFFACER L'HISTORIQUE
  // ============================================================

  Future<void> clearHistory({
    required int subjectId,
  }) async {
    await _apiClient.delete('/chat/history/$subjectId');
  }
}