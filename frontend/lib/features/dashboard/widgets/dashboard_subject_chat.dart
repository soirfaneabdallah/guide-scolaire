// frontend/lib/features/dashboard/presentation/widgets/dashboard_subject_chat.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/domain/entities/message.dart';
import '../../chat/presentation/providers/chat_provider.dart';
import '../../chat/presentation/widgets/pro_message_bubble.dart';  // 👈 AJOUT
import '../providers/dashboard_provider.dart';

class DashboardSubjectChat extends StatefulWidget {
  const DashboardSubjectChat({
    super.key,
    required this.subjectSlug,
    this.isMobile = false,
  });

  final String subjectSlug;
  final bool isMobile;

  @override
  State<DashboardSubjectChat> createState() => _DashboardSubjectChatState();
}

class _DashboardSubjectChatState extends State<DashboardSubjectChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _typingTimer;
  String _displayedResponse = '';
  int _currentCharIndex = 0;
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages = provider.getMessagesForSubject(widget.subjectSlug);
    final subject = provider.selectedSubject;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: Column(
        children: [
          _buildHeader(provider, messages, isDark),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(subject)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      if (index == messages.length - 1 &&
                          _isTyping &&
                          !message.isUser) {
                        return ProMessageBubble(
                          message: message.copyWith(
                            content: _displayedResponse,
                          ),
                          isUser: false,
                          isDark: isDark,
                          isTyping: true,
                        );
                      }
                      return ProMessageBubble(
                        message: message,
                        isUser: message.isUser,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
          if (messages.isNotEmpty && !_isTyping) _buildSuggestions(),
          _buildInputBar(provider, chatProvider),
        ],
      ),
    );
  }

  Widget _buildHeader(
    DashboardProvider provider,
    List<Message> messages,
    bool isDark,
  ) {
    final subject = provider.selectedSubject;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 16 : 24,
        vertical: widget.isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            subject?.name ?? 'Accueil',
            style: TextStyle(
              fontSize: widget.isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (_isTyping)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'L\'assistant réfléchit...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          if (messages.isNotEmpty && !_isTyping) ...[
            Text(
              '${messages.length} messages',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _clearChat(provider),
              tooltip: 'Effacer la discussion',
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(Subject? subject) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pose ta première question',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sur ${subject?.name ?? "cette matière"}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickSuggestion(
                label: 'Explique-moi ce concept',
                onTap: () {
                  _controller.text = 'Explique-moi ce concept';
                  _sendMessage(
                    Provider.of<DashboardProvider>(context, listen: false),
                    Provider.of<ChatProvider>(context, listen: false),
                  );
                },
              ),
              _QuickSuggestion(
                label: 'Donne-moi un exemple',
                onTap: () {
                  _controller.text = 'Donne-moi un exemple';
                  _sendMessage(
                    Provider.of<DashboardProvider>(context, listen: false),
                    Provider.of<ChatProvider>(context, listen: false),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: const [
            _SuggestionChip(label: 'Explique-moi'),
            SizedBox(width: 8),
            _SuggestionChip(label: 'Donne-moi un exemple'),
            SizedBox(width: 8),
            _SuggestionChip(label: 'Je ne comprends pas'),
            SizedBox(width: 8),
            _SuggestionChip(label: 'Corrige mon exercice'),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(DashboardProvider provider, ChatProvider chatProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 8 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _sendMessage(provider, chatProvider),
                  enabled: !_isTyping,
                  decoration: InputDecoration(
                    hintText: _isTyping
                        ? 'L\'assistant répond...'
                        : 'Pose ta question...',
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 12 : 16,
                      vertical: widget.isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isTyping ? null : () => _sendMessage(provider, chatProvider),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isTyping ? Icons.hourglass_empty : Icons.send_rounded,
                      color: _isTyping ? Colors.grey : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ⭐ ENVOI DE MESSAGE (connecté au backend)
  // ============================================================
  void _sendMessage(DashboardProvider provider, ChatProvider chatProvider) {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    provider.addMessage(widget.subjectSlug, userMessage);

    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _isTyping = true;
      _displayedResponse = '';
      _currentCharIndex = 0;
    });

    chatProvider.sendMessage(text).then((_) {
      _handleResponse(provider, chatProvider);
    }).catchError((error) {
      _handleError(provider, error);
    });
  }

  // ============================================================
  // ⭐ GESTION DE LA RÉPONSE
  // ============================================================
  void _handleResponse(DashboardProvider provider, ChatProvider chatProvider) {
    final messages = chatProvider.messages;
    Message? lastAssistantMessage;

    for (int i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isUser) {
        lastAssistantMessage = messages[i];
        break;
      }
    }

    if (lastAssistantMessage == null) {
      _handleError(provider, 'Aucune réponse reçue');
      return;
    }

    if (lastAssistantMessage.isError) {
      setState(() {
        _isTyping = false;
        _displayedResponse = '';
        _currentCharIndex = 0;
      });
      return;
    }

    final fullResponse = lastAssistantMessage.content;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentCharIndex < fullResponse.length) {
        setState(() {
          _displayedResponse += fullResponse[_currentCharIndex];
          _currentCharIndex++;
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        final assistantMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: fullResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
        provider.addMessage(widget.subjectSlug, assistantMessage);
        setState(() {
          _isTyping = false;
          _displayedResponse = '';
          _currentCharIndex = 0;
        });
        _scrollToBottom();
      }
    });
  }

  // ============================================================
  // ⭐ GESTION DES ERREURS
  // ============================================================
  void _handleError(DashboardProvider provider, dynamic error) {
    final errorMessage = Message(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      content: '❌ Erreur: $error',
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
    provider.addMessage(widget.subjectSlug, errorMessage);
    setState(() {
      _isTyping = false;
      _displayedResponse = '';
      _currentCharIndex = 0;
    });
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat(DashboardProvider provider) {
    provider.clearSubjectHistory(widget.subjectSlug);
    _typingTimer?.cancel();
    setState(() {
      _isTyping = false;
      _displayedResponse = '';
      _currentCharIndex = 0;
    });
  }
}

// ============================================================
// WIDGETS AUXILIAIRES
// ============================================================

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textWhite : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _QuickSuggestion extends StatelessWidget {
  const _QuickSuggestion({
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}