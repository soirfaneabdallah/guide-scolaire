// frontend/lib/features/chat/data/models/chat_request.dart

import 'package:equatable/equatable.dart';

/// Modèle de requête pour l'endpoint /chat/ask.
class ChatRequest extends Equatable {
  const ChatRequest({
    required this.question,
    this.userId,
  });

  final String question;
  final int? userId;

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      if (userId != null) 'user_id': userId,
    };
  }

  @override
  List<Object?> get props => [question, userId];
}