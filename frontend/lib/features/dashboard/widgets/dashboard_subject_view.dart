// frontend/lib/features/dashboard/presentation/widgets/dashboard_subject_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../videos/data/repositories/video_repository.dart';
import '../../videos/domain/entities/video_script.dart';
import '../../videos/presentation/providers/video_provider.dart';
import '../../videos/presentation/widgets/video_card.dart';
import '../providers/dashboard_provider.dart';

/// Widget central affiché lorsqu'une matière est sélectionnée.
class DashboardSubjectView extends StatefulWidget {
  const DashboardSubjectView({
    super.key,
    required this.subjectSlug,
    this.isMobile = false,
  });

  final String subjectSlug;
  final bool isMobile;

  @override
  State<DashboardSubjectView> createState() => _DashboardSubjectViewState();
}

class _DashboardSubjectViewState extends State<DashboardSubjectView> {
  final TextEditingController _searchController = TextEditingController();
  late VideoProvider _videoProvider;
  String? _selectedLevel;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    final authProvider = context.read<AuthProvider>();
    final apiClient = context.read<ApiClient>();

    // ✅ Niveau de l'élève par défaut
    _selectedLevel = authProvider.userLevel ?? '3ème';

    _videoProvider = VideoProvider(
      videoRepository: VideoRepository(apiClient: apiClient),
      authProvider: authProvider,
    );

    // Charger les vidéos après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadVideos() {
    final dashboardProvider = context.read<DashboardProvider>();
    final subject = dashboardProvider.selectedSubject;
    if (subject != null) {
      _videoProvider.loadVideosBySubject(
        subjectId: subject.id,
        level: _selectedLevel,
      );
    }
  }

  void _onLevelChanged(String newLevel) {
    setState(() {
      _selectedLevel = newLevel;
    });
    _loadVideos();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });
  }

  // ✅ Filtrer les vidéos par recherche
  List<VideoScript> _getFilteredVideos(List<VideoScript> videos) {
    if (_searchQuery.isEmpty) return videos;
    return videos.where((v) {
      return v.title.toLowerCase().contains(_searchQuery) ||
          (v.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          v.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final subject = dashboardProvider.selectedSubject;
        if (subject == null) {
          return _buildNoSubject(isDark);
        }

        return Container(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          child: ChangeNotifierProvider<VideoProvider>.value(
            value: _videoProvider,
            child: Column(
              children: [
                // HEADER
                _buildHeader(subject.name, isDark),

                // BARRE DE RECHERCHE
                _buildSearchBar(isDark),

                // LISTE DES VIDÉOS
                Expanded(
                  child: Consumer<VideoProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (provider.error != null) {
                        return _buildError(provider.error!, isDark);
                      }

                      final filteredVideos =
                          _getFilteredVideos(provider.videos);

                      if (filteredVideos.isEmpty) {
                        return _buildEmpty(isDark);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredVideos.length,
                        itemBuilder: (context, index) {
                          final video = filteredVideos[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: VideoCard(
                              video: video,
                              subjectColor: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              onTap: () => _openVideo(video),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(String subjectName, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 20,
        vertical: widget.isMobile ? 10 : 14,
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
          // Nom de la matière
          Expanded(
            child: Text(
              subjectName,
              style: TextStyle(
                fontSize: widget.isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Sélecteur de niveau
          _buildLevelDropdown(isDark),

          const SizedBox(width: 8),

          // Bouton Créer une vidéo
          _buildCreateVideoButton(isDark),

          const SizedBox(width: 8),

          // Bouton Chat
          _buildChatButton(isDark),
        ],
      ),
    );
  }

  // ============================================================
  // SÉLECTEUR DE NIVEAU
  // ============================================================

  Widget _buildLevelDropdown(bool isDark) {
    const levels = [
      '6ème', '5ème', '4ème', '3ème',
      'Seconde', 'Première', 'Terminale',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedLevel,
        underline: const SizedBox(),
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: isDark ? AppColors.textWhite : AppColors.textPrimary,
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textWhite : AppColors.textPrimary,
        ),
        items: levels.map((level) {
          return DropdownMenuItem<String>(
            value: level,
            child: Text(level),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _onLevelChanged(value);
          }
        },
      ),
    );
  }

  // ============================================================
  // BOUTON CRÉER UNE VIDÉO
  // ============================================================

  Widget _buildCreateVideoButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCreateVideo,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : AppColors.textPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 16,
                color: isDark ? AppColors.textPrimary : Colors.white,
              ),
              if (!widget.isMobile) ...[
                const SizedBox(width: 6),
                Text(
                  'Créer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textPrimary : Colors.white,
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
  // BOUTON CHAT
  // ============================================================

  Widget _buildChatButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openSubjectChat,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
              if (!widget.isMobile) ...[
                const SizedBox(width: 6),
                Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
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
  // BARRE DE RECHERCHE
  // ============================================================

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.isMobile ? 12 : 20,
        12,
        widget.isMobile ? 12 : 20,
        4,
      ),
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher une vidéo...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÉTATS
  // ============================================================

  Widget _buildNoSubject(bool isDark) {
    return Center(
      child: Text(
        'Sélectionne une matière',
        style: TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildError(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
            const Icon(
              Icons.video_library_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucune vidéo trouvée'
                  : 'Aucune vidéo pour $_selectedLevel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Essaie un autre mot-clé'
                  : 'Aucune vidéo disponible pour ce niveau',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS (une seule fois !)
  // ============================================================

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

  void _openSubjectChat() {
    final dashboardProvider = context.read<DashboardProvider>();
    final subject = dashboardProvider.selectedSubject;
    if (subject == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {
        'subjectId': subject.id,
        'subjectName': subject.name,
      },
    );
  }

  void _openCreateVideo() {
    final dashboardProvider = context.read<DashboardProvider>();
    final subject = dashboardProvider.selectedSubject;
    if (subject == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.createVideo,
      arguments: {
        'subjectId': subject.id,
        'subjectName': subject.name,
        'level': _selectedLevel,
      },
    );
  }
}