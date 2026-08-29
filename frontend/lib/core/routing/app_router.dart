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
import '../../features/settings/presentation/screens/settings_screen.dart';  // ✅ AJOUTER
import '../network/api_client.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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

      // ✅ AJOUTER LA ROUTE SETTINGS
      case AppRoutes.settings:
        return _slideRoute(
          settings,
          (_) => const SettingsScreen(),
        );

      case AppRoutes.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialQuestion = args?['question'] as String?;
        final subjectId = args?['subjectId'] as int? ?? 1;

        return _slideRoute(
          settings,
          (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final apiClient = Provider.of<ApiClient>(context, listen: false);
            final chatRepository = ChatRepository(apiClient: apiClient);
            
            final chatProvider = ChatProvider(
              chatRepository: chatRepository,
              authProvider: authProvider,
              subjectId: subjectId,
            );
            
            return Provider<ChatProvider>(
              create: (_) => chatProvider,
              child: ChatScreen(
                initialQuestion: initialQuestion,
              ),
            );
          },
        );

      case String route when route.startsWith('/course/'):
        final id = route.split('/').last;
        return _fadeRoute(
          settings,
          (_) => Scaffold(
            appBar: AppBar(
              title: Text('Cours #$id'),
            ),
            body: Center(
              child: Text('Page du cours $id (à venir)'),
            ),
          ),
        );

      default:
        return _fadeRoute(
          settings,
          (_) => Scaffold(
            body: Center(
              child: Text(
                '🚫 Route non trouvée : ${settings.name}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
    }
  }

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
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Navigation helpers
  static void pushNamed(BuildContext context, String routeName,
      {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pushReplacementNamed(BuildContext context, String routeName,
      {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushNamedAndRemoveUntil(BuildContext context, String routeName,
      {Object? arguments}) {
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
}