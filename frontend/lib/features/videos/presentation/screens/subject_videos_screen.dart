// frontend/lib/features/videos/presentation/screens/subject_videos_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/entities/video_script.dart';
import '../providers/video_provider.dart';
import '../widgets/level_selector.dart';
import '../widgets/video_card.dart';

class SubjectVideosScreen extends StatefulWidget {
  const SubjectVideosScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectIcon,
    required this.subjectColor,
  });

  final int subjectId;
  final String subjectName;
  final String subjectIcon;
  final Color subjectColor;

  @override
  State<SubjectVideosScreen> createState() => _SubjectVideosScreenState();
}

class _SubjectVideosScreenState extends State<SubjectVideosScreen> {
  late VideoProvider _provider;
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();

    final authProvider = context.read<AuthProvider>();
    final apiClient = context.read<ApiClient>();

    // ✅ Niveau de l'élève par défaut
    _selectedLevel = authProvider.userLevel ?? '3ème';

    _provider = VideoProvider(
      videoRepository: VideoRepository(apiClient: apiClient), // ✅ CORRIGÉ
      authProvider: authProvider,
    );

    // Charger les vidéos après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

  void _loadVideos() {
    _provider.loadVideosBySubject(
      subjectId: widget.subjectId,
      level: _selectedLevel,
    );
  }

  void _onLevelChanged(String newLevel) {
    setState(() {
      _selectedLevel = newLevel;
    });
    _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider<VideoProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
        body: CustomScrollView(
          slivers: [
            // ============================================================
            // APPBAR PERSONNALISÉE
            // ============================================================
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: widget.subjectColor,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.subjectIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.subjectName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.subjectColor,
                        widget.subjectColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // ✅ Bouton d'accès au chat de la matière
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: 'Chat sur cette matière',
                  onPressed: _openSubjectChat,
                ),
              ],
            ),

            // ============================================================
            // SÉLECTEUR DE NIVEAU
            // ============================================================
            SliverToBoxAdapter(
              child: LevelSelector(
                selectedLevel: _selectedLevel ?? '3ème',
                userLevel: context.read<AuthProvider>().userLevel ?? '3ème',
                onLevelChanged: _onLevelChanged,
              ),
            ),

            // ============================================================
            // STATISTIQUES
            // ============================================================
            SliverToBoxAdapter(
              child: Consumer<VideoProvider>(
                builder: (context, provider, _) {
                  return _buildStats(provider, isDark);
                },
              ),
            ),

            // ============================================================
            // LISTE DES VIDÉOS
            // ============================================================
            Consumer<VideoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (provider.error != null) {
                  return SliverFillRemaining(
                    child: _buildError(provider.error!, isDark),
                  );
                }

                if (provider.videos.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmpty(isDark),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = provider.videos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VideoCard(
                            video: video,
                            subjectColor: widget.subjectColor,
                            onTap: () => _openVideo(video),
                          ),
                        );
                      },
                      childCount: provider.videos.length,
                    ),
                  ),
                );
              },
            ),

            // Espace en bas
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createVideo,
          backgroundColor: widget.subjectColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Créer une vidéo'),
        ),
      ),
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStats(VideoProvider provider, bool isDark) {
    final total = provider.totalVideos;
    final completed =
        provider.videos.where((v) => v.userProgress?.completed == true).length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression en $_selectedLevel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.border,
              valueColor: AlwaysStoppedAnimation(widget.subjectColor),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÉTATS : ERREUR / VIDE
  // ============================================================

  Widget _buildError(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVideos,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: widget.subjectColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune vidéo pour $_selectedLevel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez la première vidéo sur ce sujet !',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createVideo,
              icon: const Icon(Icons.add),
              label: const Text('Créer une vidéo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.subjectColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _openSubjectChat() {
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {
        'subjectId': widget.subjectId,
        'subjectName': widget.subjectName,
      },
    );
  }

  void _openVideo(VideoScript video) {
    Navigator.pushNamed(
      context,
      AppRoutes.videoPlayer,
      arguments: {
        'scriptId': video.id,
        'video': video,
      },
    );
  }

  void _createVideo() {
    Navigator.pushNamed(
      context,
      AppRoutes.createVideo,
      arguments: {
        'subjectId': widget.subjectId,
        'subjectName': widget.subjectName,
        'level': _selectedLevel,
      },
    );
  }
}