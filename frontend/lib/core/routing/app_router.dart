// frontend/lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/screens/login_page.dart';
import '../../features/auth/presentation/screens/register_page.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/chat/repositories/chat_repository.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/videos/presentation/screens/home_videos_screen.dart';
import '../../features/videos/presentation/screens/subject_videos_screen.dart';
import '../../features/videos/data/repositories/video_repository.dart';
import '../../features/videos/presentation/providers/video_provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../network/api_client.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ============================================================
      // ROUTES DE BASE
      // ============================================================
      case AppRoutes.home:
        return _fadeRoute(
          settings,
          (_) =>  HomeScreen(),
        );

      case AppRoutes.dashboard:
        return _fadeRoute(
          settings,
          (_) => const DashboardScreen(),
        );

      case AppRoutes.login:
        return _fadeRoute(
          settings,
          (_) => const LoginPage(),
        );

      case AppRoutes.register:
        return _fadeRoute(
          settings,
          (_) => const RegisterPage(),
        );

      case AppRoutes.profileEdit:
        return _slideRoute(
          settings,
          (_) => const ProfileEditScreen(),
        );

      case AppRoutes.settings:
        return _slideRoute(
          settings,
          (_) => const SettingsScreen(),
        );

      // ============================================================
      // ✅ NOUVELLE ROUTE : ACCUEIL VIDÉOS (Video-First)
      // ============================================================
      case AppRoutes.homeVideos:
        return _fadeRoute(
          settings,
          (context) {
            final apiClient = Provider.of<ApiClient>(context, listen: false);
            final authProvider = Provider.of<AuthProvider>(context, listen: false);

            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => VideoProvider(
                    videoRepository: VideoRepository(apiClient: apiClient),
                    authProvider: authProvider,
                  ),
                ),
              ],
              child: const HomeVideosScreen(),
            );
          },
        );

      // ============================================================
      // ✅ NOUVELLE ROUTE : VIDÉOS PAR MATIÈRE
      // ============================================================
      case AppRoutes.subjectVideos:
        final args = settings.arguments as Map<String, dynamic>?;
        
        if (args == null) {
          return _errorRoute('Arguments manquants pour les vidéos de matière');
        }

        final subjectId = args['subjectId'] as int?;
        final subjectName = args['subjectName'] as String?;
        final subjectIcon = args['subjectIcon'] as String? ?? '📚';
        final subjectColor = args['subjectColor'] as String?;

        if (subjectId == null || subjectName == null) {
          return _errorRoute('Matière invalide');
        }

        return _slideRoute(
          settings,
          (context) {
            final apiClient = Provider.of<ApiClient>(context, listen: false);
            final authProvider = Provider.of<AuthProvider>(context, listen: false);

            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => VideoProvider(
                    videoRepository: VideoRepository(apiClient: apiClient),
                    authProvider: authProvider,
                  ),
                ),
              ],
              child: SubjectVideosScreen(
                subjectId: subjectId,
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                subjectColor: _parseColor(subjectColor),
              ),
            );
          },
        );

      // ============================================================
      // ✅ NOUVELLE ROUTE : LECTEUR VIDÉO
      // ============================================================
      case AppRoutes.videoPlayer:
        final args = settings.arguments as Map<String, dynamic>?;
        
        if (args == null || args['scriptId'] == null) {
          return _errorRoute('ID de vidéo manquant');
        }

        final scriptId = args['scriptId'] as String;

        return _slideRoute(
          settings,
          (context) {
            final apiClient = Provider.of<ApiClient>(context, listen: false);
            final authProvider = Provider.of<AuthProvider>(context, listen: false);

            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => VideoProvider(
                    videoRepository: VideoRepository(apiClient: apiClient),
                    authProvider: authProvider,
                  ),
                ),
              ],
              // TODO: Créer VideoPlayerScreen
              child: Scaffold(
                appBar: AppBar(title: const Text('Lecteur vidéo')),
                body: Center(
                  child: Text('Lecteur vidéo pour : $scriptId\n(À venir)'),
                ),
              ),
            );
          },
        );

      // ============================================================
      // ✅ NOUVELLE ROUTE : CRÉER UNE VIDÉO
      // ============================================================
      case AppRoutes.createVideo:
        final args = settings.arguments as Map<String, dynamic>?;
        final subjectId = args?['subjectId'] as int?;
        final subjectName = args?['subjectName'] as String?;
        final level = args?['level'] as String?;

        return _slideRoute(
          settings,
          (context) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  subjectName != null
                      ? 'Créer une vidéo - $subjectName'
                      : 'Créer une vidéo',
                ),
              ),
              body: Center(
                child: Text(
                  'Création de vidéo\n'
                  'Matière: ${subjectName ?? "générale"}\n'
                  'Niveau: ${level ?? "3ème"}\n'
                  '(À venir)',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );

      // ============================================================
      // ✅ NOUVELLE ROUTE : RECHERCHE
      // ============================================================
      case AppRoutes.search:
        return _fadeRoute(
          settings,
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Recherche')),
            body: const Center(
              child: Text('Page de recherche (À venir)'),
            ),
          ),
        );


      // ============================================================
      // CHAT
      // ============================================================
      case AppRoutes.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialQuestion = args?['question'] as String?;
        final subjectId = args?['subjectId'] as int? ?? 1;
        final subjectName = args?['subjectName'] as String?;  // ✅ AJOUTÉ

        return _slideRoute(
          settings,
          (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final apiClient = Provider.of<ApiClient>(context, listen: false);
            final chatRepository = ChatRepository(apiClient: apiClient);

            return ChangeNotifierProvider<ChatProvider>(
              create: (_) => ChatProvider(
                chatRepository: chatRepository,
                authProvider: authProvider,
                subjectId: subjectId,
              ),
              child: ChatScreen(
                initialQuestion: initialQuestion,
                subjectName: subjectName,  // ✅ PASSÉ
              ),
            );
          },
        );
      // ============================================================
      // ROUTES DYNAMIQUES
      // ============================================================
      case String route when route.startsWith('/course/'):
        final id = route.split('/').last;
        return _fadeRoute(
          settings,
          (_) => Scaffold(
            appBar: AppBar(title: Text('Cours #$id')),
            body: Center(
              child: Text('Page du cours $id (à venir)'),
            ),
          ),
        );

      // ============================================================
      // ROUTE PAR DÉFAUT (erreur 404)
      // ============================================================
      default:
        return _errorRoute('Route non trouvée : ${settings.name}');
    }
  }

  // ============================================================
  // ROUTE D'ERREUR
  // ============================================================

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TRANSITIONS
  // ============================================================

  static Route<T> _fadeRoute<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeInOut),
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> _slideRoute<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuad;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  /// Convertit une chaîne hexadécimale en Color
  static Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return const Color(0xFF4F46E5); // Couleur primaire par défaut
    }

    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF4F46E5);
    }
  }

  // ============================================================
  // NAVIGATION HELPERS
  // ============================================================

  static void pushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pushReplacementNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushNamedAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  static void goToLogin(BuildContext context) {
    pushNamedAndRemoveUntil(context, AppRoutes.login);
  }

  static void goToDashboard(BuildContext context) {
    pushReplacementNamed(context, AppRoutes.dashboard);
  }

  static void goToHomeVideos(BuildContext context) {
    pushReplacementNamed(context, AppRoutes.homeVideos);
  }
}