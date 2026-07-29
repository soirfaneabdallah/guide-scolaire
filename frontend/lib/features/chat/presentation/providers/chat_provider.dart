// frontend/lib/features/chat/presentation/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/entities/message.dart';
import '../../repositories/i_chat_repository.dart';
import '../../domain/usecases/send_message.dart';

/// Provider d'état du chat.
/// Gère la liste des messages, l'état de chargement, et les erreurs.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required IChatRepository chatRepository,
    required AuthProvider authProvider,
  })  : _sendMessageUseCase = SendMessageUseCase(chatRepository),
        _authProvider = authProvider {
    // Initialiser avec un message de bienvenue
    _messages = [
        Message(
        id: 'welcome',
        content:
            '👋 Bonjour ! Je suis ton assistant scolaire. Pose-moi une question sur n\'importe quel sujet de cours.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: [
          'Explique-moi les fractions',
          'Comment conjuguer au passé composé ?',
          'Théorème de Pythagore',
          'Calculer une moyenne',
        ],
      ),
    ];
  }

  final SendMessageUseCase _sendMessageUseCase;
  final AuthProvider _authProvider;

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Ajoute un message utilisateur et envoie la requête.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _error = null;

    // Message utilisateur
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // Message de l'assistant (placeholder pour le typage)
    final assistantPlaceholder = Message(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(assistantPlaceholder);
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authProvider.userId;
      final response = await _sendMessageUseCase.execute(
        content.trim(),
        userId: userId,
      );

      // Remplacer le placeholder par la vraie réponse
      _messages.removeLast();
      _messages.add(response);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Remplacer le placeholder par un message d'erreur
      _messages.removeLast();
      _messages.add(
        Message(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          content: e.toString(),
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Efface toutes les conversations.
  void clearConversation() {
    _messages = [
       Message(
        id: 'welcome',
        content:
            '👋 Bonjour ! Je suis ton assistant scolaire. Pose-moi une question sur n\'importe quel sujet de cours.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: [
          'Explique-moi les fractions',
          'Comment conjuguer au passé composé ?',
          'Théorème de Pythagore',
          'Calculer une moyenne',
        ],
      ),
    ];
    _error = null;
    notifyListeners();
  }

  /// Efface une erreur.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}