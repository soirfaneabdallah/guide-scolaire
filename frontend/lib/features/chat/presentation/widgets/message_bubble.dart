// frontend/lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/message.dart';
import 'suggestion_chip.dart';

/// Bulle de message dans le chat.
/// Affiche le message, la date, et les suggestions éventuelles.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
  });

  final Message message;
  final void Function(String)? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        left: isUser ? 50 : 0,
        right: isUser ? 0 : 50,
        bottom: message.suggestions.isNotEmpty ? 4 : 0,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bulle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isError
                  ? AppColors.error.withOpacity(0.1)
                  : isUser
                      ? AppColors.primary
                      : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isUser
                    ? const Radius.circular(12)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isUser
                ? Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  )
                : MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      code: TextStyle(
                        backgroundColor: AppColors.background,
                        color: AppColors.primary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      listBullet: const TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          // Date
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                _formatDate(message.timestamp),
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ),
          // Suggestions
          if (message.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestions
                    .map(
                      (s) => SuggestionChip(
                        label: s,
                        onTap: onSuggestionTap != null
                            ? () => onSuggestionTap!(s)
                            : null,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}