// ============================================================
// FICHIER: frontend/lib/features/videos/presentation/screens/video_player_screen.dart
// DESCRIPTION: Lecteur vidéo avec commentaires et suggestions
// ============================================================

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/environment.dart';
import '../../../auth/providers/auth_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.scriptId,
    this.title,
    this.subjectName,
    this.description,
    this.level,
    this.duration,
  });

  final String scriptId;
  final String? title;
  final String? subjectName;
  final String? description;
  final String? level;
  final int? duration; // en secondes

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _isLoading = true;
  String? _error;

  // État pour le responsive
  bool _isSidebarVisible = true;

  // Commentaires factices (à remplacer par une vraie API)
  final List<Map<String, dynamic>> _comments = [
    {
      'author': 'Jean Dupont',
      'avatar': 'JD',
      'time': 'il y a 2h',
      'text': 'Super explication, j\'ai enfin compris !',
      'likes': 12,
    },
    {
      'author': 'Marie Curie',
      'avatar': 'MC',
      'time': 'il y a 1h',
      'text': 'Merci beaucoup, très clair.',
      'likes': 8,
    },
  ];

  // Suggestions factices
  final List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'Théorème de Thalès',
      'subject': 'Mathématiques',
      'duration': '15 min',
      'color': Colors.blue,
    },
    {
      'title': 'Trigonométrie : les bases',
      'subject': 'Mathématiques',
      'duration': '12 min',
      'color': Colors.green,
    },
    {
      'title': 'Les fractions expliquées',
      'subject': 'Mathématiques',
      'duration': '10 min',
      'color': Colors.orange,
    },
    {
      'title': 'Géométrie dans l\'espace',
      'subject': 'Mathématiques',
      'duration': '18 min',
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  // ============================================================
  // INITIALISATION DU LECTEUR
  // ============================================================

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎬 [VideoPlayer] Initialisation pour ${widget.scriptId}');

      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('Token manquant. Veuillez vous reconnecter.');
      }

      final baseUrl = EnvironmentConfig.baseUrl;
      final streamUrl =
          '$baseUrl/api/v1/videos/${widget.scriptId}/stream?token=$token';

      debugPrint('🎬 [VideoPlayer] URL : $streamUrl');

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: {'Authorization': 'Bearer $token'},
      );

      await _videoController!.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        autoInitialize: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de lecture\n$errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ [VideoPlayer] Erreur : $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD RESPONSIVE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;
          final isMedium = constraints.maxWidth >= 768 && !isWide;

          if (isWide) {
            return _buildWideLayout();
          } else if (isMedium) {
            return _buildMediumLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F0F),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title ?? 'Vidéo',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.subjectName != null)
            Text(
              widget.subjectName!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      actions: [
        if (MediaQuery.of(context).size.width >= 1100)
          IconButton(
            icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
            tooltip: _isSidebarVisible ? 'Masquer les suggestions' : 'Afficher les suggestions',
            onPressed: () {
              setState(() => _isSidebarVisible = !_isSidebarVisible);
            },
          ),
      ],
    );
  }

  // ============================================================
  // LAYOUT WIDE (Desktop ≥1100px) : vidéo + sidebar côte à côte
  // ============================================================

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne principale (vidéo + commentaires)
        Expanded(
          flex: _isSidebarVisible ? 3 : 1,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlayer(),
                _buildVideoInfo(),
                _buildCommentsSection(),
              ],
            ),
          ),
        ),
        // Sidebar suggestions
        if (_isSidebarVisible)
          Container(
            width: 400,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF272727), width: 1),
              ),
            ),
            child: _buildSuggestionsSidebar(),
          ),
      ],
    );
  }

  // ============================================================
  // LAYOUT MEDIUM (Tablette 768-1100px) : vidéo + sidebar étroite
  // ============================================================

  Widget _buildMediumLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlayer(),
                _buildVideoInfo(),
                _buildCommentsSection(),
              ],
            ),
          ),
        ),
        Container(
          width: 300,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF272727), width: 1),
            ),
          ),
          child: _buildSuggestionsSidebar(),
        ),
      ],
    );
  }

  // ============================================================
  // LAYOUT MOBILE (<768px) : tout empilé
  // ============================================================

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayer(),
          _buildVideoInfo(),
          _buildSuggestionsSectionMobile(),
          _buildCommentsSection(),
        ],
      ),
    );
  }

  // ============================================================
  // LECTEUR VIDÉO (toujours 16:9, centré)
  // ============================================================

  Widget _buildPlayer() {
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildPlayerContent(),
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'La génération peut prendre plusieurs minutes',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger la vidéo',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _videoController?.dispose();
                  _chewieController?.dispose();
                  _initializePlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // INFOS VIDÉO (titre, description, actions)
  // ============================================================

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            widget.title ?? 'Vidéo pédagogique',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Méta (vues, niveau, durée)
          Row(
            children: [
              if (widget.level != null) ...[
                _buildBadge(widget.level!),
                const SizedBox(width: 8),
              ],
              if (widget.duration != null) ...[
                _buildBadge('${(widget.duration! / 60).ceil()} min'),
                const SizedBox(width: 8),
              ],
              _buildBadge('1.2k vues'),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          if (widget.description != null && widget.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.description!,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  // ============================================================
  // SIDEBAR SUGGESTIONS (Desktop/Tablette)
  // ============================================================

  Widget _buildSuggestionsSidebar() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'À suivre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ..._suggestions.map((s) => _buildSuggestionCard(s)),
      ],
    );
  }

  // ============================================================
  // SUGGESTIONS MOBILE (sous la vidéo)
  // ============================================================

  Widget _buildSuggestionsSectionMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'À suivre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 240,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildSuggestionCard(_suggestions[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Naviguer vers la vidéo suggérée
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vidéo : ${suggestion['title']}')),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniature
            Container(
              width: 140,
              height: 80,
              decoration: BoxDecoration(
                color: suggestion['color'] as Color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_outline,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 10),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion['subject'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  Text(
                    suggestion['duration'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMENTAIRES
  // ============================================================

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_comments.length} commentaires',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Ajouter un commentaire
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF272727),
                child: Icon(Icons.person, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF272727)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Liste
          ..._comments.map((c) => _buildCommentTile(c)),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              comment['avatar'] as String,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['author'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment['time'] as String,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['text'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.thumb_up_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${comment['likes']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.thumb_down_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 16),
                    const Text(
                      'Répondre',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}