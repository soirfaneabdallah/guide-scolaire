// frontend/lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../widgets/dashboard_subject_chat.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../cahier/presentation/screens/cahier_screen.dart';
import '../../../exercises/presentation/screens/exercices_screen.dart';
import '../../../exercises/providers/exercices_provider.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../library/providers/library_provider.dart';

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
      final auth = context.read<AuthProvider>();
      
      if (auth.isAuthenticated && auth.token != null) {
        provider.loadSubjectsWithAuth();
      } else {
        provider.loadSubjects();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<DashboardProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      // ✅ AppBar simple pour mobile
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const Text(
                'Guide Scolaire',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : null,
      drawer: isMobile
          ? const Drawer(child: DashboardSidebar())
          : null,
      body: Row(
        children: [
          // Sidebar Desktop
          if (!isMobile)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: AppColors.divider.withOpacity(0.5)),
                ),
              ),
              child: const DashboardSidebar(),
            ),
          // Contenu principal
          Expanded(
            child: _buildContent(provider, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DashboardProvider provider, bool isMobile) {
    // Exercices
    if (provider.selectedIndex == 2) {
      return ChangeNotifierProvider(
        create: (_) => ExercicesProvider(),
        child: const ExercicesScreen(),
      );
    }

    // Cahier
    if (provider.selectedIndex == 3) {
      return const CahierScreen();
    }

    // Bibliothèque
    if (provider.selectedIndex == 4) {
      return ChangeNotifierProvider<LibraryProvider>(
        create: (_) => LibraryProvider(
          apiClient: context.read<ApiClient>(),
        ),
        child: const LibraryScreen(),
      );
    }

    // Accueil (Chat)
    final subject = provider.selectedSubject;
    
    if (subject == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune matière disponible'),
            SizedBox(height: 8),
            Text('Ajoute une matière pour commencer'),
          ],
        ),
      );
    }

    return DashboardSubjectChat(
      subjectSlug: subject.slug,
      isMobile: isMobile,
    );
  }
}