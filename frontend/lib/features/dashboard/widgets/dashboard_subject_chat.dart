// frontend/lib/features/dashboard/presentation/widgets/dashboard_subject_chat.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/domain/entities/message.dart';
import '../../chat/presentation/widgets/pro_message_bubble.dart';
import '../../chat/repositories/chat_repository.dart';
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

class _DashboardSubjectChatState extends State<DashboardSubjectChat>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  bool _isInitialLoad = true;
  bool _showScrollToBottom = false;

  // Typewriter effect state
  final Map<String, String> _typedContents = {};
  final Map<String, Timer> _typingTimers = {};
  final Set<String> _typingIds = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();

    _loadChatHistory();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final show = maxScroll - currentScroll > 200;
    if (show != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = show;
      });
    }
  }

  // ============================================================
  //  LOAD CHAT HISTORY – NO AUTO‑SCROLL
  // ============================================================

  void _loadChatHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      final subject = provider.selectedSubject;
      if (subject != null) {
        provider.loadChatHistory(subject.id).then((_) {
          final messages = provider.getMessagesForSubject(widget.subjectSlug);
          _initializeTypedContents(messages);
          setState(() {
            _isInitialLoad = false;
          });
        });
      } else {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  void _initializeTypedContents(List<Message> messages) {
    for (final msg in messages) {
      _typedContents[msg.id] = msg.content;
    }
  }

  @override
  void didUpdateWidget(DashboardSubjectChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectSlug != widget.subjectSlug) {
      _isInitialLoad = true;
      _cancelAllTypingTimers();
      _typedContents.clear();
      _typingIds.clear();
      _loadChatHistory();
    }
  }

  void _cancelAllTypingTimers() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _typingIds.clear();
  }

  @override
  void dispose() {
    _cancelAllTypingTimers();
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ============================================================
  //  TYPEWRITER EFFECT
  // ============================================================

  void _startTypingEffect(Message message) {
    if (_typingIds.contains(message.id)) return;
    if (_typedContents.containsKey(message.id)) return;

    _typedContents[message.id] = '';
    _typingIds.add(message.id);

    int index = 0;
    final fullContent = message.content;
    final timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (index < fullContent.length) {
        _typedContents[message.id] = fullContent.substring(0, index + 1);
        setState(() {});
        index++;
      } else {
        timer.cancel();
        _typingTimers.remove(message.id);
        _typingIds.remove(message.id);
        _typedContents[message.id] = fullContent;
        setState(() {});
      }
    });
    _typingTimers[message.id] = timer;
  }

  // ============================================================
  //  SEND MESSAGE – NO AUTO‑SCROLL
  // ============================================================

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final dashboardProvider = context.read<DashboardProvider>();
    final subject = dashboardProvider.selectedSubject;
    final effectiveSlug = subject?.slug ?? widget.subjectSlug;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    dashboardProvider.addMessage(effectiveSlug, userMessage);
    _typedContents[userMessage.id] = userMessage.content;

    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _isSending = true;
    });

    final apiClient = context.read<ApiClient>();
    final authProvider = context.read<AuthProvider>();
    final chatRepository = ChatRepository(apiClient: apiClient);
    final userId = authProvider.userId;
    final subjectId = subject?.id ?? 1;

    chatRepository
        .sendMessage(text, userId: userId, subjectId: subjectId)
        .then((response) {
      dashboardProvider.refreshChatHistory(subjectId).then((_) {
        final messages = dashboardProvider.getMessagesForSubject(effectiveSlug);
        for (final msg in messages) {
          if (!msg.isUser && !_typedContents.containsKey(msg.id)) {
            _startTypingEffect(msg);
          }
        }
        setState(() {
          _isSending = false;
        });
      });
    }).catchError((error) {
      debugPrint('❌ Erreur envoi: $error');

      final errorMessage = Message(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: '❌ Erreur: ${error.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      dashboardProvider.addMessage(effectiveSlug, errorMessage);
      _typedContents[errorMessage.id] = errorMessage.content;

      setState(() {
        _isSending = false;
      });
    });
  }

  void _clearChat(DashboardProvider dashboardProvider) {
    final subject = dashboardProvider.selectedSubject;
    final effectiveSlug = subject?.slug ?? widget.subjectSlug;
    dashboardProvider.clearSubjectHistory(effectiveSlug);
    _cancelAllTypingTimers();
    _typedContents.clear();
    _typingIds.clear();
    setState(() {
      _isSending = false;
    });
  }

  // ============================================================
  //  SCROLL TO BOTTOM (MANUAL)
  // ============================================================

  void _scrollToBottomInstant() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  //  BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final subject = dashboardProvider.selectedSubject;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final effectiveSlug = subject?.slug ?? widget.subjectSlug;
        final messages = dashboardProvider.getMessagesForSubject(effectiveSlug);
        final isLoading = dashboardProvider.isLoading || _isInitialLoad;

        // Start typewriter for new assistant messages
        for (final msg in messages) {
          if (!msg.isUser &&
              !_typedContents.containsKey(msg.id) &&
              !_typingIds.contains(msg.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _startTypingEffect(msg);
              }
            });
          }
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.background,
            child: Column(
              children: [
                _buildHeader(dashboardProvider, messages, isDark),
                Expanded(
                  child: Stack(
                    children: [
                      _buildMessageList(messages, isLoading, isDark, subject),
                      if (_showScrollToBottom && messages.isNotEmpty)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: _buildScrollToBottomButton(),
                        ),
                    ],
                  ),
                ),
                _buildTypingIndicator(),
                if (messages.isNotEmpty && !_isSending) _buildSuggestions(),
                _buildInputBar(dashboardProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  //  MESSAGE LIST
  // ============================================================

  Widget _buildMessageList(
    List<Message> messages,
    bool isLoading,
    bool isDark,
    Subject? subject,
  ) {
    if (isLoading && messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement des messages...',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return _buildEmptyState(subject);
    }

    final groupedMessages = _groupMessagesByDate(messages);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: groupedMessages.length,
      itemBuilder: (context, index) {
        final group = groupedMessages[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSeparator(group.date, isDark),
            const SizedBox(height: 8),
            ...group.messages.map((message) {
              final displayContent = _typedContents[message.id] ?? message.content;
              final displayMessage = message.copyWith(content: displayContent);
              return ProMessageBubble(
                message: displayMessage,
                isUser: message.isUser,
                isDark: isDark,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = "Aujourd'hui";
    } else if (dateOnly == yesterday) {
      label = 'Hier';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textWhite : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  HEADER
  // ============================================================

  Widget _buildHeader(
    DashboardProvider dashboardProvider,
    List<Message> messages,
    bool isDark,
  ) {
    final subject = dashboardProvider.selectedSubject;
    final isLoading = dashboardProvider.isLoading || _isInitialLoad;

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
            decoration: BoxDecoration(
              color: _isSending ? AppColors.warning : AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subject?.name ?? 'Accueil',
              style: TextStyle(
                fontSize: widget.isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (messages.isNotEmpty && !isLoading) ...[
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
              onPressed: () => _clearChat(dashboardProvider),
              tooltip: 'Effacer la discussion',
              color: AppColors.textSecondary,
              splashRadius: 20,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  //  EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(Subject? subject) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                    _sendMessage();
                  },
                ),
                _QuickSuggestion(
                  label: 'Donne-moi un exemple',
                  onTap: () {
                    _controller.text = 'Donne-moi un exemple';
                    _sendMessage();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  TYPING INDICATOR
  // ============================================================

  Widget _buildTypingIndicator() {
    if (!_isSending) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "L'assistant écrit...",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textWhite : AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SCROLL TO BOTTOM BUTTON
  // ============================================================

  Widget _buildScrollToBottomButton() {
    return GestureDetector(
      onTap: _scrollToBottomInstant,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_downward_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // ============================================================
  //  SUGGESTIONS
  // ============================================================

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
          children: [
            _QuickSuggestion(
              label: 'Explique-moi',
              onTap: () {
                _controller.text = 'Explique-moi ce concept';
                _sendMessage();
              },
            ),
            const SizedBox(width: 8),
            _QuickSuggestion(
              label: 'Donne-moi un exemple',
              onTap: () {
                _controller.text = 'Donne-moi un exemple';
                _sendMessage();
              },
            ),
            const SizedBox(width: 8),
            _QuickSuggestion(
              label: 'Je ne comprends pas',
              onTap: () {
                _controller.text = 'Je ne comprends pas';
                _sendMessage();
              },
            ),
            const SizedBox(width: 8),
            _QuickSuggestion(
              label: 'Corrige mon exercice',
              onTap: () {
                _controller.text = 'Corrige mon exercice';
                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  INPUT BAR
  // ============================================================

  Widget _buildInputBar(DashboardProvider dashboardProvider) {
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
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isSending,
                  decoration: InputDecoration(
                    hintText: _isSending
                        ? 'Envoi en cours...'
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
                  onTap: _isSending ? null : () => _sendMessage(),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isSending ? Icons.hourglass_empty : Icons.send_rounded,
                      color: _isSending ? Colors.grey : Colors.white,
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
  //  UTILITY
  // ============================================================

  List<_MessageGroup> _groupMessagesByDate(List<Message> messages) {
    final groups = <_MessageGroup>[];
    DateTime? currentDate;

    for (final message in messages) {
      final dateOnly = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      if (currentDate == null || dateOnly != currentDate) {
        currentDate = dateOnly;
        groups.add(_MessageGroup(date: dateOnly, messages: []));
      }

      groups.last.messages.add(message);
    }

    return groups;
  }
}

// ============================================================
//  MESSAGE GROUP
// ============================================================

class _MessageGroup {
  _MessageGroup({
    required this.date,
    required this.messages,
  });

  final DateTime date;
  final List<Message> messages;
}

// ============================================================
//  QUICK SUGGESTION WIDGET
// ============================================================

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