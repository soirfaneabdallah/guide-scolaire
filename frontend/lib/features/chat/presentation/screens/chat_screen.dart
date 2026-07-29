// frontend/lib/features/chat/presentation/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Écran de chat complet.
/// Interface type ChatGPT avec bulles de messages, indicateur de frappe,
/// et suggestions contextuelles.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si une question initiale est fournie, l'envoyer automatiquement
    if (widget.initialQuestion != null &&
        widget.initialQuestion != oldWidget.initialQuestion) {
      Future.microtask(() {
        final provider = context.read<ChatProvider>();
        if (provider.messages.length == 1) {
          provider.sendMessage(widget.initialQuestion!);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assistant Scolaire',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
            onPressed: () {
              _showClearDialog(context);
            },
            tooltip: 'Effacer la conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.messages.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.messages.length) {
                  // Typing indicator
                  if (provider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: TypingIndicator(),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final message = provider.messages[index];
                return MessageBubble(
                  message: message,
                  onSuggestionTap: (suggestion) {
                    provider.sendMessage(suggestion);
                  },
                );
              },
            ),
          ),

          // Saisie
          ChatInputBar(
            onSend: (text) {
              provider.sendMessage(text);
              _scrollToBottom();
            },
            onTyping: _scrollToBottom,
            isLoading: provider.isLoading,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la conversation'),
        content: const Text(
          'Tous les messages seront supprimés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearConversation();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}