// frontend/lib/features/chat/domain/entities/message.dart

import 'package:equatable/equatable.dart';

/// Entité métier d'un message dans le chat.
/// Utilisée dans la couche domaine et présentation.
class Message extends Equatable {
  const Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
    this.confidence,
    this.isError = false,
  });

  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions;
  final double? confidence;
  final bool isError;

  /// Copie du message avec des champs modifiés.
  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<String>? suggestions,
    double? confidence,
    bool? isError,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      suggestions: suggestions ?? this.suggestions,
      confidence: confidence ?? this.confidence,
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [id, content, isUser, timestamp];
}