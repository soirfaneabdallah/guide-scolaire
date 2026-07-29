// frontend/lib/features/chat/domain/usecases/send_message.dart

import '../entities/message.dart';
import '../../../chat/repositories/i_chat_repository.dart';


/// Use case pour envoyer un message et recevoir une réponse.
class SendMessageUseCase {
  SendMessageUseCase(this._repository);

  final IChatRepository _repository;

  /// Exécute le use case.
  Future<Message> execute(String question, {int? userId}) {
    return _repository.sendMessage(question, userId: userId);
  }
}