// frontend/lib/core/routing/app_routes.dart

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';  // Nouvelle route
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String courses = '/courses';
  static const String exercises = '/exercises';
  static const String handwriting = '/handwriting';
  static const String chat = '/chat';

  static String courseDetail(String id) => '/course/$id';
}