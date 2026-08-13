// frontend/lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/home_hero.dart';
import '../../widgets/home_features.dart';
import '../../widgets/home_news.dart';
import '../../widgets/home_cta.dart';
import '../../widgets/home_footer.dart';
import '../../widgets/home_drawer.dart';
import '../../widgets/home_menu_items.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/app_router.dart';


class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // On utilise LayoutBuilder pour avoir la largeur disponible
    return LayoutBuilder(
      builder: (context, constraints) {
        // Seuil de bascule vers le mobile
        final isMobile = constraints.maxWidth < 700;
        final logoSize = isMobile ? 34.0 : 44.0;
        final titleSize = isMobile ? 16.0 : 20.0;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                // Logo responsive
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '📚',
                      style: TextStyle(
                        fontSize: logoSize * 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'E-learningAI',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              // Si on est sur grand écran, on affiche le menu complet
              if (!isMobile) ...[
                ...HomeMenuItems.items.map((item) {
                  return TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(item['label']!),
                  );
                }).toList(),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    AppRouter.pushNamed(context, AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Se connecter'),
                  
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    AppRouter.pushNamed(context, AppRoutes.register);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('S\'inscrire'),
                ),
              ],
            ],
            // Sur mobile, on affiche le menu hamburger
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.primary),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  )
                : null,
          ),
          drawer: isMobile ? const HomeDrawer() : null, // drawer seulement sur mobile
          body: const SingleChildScrollView(
            child: Column(
              children: [
                HomeHero(),
                HomeFeatures(),
                HomeNews(),
                HomeCTA(),
                HomeFooter(),
              ],
            ),
          ),
        );
      },
    );
  }
}