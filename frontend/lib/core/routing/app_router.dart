// frontend/lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_page.dart';
import '../../features/auth/presentation/screens/register_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // 🏠 Accueil
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => HomeScreen(), // pas de const
        );
      
      // 🔐 Connexion
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(), // pas de const
        );
      
      // 📝 Inscription (placeholder temporaire)
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => RegisterPage(),
        );
      
      // 📊 Tableau de bord (placeholder temporaire)
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Tableau de bord'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    // TODO: Déconnexion
                  },
                ),
              ],
            ),
            body: const Center(
              child: Text('Bienvenue sur votre tableau de bord !'),
            ),
          ),
        );
      
      // 📄 Détail d'un cours (ex: /course/123)
      case String route when route.startsWith('/course/'):
        final id = route.split('/').last;
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Détail du cours #$id')),
            body: Center(
              child: Text('Cours ID : $id'),
            ),
          ),
        );
      
      // 🔄 Route par défaut (404)
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
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

  // --- Utilitaires de navigation ---

  static void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushNamedAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false, arguments: arguments);
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