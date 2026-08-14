// frontend/lib/features/chat/presentation/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/entities/message.dart';
import '../../repositories/i_chat_repository.dart';
import '../../domain/usecases/send_message.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required IChatRepository chatRepository,
    required AuthProvider authProvider,
    required this.subjectId,
  })  : _sendMessageUseCase = SendMessageUseCase(chatRepository),
        _authProvider = authProvider {
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
  final int subjectId;

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ AJOUT : Méthode pour mettre à jour les messages depuis l'historique
  void setMessages(List<Message> messages) {
    _messages = messages;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _error = null;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

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
      
      print('📤 Envoi de la question: $content');
      print('📤 subjectId: $subjectId');
      
      final response = await _sendMessageUseCase.execute(
        content.trim(),
        userId: userId,
        subjectId: subjectId,
      );
      
      print('📥 Réponse reçue: ${response.content.substring(0, 50)}...');

      _messages.removeLast();
      _messages.add(response);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur: $e');
      _messages.removeLast();
      _messages.add(
        Message(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          content: '❌ Erreur: ${e.toString()}',
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}