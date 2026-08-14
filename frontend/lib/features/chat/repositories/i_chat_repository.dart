// frontend/lib/features/chat/domain/repositories/i_chat_repository.dart

import '../domain/entities/message.dart';

abstract class IChatRepository {
  Future<Message> sendMessage(
    String question, {
    int? userId,
    String? subjectSlug,
    int? subjectId,  // 👈 AJOUT
  });
}