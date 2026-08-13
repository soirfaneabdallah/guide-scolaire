// frontend/lib/features/chat/repositories/chat_repository.dart

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/entities/message.dart';
import '../repositories/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Message> sendMessage(String question, {int? userId}) async {
    try {
      final response = await _apiClient.post(
        '/chat/ask',  // ✅ URL: /api/v1/chat/ask
        data: {
          'question': question,
          // 'level': '3ème',  // À ajouter si besoin
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return Message(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          content: data['answer'] ?? '',
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: List<String>.from(data['suggestions'] ?? []),
          confidence: data['confidence']?.toDouble(),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.data?['detail'] ?? 'Erreur inconnue'}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'La connexion a expiré. Vérifie ta connexion internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de contacter le serveur. Vérifie ta connexion.';
    }
    if (e.response?.statusCode == 401) {
      return 'Session expirée. Reconnecte-toi.';
    }
    if (e.response?.statusCode != null) {
      return 'Erreur ${e.response?.statusCode}: ${e.response?.data?['detail'] ?? 'Erreur inconnue'}';
    }
    return 'Une erreur est survenue. Réessaie plus tard.';
  }
}