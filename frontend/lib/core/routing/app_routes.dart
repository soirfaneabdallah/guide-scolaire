// frontend/lib/core/routing/app_routes.dart

class AppRoutes {
  AppRoutes._();

  // ============================================================
  // ROUTES DE BASE
  // ============================================================
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';

  // ============================================================
  // PROFIL & PARAMÈTRES
  // ============================================================
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String settingsGeneral = '/settings/general';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsPrivacy = '/settings/privacy';

  // ============================================================
  // VIDÉOS (Video-First)
  // ============================================================
  /// Page d'accueil principale (Video-First) - affichée après connexion
  static const String homeVideos = '/home-videos';

  /// Vidéos d'une matière spécifique
  static const String subjectVideos = '/subject-videos';

  /// Lecteur vidéo
  static const String videoPlayer = '/video';

  /// Création d'une vidéo personnalisée
  static const String createVideo = '/create-video';

  /// Recherche de vidéos
  static const String search = '/search';

  // ============================================================
  // CHAT & SUPPORT
  // ============================================================
  static const String chat = '/chat';

  // ============================================================
  // AUTRES
  // ============================================================
  static const String courses = '/courses';
  static const String exercises = '/exercises';
  static const String handwriting = '/handwriting';

  // ============================================================
  // ROUTES DYNAMIQUES
  // ============================================================
  static String courseDetail(String id) => '/course/$id';
  static String videoDetail(String scriptId) => '/video/$scriptId';
}