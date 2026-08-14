// frontend/lib/features/chat/repositories/chat_repository.dart

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/entities/message.dart';
import '../repositories/i_chat_repository.dart';

/// Implémentation du repository chat avec Dio.
class ChatRepository implements IChatRepository {
  ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Message> sendMessage(
    String question, {
    int? userId,
    String? subjectSlug,
    int? subjectId,  // 👈 AJOUT : ID de la matière
  }) async {
    try {
      // 👇 Corps de la requête
      final Map<String, dynamic> data = {
        'question': question,
        'level': '3ème',
      };
      
      // ✅ Utiliser l'ID si disponible (plus robuste)
      if (subjectId != null) {
        data['subject_id'] = subjectId;
      } 
      // Fallback sur le slug si l'ID n'est pas fourni
      else if (subjectSlug != null && subjectSlug.isNotEmpty) {
        data['subject_slug'] = subjectSlug;
      }

      final response = await _apiClient.post(
        '/chat/ask',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data as Map<String, dynamic>;
        return Message(
          id: result['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          content: result['answer'] ?? '',
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: List<String>.from(result['suggestions'] ?? []),
          confidence: result['confidence']?.toDouble(),
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