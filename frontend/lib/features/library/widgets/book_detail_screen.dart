// frontend/lib/features/library/presentation/widgets/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';
import '../models/book_comment.dart';
import '../providers/library_provider.dart';
import '../../../core/constants/app_colors.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({
    super.key,
    required this.book,
    required this.provider,
  });

  final Book book;
  final LibraryProvider provider;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int? _replyingTo;
  String? _replyToName;
  bool _isLiked = false;
  bool _isSubmitting = false;
  final Map<int, bool> _commentLikes = {};
  final Set<int> _collapsedThreads = {};

  @override
  void initState() {
    super.initState();
    _isLiked = widget.book.isLiked;

    // ------------------------------------------------------------
    // CORRECTIF : le provider notifie ses changements via
    // notifyListeners(), mais cet écran ne les recevait jamais
    // car il lisait juste `widget.provider.comments` sans jamais
    // s'abonner. Résultat : le premier chargement restait invisible
    // tant qu'un setState() n'était pas déclenché ailleurs (ex. en
    // postant un commentaire). On s'abonne donc explicitement ici.
    // ------------------------------------------------------------
    widget.provider.addListener(_onProviderChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComments();
    });
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadComments() async {
    await widget.provider.loadComments(widget.book.id);
    // Filet de sécurité : même si addListener() ci-dessus suffit
    // normalement, on force aussi un rebuild local ici pour être
    // certain que le premier affichage n'attend jamais une action
    // de l'utilisateur.
    if (mounted) setState(() {});
  }

  void _toggleCommentLike(int commentId) {
    setState(() {
      _commentLikes[commentId] = !(_commentLikes[commentId] ?? false);
    });
    // TODO: Appeler l'API pour liker le commentaire
  }

  void _startReply(int commentId, String userName) {
    setState(() {
      if (_replyingTo == commentId) {
        _replyingTo = null;
        _replyToName = null;
        _commentController.clear();
      } else {
        _replyingTo = commentId;
        _replyToName = userName;
        _commentController.clear();
        _focusNode.requestFocus();
      }
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyToName = null;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildBookCover(isDark, isMobile),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComments,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndAuthor(isDark, isMobile),
                    const SizedBox(height: 12),
                    _buildTags(isDark),
                    const SizedBox(height: 16),
                    _buildStats(isDark, isMobile),
                    const SizedBox(height: 20),
                    _buildDescription(isDark),
                    const SizedBox(height: 28),
                    _buildCommentsSection(isDark, isMobile),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCommentInput(isDark, isMobile),
    );
  }

  // ============================================================
  //  APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.book.title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : (isDark ? Colors.white70 : Colors.grey),
          ),
          onPressed: _toggleLike,
        ),
        IconButton(
          icon: Icon(Icons.share, color: isDark ? Colors.white70 : Colors.grey),
          onPressed: _shareBook,
        ),
      ],
    );
  }

  // ============================================================
  //  COUVERTURE
  // ============================================================

  Widget _buildBookCover(bool isDark, bool isMobile) {
    final coverUrl = widget.book.coverImage ?? _getDefaultCover();
    final hasPdf = widget.book.fileUrl != null;

    return Container(
      height: isMobile ? 200 : 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[200],
        image: DecorationImage(
          image: NetworkImage(coverUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasPdf) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 40),
                    onPressed: () => _openPDF(widget.book.fileUrl!),
                    iconSize: 50,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lire le PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  TITRE, AUTEUR, TAGS
  // ============================================================

  Widget _buildTitleAndAuthor(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.book.title,
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.book.author,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTags(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (widget.book.level != null) _buildTag(widget.book.level!, isDark),
        if (widget.book.subject != null) _buildTag(widget.book.subject!, isDark),
        _buildTag(_formatDate(widget.book.createdAt), isDark),
      ],
    );
  }

  Widget _buildTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
    );
  }

  // ============================================================
  //  STATISTIQUES
  // ============================================================

  Widget _buildStats(bool isDark, bool isMobile) {
    return Row(
      children: [
        _buildStatItem('Vues', widget.book.viewsCount, isDark),
        _buildStatItem('Likes', widget.book.likesCount, isDark),
        _buildStatItem('Commentaires', widget.book.commentsCount, isDark),
      ],
    );
  }

  Widget _buildStatItem(String label, dynamic value, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  DESCRIPTION
  // ============================================================

  Widget _buildDescription(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.book.description,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  SECTION COMMENTAIRES
  // ============================================================

  Widget _buildCommentsSection(bool isDark, bool isMobile) {
    final comments = widget.provider.comments;
    final isLoading = widget.provider.isLoadingComments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Commentaires',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${comments.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (isLoading && comments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          )
        else if (comments.isEmpty)
          _buildEmptyComments(isDark)
        else
          Column(
            children: comments
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCommentNode(c, 0, isDark),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyComments(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: isDark ? Colors.white30 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aucun commentaire',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Soyez le premier à partager votre avis',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  ARBRE DE COMMENTAIRES (profondeur illimitée)
  // ============================================================
  //
  // La ligne de connexion est obtenue simplement en donnant une
  // bordure gauche au conteneur qui enveloppe les réponses d'un
  // commentaire : chaque niveau de profondeur ajoute donc sa propre
  // bordure, ce qui crée naturellement une ligne continue par
  // niveau, sans calcul de hauteur manuel (contrairement à la
  // version précédente basée sur IntrinsicHeight, qui pouvait
  // donner une ligne de hauteur nulle et donc invisible).
  // ============================================================

  Widget _buildCommentNode(BookComment comment, int depth, bool isDark) {
    final isReply = depth > 0;
    final isLiked = _commentLikes[comment.id] ?? false;
    final isReplying = _replyingTo == comment.id;
    final hasReplies = comment.replies.isNotEmpty;
    final isCollapsed = _collapsedThreads.contains(comment.id);

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? (isReply ? Colors.white.withOpacity(0.035) : AppColors.surfaceDark)
            : (isReply ? Colors.grey[50] : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReplying
              ? AppColors.primary.withOpacity(0.4)
              : (isDark
                  ? (isReply ? Colors.white.withOpacity(0.06) : AppColors.borderDark)
                  : Colors.grey[200]!),
          width: isReplying ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.userName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isReply) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(isDark ? 0.16 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Réponse',
                              style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: () => _startReply(comment.id, comment.userName),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReplying
                        ? AppColors.primary.withOpacity(isDark ? 0.16 : 0.1)
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.reply, size: 14, color: isReplying ? AppColors.primary : (isDark ? Colors.white60 : Colors.grey[600])),
                      const SizedBox(width: 4),
                      Text(
                        'Répondre',
                        style: TextStyle(fontSize: 12, color: isReplying ? AppColors.primary : (isDark ? Colors.white60 : Colors.grey[600])),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _toggleCommentLike(comment.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLiked ? Colors.red.withOpacity(0.1) : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 14,
                        color: isLiked ? Colors.red : (isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likesCount + (isLiked ? 1 : 0)}',
                        style: TextStyle(fontSize: 12, color: isLiked ? Colors.red : (isDark ? Colors.white60 : Colors.grey[600])),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasReplies) ...[
                const Spacer(),
                InkWell(
                  onTap: () => setState(() {
                    if (isCollapsed) {
                      _collapsedThreads.remove(comment.id);
                    } else {
                      _collapsedThreads.add(comment.id);
                    }
                  }),
                  child: Text(
                    isCollapsed
                        ? 'Afficher ${comment.replies.length} réponses'
                        : 'Masquer',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
          if (isReplying) ...[
            const SizedBox(height: 12),
            _buildReplyInput(isDark, comment),
          ],
        ],
      ),
    );

    if (!hasReplies) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card,
        if (!isCollapsed)
          Container(
            margin: const EdgeInsets.only(left: 16, top: 10),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: comment.replies
                  .map((reply) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildCommentNode(reply, depth + 1, isDark),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyInput(bool isDark, BookComment comment) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
              onSubmitted: (_) => _submitReply(comment.id),
              decoration: InputDecoration(
                hintText: 'Répondre à @${comment.userName}...',
                hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[500], fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
            onPressed: _isSubmitting ? null : () => _submitReply(comment.id),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white60 : Colors.grey[500]),
            onPressed: _cancelReply,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  INPUT COMMENTAIRE PRINCIPAL
  // ============================================================

  Widget _buildCommentInput(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _replyingTo == null ? _focusNode : null,
                  decoration: InputDecoration(
                    hintText: _replyingTo != null ? 'Répondez au-dessus \u2b06\ufe0f' : 'Ajouter un commentaire...',
                    hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  enabled: _replyingTo == null,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _replyingTo == null ? _submitComment : null,
                  borderRadius: BorderRadius.circular(30),
                  child: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
  //  ACTIONS
  // ============================================================

  Future<void> _toggleLike() async {
    setState(() => _isLiked = !_isLiked);
    await widget.provider.toggleLike(widget.book.id);
    final updatedBook = await widget.provider.loadBookDetails(widget.book.id);
    if (updatedBook != null && mounted) {
      setState(() => _isLiked = updatedBook.isLiked);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final comment = await widget.provider.addComment(
        widget.book.id,
        content,
        parentId: _replyingTo,
      );

      if (comment != null) {
        _commentController.clear();
        setState(() {
          _replyingTo = null;
          _replyToName = null;
          _isSubmitting = false;
        });
        await _loadComments();
        _showMessage('Commentaire ajouté');
      } else {
        setState(() => _isSubmitting = false);
        _showMessage('Erreur lors de l\'ajout du commentaire', isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('Erreur: $e', isError: true);
    }
  }

  Future<void> _submitReply(int parentId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final comment = await widget.provider.addComment(
        widget.book.id,
        content,
        parentId: parentId,
      );

      if (comment != null) {
        _commentController.clear();
        setState(() {
          _replyingTo = null;
          _replyToName = null;
          _isSubmitting = false;
          // On déplie automatiquement le fil dans lequel on vient
          // de répondre, pour que la nouvelle réponse soit visible
          // immédiatement sans action supplémentaire.
          _collapsedThreads.remove(parentId);
        });
        await _loadComments();
        _showMessage('Réponse ajoutée');
      } else {
        setState(() => _isSubmitting = false);
        _showMessage('Erreur lors de l\'ajout de la réponse', isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('Erreur: $e', isError: true);
    }
  }

  void _openPDF(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Impossible d\'ouvrir le PDF', isError: true);
      }
    } catch (e) {
      _showMessage('Erreur: $e', isError: true);
    }
  }

  void _shareBook() {
    _showMessage('Fonction de partage à venir');
  }

  // ============================================================
  //  UTILITAIRES
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getDefaultCover() {
    return 'https://via.placeholder.com/400x600/4CAF50/FFFFFF?text=📚';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 1) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inHours > 1) return 'Il y a ${diff.inHours} heures';
    if (diff.inHours == 1) return 'Il y a 1 heure';
    if (diff.inMinutes > 1) return 'Il y a ${diff.inMinutes} minutes';
    return 'À l\'instant';
  }
}