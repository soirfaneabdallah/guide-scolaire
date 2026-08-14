// frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../widgets/dashboard_subject_chat.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../cahier/presentation/screens/cahier_screen.dart';
import '../../../exercises/presentation/screens/exercices_screen.dart';
import '../../../exercises/providers/exercices_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      provider.loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<DashboardProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: isMobile ? _buildMobileAppBar() : null,
      drawer: isMobile ? const DashboardSidebar() : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: isTablet ? 72 : 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: AppColors.divider.withOpacity(0.5)),
                ),
              ),
              child: const DashboardSidebar(  // 👈 Supprimer isCompact pour l'instant
                isCompact: false,
              ),
            ),
          if (isDesktop)
            Container(
              width: 1,
              color: AppColors.divider.withOpacity(0.5),
            ),
          Expanded(
            child: _buildContent(provider, isMobile),
          ),
        ],
      ),
    );
  }

  AppBar _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: const Text(
        'E-learningAI',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: const Text(
            'M',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildContent(DashboardProvider provider, bool isMobile) {
    // Onglet 2 : Exercices
    if (provider.selectedIndex == 2) {
      return Builder(
        builder: (context) {
          return ChangeNotifierProvider(
            create: (_) => ExercicesProvider(),
            child: const ExercicesScreen(),
          );
        },
      );
    }

    // Onglet 3 : Cahier de correction
    if (provider.selectedIndex == 3) {
      return const CahierScreen();
    }

    // Onglet 4 : Bibliothèque
    if (provider.selectedIndex == 4) {
      return _BibliothequeView(isMobile: isMobile);
    }

    // Onglet 0 : Accueil (chat par matière)
    return DashboardSubjectChat(
      subjectSlug: provider.selectedSubjectSlug,
      isMobile: isMobile,
    );
  }
}

// ===== VUE BIBLIOTHÈQUE =====
class _BibliothequeView extends StatelessWidget {
  const _BibliothequeView({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: isMobile ? 40 : 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '📚 Bibliothèque numérique',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Page de la bibliothèque (à venir)',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


