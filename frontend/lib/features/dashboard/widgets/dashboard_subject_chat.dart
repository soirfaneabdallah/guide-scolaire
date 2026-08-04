// frontend/lib/features/dashboard/presentation/widgets/dashboard_subject_chat.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/domain/entities/message.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final messages = provider.getMessagesForSubject(widget.subjectSlug);
    final subject = provider.selectedSubject;

    return Column(
      children: [
        // Header (adapté)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 16 : 24,
            vertical: widget.isMobile ? 12 : 16,
          ),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                subject?.name ?? 'Accueil',
                style: TextStyle(
                  fontSize: widget.isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${messages.length} messages',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // Messages list
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun message',
                        style: TextStyle(
                          fontSize: widget.isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pose ta première question sur ${subject?.name ?? "cette matière"}',
                        style: TextStyle(
                          fontSize: widget.isMobile ? 13 : 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: 8,
                        left: message.isUser ? 40 : 0,
                        right: message.isUser ? 0 : 40,
                      ),
                      child: _MessageBubble(
                        message: message,
                        isUser: message.isUser,
                        isMobile: widget.isMobile,
                      ),
                    );
                  },
                ),
        ),

        // Suggestions
        _buildSuggestions(),

        // Input bar
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 8 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(provider),
                      decoration: InputDecoration(
                        hintText: 'Pose ta question...',
                        hintStyle: const TextStyle(
                          color: AppColors.textDisabled,
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(provider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 16,
        vertical: widget.isMobile ? 8 : 12,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _SuggestionChip(label: 'Explique-moi ce concept'),
          _SuggestionChip(label: 'Donne-moi un exemple'),
          _SuggestionChip(label: 'Je ne comprends pas'),
          _SuggestionChip(label: 'Corrige mon exercice'),
        ],
      ),
    );
  }

  void _sendMessage(DashboardProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    provider.addMessage(widget.subjectSlug, userMessage);

    final assistantMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _simulateResponse(text),
      isUser: false,
      timestamp: DateTime.now(),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      provider.addMessage(widget.subjectSlug, assistantMessage);
    });

    _controller.clear();
  }

  String _simulateResponse(String question) {
    return 'Voici une réponse à ta question :\n\n"$question"\n\n'
        'Je te conseille de consulter la bibliothèque numérique pour plus d\'informations. '
        'N\'hésite pas à poser une question plus précise si tu as besoin de détails.';
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.isMobile,
  });

  final Message message;
  final bool isUser;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          CircleAvatar(
            radius: isMobile ? 14 : 16,
            backgroundColor: AppColors.primary,
            child: Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        SizedBox(width: isMobile ? 6 : 8),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 14,
              vertical: isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(12),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 13 : 14,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (isUser)
          CircleAvatar(
            radius: isMobile ? 14 : 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              'Moi',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}