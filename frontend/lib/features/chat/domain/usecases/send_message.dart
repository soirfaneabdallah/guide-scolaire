// frontend/lib/features/chat/domain/usecases/send_message.dart

import '../entities/message.dart';
import '../../repositories/i_chat_repository.dart';

class SendMessageUseCase {
  SendMessageUseCase(this._repository);

  final IChatRepository _repository;

  Future<Message> execute(
    String question, {
    int? userId,
    String? subjectSlug,
    int? subjectId,  // 👈 AJOUT
  }) {
    return _repository.sendMessage(
      question,
      userId: userId,
      subjectSlug: subjectSlug,
      subjectId: subjectId,
    );
  }
}