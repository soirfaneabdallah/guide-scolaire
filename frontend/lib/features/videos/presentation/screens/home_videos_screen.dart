// frontend/lib/features/videos/presentation/screens/home_videos_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../data/repositories/video_repository.dart';
import '../../domain/entities/video_script.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card_horizontal.dart';
import '../widgets/video_card.dart';
import '../widgets/subject_card.dart';

class HomeVideosScreen extends StatefulWidget {
  const HomeVideosScreen({super.key});

  @override
  State<HomeVideosScreen> createState() => _HomeVideosScreenState();
}

class _HomeVideosScreenState extends State<HomeVideosScreen> {
  late VideoProvider _provider;

  @override
  void initState() {
    super.initState();

    final apiClient = context.read<ApiClient>();
    final authProvider = context.read<AuthProvider>();

    _provider = VideoProvider(
      videoRepository: VideoRepository(apiClient: apiClient),
      authProvider: authProvider,
    );

    _loadData();
  }

  void _loadData() {
    _provider.loadRecommended();
    _provider.loadPopular();
    _provider.loadInProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider<VideoProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: CustomScrollView(
            slivers: [
              // ============================================================
              // APPBAR PERSONNALISÉE
              // ============================================================
              SliverAppBar(
                floating: true,
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                elevation: 0,
                title: Row(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final name = auth.userName ?? 'Élève';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bonjour 👋',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              name.split(' ').first,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textWhite
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // ============================================================
              // BARRE DE RECHERCHE
              // ============================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Rechercher un sujet...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ============================================================
              // MATIÈRES
              // ============================================================
              SliverToBoxAdapter(
                child: _buildSubjectsSection(isDark),
              ),

              // ============================================================
              // REPRENDRE
              // ============================================================
              Consumer<VideoProvider>(
                builder: (context, provider, _) {
                  if (provider.inProgress.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _buildSection(
                      title: '🔥 Reprendre',
                      videos: provider.inProgress,
                      isDark: isDark,
                      isLarge: true,
                    ),
                  );
                },
              ),

              // ============================================================
              // RECOMMANDÉ
              // ============================================================
              Consumer<VideoProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingRecommended) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (provider.recommended.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _buildSection(
                      title: '🎯 Recommandé pour toi',
                      videos: provider.recommended,
                      isDark: isDark,
                    ),
                  );
                },
              ),

              // ============================================================
              // POPULAIRES
              // ============================================================
              Consumer<VideoProvider>(
                builder: (context, provider, _) {
                  if (provider.popular.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _buildSection(
                      title: '🌟 Tendances',
                      videos: provider.popular,
                      isDark: isDark,
                    ),
                  );
                },
              ),

              // Espace en bas
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION MATIÈRES
  // ============================================================

  Widget _buildSubjectsSection(bool isDark) {
    // Récupérer les matières du dashboard
    final dashboard = context.read<DashboardProvider>();
    final subjects = dashboard.subjects;

    if (subjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            '📚 Tes matières',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 100,
                  child: SubjectCard(
                    name: subject.name,
                    icon: subject.icon ?? '📚',
                    color: _parseColor(subject.color) ?? AppColors.primary,
                    onTap: () => _openSubject(subject),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION VIDÉOS (générique)
  // ============================================================

  Widget _buildSection({
    required String title,
    required List<VideoScript> videos,
    required bool isDark,
    bool isLarge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => _seeAll(title),
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: isLarge ? 180 : 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: VideoCardHorizontal(
                  video: video,
                  subjectColor: _getSubjectColor(video),
                  onTap: () => _openVideo(video),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _openSubject(dynamic subject) {
    Navigator.pushNamed(
      context,
      '/subject-videos',
      arguments: {
        'subjectId': subject.id,
        'subjectName': subject.name,
        'subjectIcon': subject.icon,
        'subjectColor': subject.color,
      },
    );
  }

  void _openVideo(VideoScript video) {
    Navigator.pushNamed(
      context,
      '/video',
      arguments: {'scriptId': video.id},
    );
  }

  void _seeAll(String section) {
    // TODO: Naviguer vers une page complète
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  Color _getSubjectColor(VideoScript video) {
    // TODO: Récupérer la couleur réelle de la matière
    return AppColors.primary;
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }
}