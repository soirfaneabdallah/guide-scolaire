// frontend/lib/features/dashboard/presentation/widgets/dashboard_subject_chat.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/domain/entities/message.dart';
import '../providers/dashboard_provider.dart';
import 'dart:async'; 

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

  // Pour l'effet de frappe progressive
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
    final messages = provider.getMessagesForSubject(widget.subjectSlug);
    final subject = provider.selectedSubject;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: Column(
        children: [
          // ===== HEADER =====
          Container(
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
                  decoration: BoxDecoration(
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
          ),

          // ===== MESSAGES LIST =====
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(subject)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      // Si c'est le dernier message ET qu'il est en cours de frappe
                      if (index == messages.length - 1 &&
                          _isTyping &&
                          !message.isUser) {
                        return _MessageBubble(
                          message: message.copyWith(
                            content: _displayedResponse,
                          ),
                          isUser: false,
                          isDark: isDark,
                          isTyping: true,
                        );
                      }
                      return _MessageBubble(
                        message: message,
                        isUser: message.isUser,
                        isDark: isDark,
                      );
                    },
                  ),
          ),

          // ===== SUGGESTIONS (mobile) =====
          if (messages.isNotEmpty && !_isTyping) _buildSuggestions(),

          // ===== INPUT BAR =====
          Container(
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
                        onSubmitted: (_) => _sendMessage(provider),
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
                        onTap: _isTyping ? null : () => _sendMessage(provider),
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
          ),
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
                  _sendMessage(Provider.of<DashboardProvider>(context, listen: false));
                },
              ),
              _QuickSuggestion(
                label: 'Donne-moi un exemple',
                onTap: () {
                  _controller.text = 'Donne-moi un exemple';
                  _sendMessage(Provider.of<DashboardProvider>(context, listen: false));
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

  void _sendMessage(DashboardProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Ajouter le message de l'utilisateur
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    provider.addMessage(widget.subjectSlug, userMessage);

    // Effacer le champ
    _controller.clear();
    _focusNode.unfocus();

    // Indicateur de frappe
    setState(() {
      _isTyping = true;
      _displayedResponse = '';
      _currentCharIndex = 0;
    });

    // Récupérer la réponse complète
    final fullResponse = _simulateResponse(text);

    // Lancer l'affichage progressif
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentCharIndex < fullResponse.length) {
        setState(() {
          _displayedResponse += fullResponse[_currentCharIndex];
          _currentCharIndex++;
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        // Ajouter le message final
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

  String _simulateResponse(String question) {
    // Réponses variées sans répéter la question
    final responses = [
      'C\'est une excellente question ! Voyons cela ensemble...\n\n'
      'Le concept clé ici est de comprendre que tout repose sur une base logique. '
      'Lorsque tu décomposes le problème, chaque étape devient plus simple.\n\n'
      'N\'hésite pas à me demander des précisions si un point reste flou !',

      'Je vois ce que tu veux dire. L\'idée principale est de bien structurer le raisonnement.\n\n'
      'Pense à utiliser les connaissances que tu as déjà acquises dans ce domaine. '
      'L\'important est de rester méthodique et de ne pas sauter d\'étapes.\n\n'
      'Veux-tu que je te donne un exercice d\'application ?',

      'Très bonne question ! Le plus important ici est de bien comprendre le contexte.\n\n'
      'Je te suggère de commencer par identifier les éléments clés du sujet. '
      'Une fois que tu as une vision claire, tout devient plus accessible.\n\n'
      'Si tu as besoin d\'un exemple concret, je peux t\'en fournir un.',

      'C\'est un sujet intéressant. L\'approche la plus efficace est souvent la plus simple.\n\n'
      'Commence par les bases, puis construis progressivement. '
      'N\'hésite pas à faire des schémas ou des notes pour clarifier ta pensée.\n\n'
      'Qu\'est-ce qui te pose le plus de difficulté dans ce point ?',

      'Je comprends ta question. Voici comment aborder ce sujet...\n\n'
      'La méthode recommandée consiste à décomposer le problème en sous-parties. '
      'Chaque sous-partie peut ensuite être traitée individuellement.\n\n'
      'Si tu veux, on peut approfondir un aspect particulier de ce sujet.',
    ];

    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }
}

// ===== SUGGESTION CHIP =====
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

// ===== QUICK SUGGESTION =====
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
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppColors.primary,
            ),
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

// ===== MESSAGE BUBBLE =====
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.isDark,
    this.isTyping = false,
  });

  final Message message;
  final bool isUser;
  final bool isDark;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 40 : 0,
        right: isUser ? 0 : 40,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar IA
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!isUser) const SizedBox(width: 8),

          // Bulle
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? AppColors.textWhite : AppColors.textPrimary),
                      fontSize: isMobile ? 13 : 14,
                      height: 1.4,
                    ),
                  ),
                  if (isTyping && !isUser) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTypingDot(),
                        const SizedBox(width: 4),
                        _buildTypingDot(),
                        const SizedBox(width: 4),
                        _buildTypingDot(),
                      ],
                    ),
                  ],
                  if (!isUser && !isTyping) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assisté par IA',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Avatar utilisateur
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child:  Text(
                'Moi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingDot() {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.textTertiary,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}