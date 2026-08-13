// frontend/lib/features/chat/presentation/widgets/pro_message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
//import 'package:markdown/markdown.dart' as md;
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/message.dart';

// ============================================================
//  BULLE DE MESSAGE PROFESSIONNELLE
//  Version stable (sans highlight)
// ============================================================

class ProMessageBubble extends StatelessWidget {
  const ProMessageBubble({
    super.key,
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
          if (!isUser) _buildAvatar('AI', AppColors.primary),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 18,
                vertical: isMobile ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
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
                  isUser
                      ? _buildUserMessage()
                      : _buildAssistantMessage(),
                  if (!isUser && !isTyping) _buildCopyButton(context),
                  if (isTyping && !isUser) _buildTypingIndicator(),
                  if (!isUser && !isTyping) _buildBadge(),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar('Moi', AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _buildAvatar(String label, Color color) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserMessage() {
    return Text(
      message.content,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildAssistantMessage() {
    final textColor = isDark ? AppColors.textWhite : AppColors.textPrimary;

    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: textColor, fontSize: 14, height: 1.6),
        h1: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        h2: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.bold),
        h3: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
        strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
        blockquotePadding: const EdgeInsets.all(12),
        code: TextStyle(
          backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          color: isDark ? Colors.green[300]! : Colors.green[800]!,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        listBullet: TextStyle(color: AppColors.primary, fontSize: 14),
        tableHead: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        tableBody: TextStyle(color: textColor, fontSize: 13),
        tableBorder: TableBorder.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () {
          FlutterClipboard.copy(message.content).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📋 Copié dans le presse-papier !'),
                duration: Duration(seconds: 1),
              ),
            );
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Copier',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          _TypingDot(),
          const SizedBox(width: 4),
          _TypingDot(),
          const SizedBox(width: 4),
          _TypingDot(),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
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
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.textTertiary,
        shape: BoxShape.circle,
      ),
    );
  }
}