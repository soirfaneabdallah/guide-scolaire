// frontend/lib/features/chat/data/repositories/chat_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/entities/message.dart';
import '../repositories/i_chat_repository.dart';
//import '../data/chat_message.dart';
import '../data/chat_request.dart';

/// Implémentation du repository chat avec Dio.
class ChatRepository implements IChatRepository {
  ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Message> sendMessage(String question, {int? userId}) async {
    try {
      final request = ChatRequest(question: question, userId: userId);
      final response = await _apiClient.post(
        '/chat/ask',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final message = Message(
          id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          content: data['answer'] ?? '',
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: List<String>.from(data['suggestions'] ?? []),
          confidence: data['confidence']?.toDouble(),
        );
        return message;
      } else {
        throw Exception(
          'Erreur ${response.statusCode}: ${response.data?['detail'] ?? 'Erreur inconnue'}',
        );
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
    if (e.response?.statusCode == 429) {
      return 'Trop de requêtes. Attends un peu avant de réessayer.';
    }
    if (e.response?.statusCode != null) {
      return 'Erreur ${e.response?.statusCode}: ${e.response?.data?['detail'] ?? 'Erreur inconnue'}';
    }
    return 'Une erreur est survenue. Réessaie plus tard.';
  }
}