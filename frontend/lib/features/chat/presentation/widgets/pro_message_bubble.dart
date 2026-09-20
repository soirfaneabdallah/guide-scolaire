// frontend/lib/features/chat/presentation/widgets/pro_message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/message.dart';

// ============================================================
//  BULLE DE MESSAGE PROFESSIONNELLE (ÉPURÉE)
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
    final maxWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.85
        : MediaQuery.of(context).size.width * 0.65;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 6,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bulle
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: isUser
                              ? const Radius.circular(20)
                              : const Radius.circular(6),
                          bottomRight: isUser
                              ? const Radius.circular(6)
                              : const Radius.circular(20),
                        ),
                        border: !isUser
                            ? Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.04),
                                width: 1,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.03),
                            blurRadius: 10,
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
                          if (isTyping && !isUser) _buildTypingIndicator(),
                        ],
                      ),
                    ),

                    // Actions
                    if (!isUser && !isTyping) _buildActions(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  MESSAGES
  // ============================================================

  Widget _buildUserMessage() {
    return Text(
      message.content,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14.5,
        height: 1.55,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildAssistantMessage() {
    final textColor = isDark ? AppColors.textWhite : AppColors.textPrimary;

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: textColor,
          fontSize: 14.5,
          height: 1.75,
          letterSpacing: 0.1,
        ),
        h1: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        h2: TextStyle(
          color: textColor,
          fontSize: 19,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        h3: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        strong: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        em: TextStyle(
          color: textColor,
          fontStyle: FontStyle.italic,
        ),
        a: TextStyle(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
        blockquotePadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        code: TextStyle(
          backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          color: isDark ? Colors.green[300]! : Colors.green[800]!,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? Colors.grey[900]! : Colors.grey[100]!,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        listBullet: TextStyle(
          color: AppColors.primary,
          fontSize: 14.5,
        ),
        tableHead: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
        ),
        tableBody: TextStyle(
          color: textColor,
          fontSize: 13,
        ),
        tableBorder: TableBorder.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  //  ACTIONS
  // ============================================================

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.copy_rounded,
            label: 'Copier',
            onTap: () {
              FlutterClipboard.copy(message.content).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Copié dans le presse-papier'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              });
            },
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            context: context,
            icon: Icons.thumb_up_alt_outlined,
            label: 'Utile',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Merci pour votre retour !'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black.withOpacity(0.35),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.black.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  INDICATEUR DE FRAPPE
  // ============================================================

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDot(delay: 0),
          const SizedBox(width: 5),
          _TypingDot(delay: 150),
          const SizedBox(width: 5),
          _TypingDot(delay: 300),
        ],
      ),
    );
  }
}

// ============================================================
//  POINT ANIMÉ DE FRAPPE
// ============================================================

class _TypingDot extends StatefulWidget {
  const _TypingDot({this.delay = 0});

  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: isDark(context)
              ? Colors.white.withOpacity(0.4)
              : Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}