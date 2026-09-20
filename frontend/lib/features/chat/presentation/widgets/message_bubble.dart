// frontend/lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/message.dart';
import 'suggestion_chip.dart';

/// Bulle de message ultra-pro dans le chat.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
        bottom: message.suggestions.isNotEmpty ? 8 : 4,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ============================================================
          // BULLE
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isError
                  ? AppColors.error.withOpacity(0.08)
                  : isUser
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: !isUser && !isError
                  ? Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isUser
                ? _buildUserContent(isDark)
                : _buildAssistantContent(isDark),
          ),

          // ============================================================
          // ACTIONS (copier, timestamp)
          // ============================================================
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Copier
                  _buildActionButton(
                    context: context,
                    icon: Icons.copy_rounded,
                    label: 'Copier',
                    isDark: isDark,
                    onTap: () => _copyToClipboard(context),
                  ),
                  const SizedBox(width: 12),
                  // Timestamp
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

          // ============================================================
          // SUGGESTIONS
          // ============================================================
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

  // ============================================================
  // CONTENU UTILISATEUR
  // ============================================================

  Widget _buildUserContent(bool isDark) {
    return Text(
      message.content,
      style: TextStyle(
        color: isDark ? AppColors.textPrimary : Colors.white,
        fontSize: 15,
        height: 1.5,
        letterSpacing: 0.1,
      ),
    );
  }

  // ============================================================
  // CONTENU ASSISTANT (MARKDOWN)
  // ============================================================

  Widget _buildAssistantContent(bool isDark) {
    final textColor =
        isDark ? AppColors.textWhite : AppColors.textPrimary;

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        // Paragraphes
        p: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.6,
          letterSpacing: 0.1,
        ),
        // Titres
        h1: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        h2: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        h3: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        // Emphase
        strong: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        em: TextStyle(
          color: textColor,
          fontStyle: FontStyle.italic,
        ),
        // Liens
        a: TextStyle(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
        // Citations
        blockquote: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.all(12),
        // Code inline
        code: TextStyle(
          backgroundColor: isDark
              ? Colors.black.withOpacity(0.3)
              : AppColors.background,
          color: isDark ? AppColors.textWhite : AppColors.primary,
          fontFamily: 'monospace',
          fontSize: 13.5,
        ),
        // Bloc de code
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        // Listes
        listBullet: TextStyle(
          color: AppColors.primary,
          fontSize: 15,
        ),
        listIndent: 20,
        // Tables
        tableHead: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tableBody: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
        tableBorder: TableBorder.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
        tableCellsPadding: const EdgeInsets.all(8),
        // Séparateur
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOUTON D'ACTION
  // ============================================================

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COPIER
  // ============================================================

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Copié dans le presse-papier'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // FORMATAGE DE LA DATE
  // ============================================================

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (dateOnly == today) {
      return time;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (dateOnly == yesterday) {
      return 'Hier à $time';
    }

    return '${date.day}/${date.month} à $time';
  }
}