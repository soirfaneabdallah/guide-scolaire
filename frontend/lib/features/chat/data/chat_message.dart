// frontend/lib/features/chat/data/models/chat_message.dart

import 'package:equatable/equatable.dart';

/// Modèle de données pour un message dans le chat.
/// Utilisé pour la sérialisation/désérialisation JSON.
class ChatMessageModel extends Equatable {
  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
    this.confidence,
  });

  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions;
  final double? confidence;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? '',
      isUser: json['is_user'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      confidence: json['confidence']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'suggestions': suggestions,
      'confidence': confidence,
    };
  }

  @override
  List<Object?> get props => [id, content, isUser, timestamp];
}