// frontend/lib/features/chat/domain/repositories/i_chat_repository.dart

import '../domain/entities/message.dart';

/// Interface du repository chat.
/// Permet de remplacer l'implémentation pour les tests.
abstract class IChatRepository {
  /// Envoie une question au serveur et retourne la réponse.
  Future<Message> sendMessage(String question, {int? userId});
}