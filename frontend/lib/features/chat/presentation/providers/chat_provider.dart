// frontend/lib/features/chat/presentation/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../repositories/chat_repository.dart';
import '../../domain/entities/message.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatRepository chatRepository,
    required AuthProvider authProvider,
    required int subjectId,
  })  : _chatRepository = chatRepository,
        _authProvider = authProvider,
        _subjectId = subjectId {
    // ✅ Charger l'historique automatiquement à la création
    loadHistory();
  }

  final ChatRepository _chatRepository;
  final AuthProvider _authProvider;
  int _subjectId;

  final List<Message> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  int get subjectId => _subjectId;

  // ============================================================
  // CHARGER L'HISTORIQUE
  // ============================================================

  Future<void> loadHistory() async {
    if (_isLoadingHistory) return;

    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      final history = await _chatRepository.getHistory(
        subjectId: _subjectId,
        limit: 100,
      );

      _messages.clear();
      _messages.addAll(history);

      _isLoadingHistory = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingHistory = false;
      notifyListeners();
      debugPrint('❌ Erreur chargement historique: $e');
    }
  }

  // ============================================================
  // ENVOYER UN MESSAGE
  // ============================================================

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    // 1. Ajouter le message utilisateur
    _messages.add(Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final Message responseMessage = await _chatRepository.sendMessage(
        question: text,
        subjectId: _subjectId,
      );

      _messages.add(responseMessage);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;

      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Désolé, une erreur est survenue. Veuillez réessayer.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
      notifyListeners();
    }
  }

  // ============================================================
  // CHANGER DE MATIÈRE
  // ============================================================

  void updateSubject(int newSubjectId) {
    _subjectId = newSubjectId;
    _messages.clear();
    _error = null;
    notifyListeners();

    // ✅ Recharger l'historique de la nouvelle matière
    loadHistory();
  }

  // ============================================================
  // EFFACER LA CONVERSATION
  // ============================================================

  void clearConversation() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // RAFRAÎCHIR
  // ============================================================

  Future<void> refresh() async {
    await loadHistory();
  }
}