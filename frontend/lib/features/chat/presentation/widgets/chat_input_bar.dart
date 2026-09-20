// frontend/lib/features/chat/presentation/widgets/chat_input_bar.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Barre de saisie du chat simple (sans mode vidéo).
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onTyping,
    this.isLoading = false,
  });

  /// Callback pour envoyer une question
  final void Function(String) onSend;

  /// Callback quand l'utilisateur tape
  final VoidCallback? onTyping;

  /// État de chargement
  final bool isLoading;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = _controller.text.trim().isNotEmpty && !widget.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ============================================================
            // CHAMP DE SAISIE
            // ============================================================
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.background : AppColors.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (_) => widget.onTyping?.call(),
                  onSubmitted: (_) => _handleSend(),
                  maxLines: 5,
                  minLines: 1,
                  enabled: !widget.isLoading,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: widget.isLoading
                        ? 'Envoi en cours...'
                        : 'Pose ta question...',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ============================================================
            // BOUTON ENVOI (flèche vers le haut)
            // ============================================================
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: canSend
                    ? (isDark ? Colors.white : AppColors.textPrimary)
                    : (isDark ? AppColors.borderDark : AppColors.border),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canSend ? _handleSend : null,
                  borderRadius: BorderRadius.circular(22),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: canSend
                                ? (isDark
                                    ? AppColors.textPrimary
                                    : Colors.white)
                                : AppColors.textTertiary,
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
}