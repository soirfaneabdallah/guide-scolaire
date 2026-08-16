// frontend/lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: _buildLogo(isMobile),
            centerTitle: false,
            actions: _buildActions(context, isMobile),
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.primary),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  )
                : null,
          ),
          drawer: isMobile ? const HomeDrawer() : null,
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

  // ============================================================
  //  LOGO
  // ============================================================

  Widget _buildLogo(bool isMobile) {
    final size = isMobile ? 28.0 : 36.0;
    final textSize = isMobile ? 14.0 : 18.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Logo SVG
        SvgPicture.asset(
          'assets/images/logo.svg',
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.primary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        // ✅ Texte E-learningAI
        Text(
          'E-learningAI',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  ACTIONS DE L'APP BAR
  // ============================================================

  List<Widget> _buildActions(BuildContext context, bool isMobile) {
    if (isMobile) {
      return []; // Sur mobile, les boutons sont dans le drawer
    }

    return [
      ...HomeMenuItems.items.map((item) {
        return TextButton(
          onPressed: () {
            // Navigation vers les sections
            _scrollToSection(context, item['section'] as String);
          },
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
    ];
  }

  // ============================================================
  //  SCROLL VERS UNE SECTION
  // ============================================================

  void _scrollToSection(BuildContext context, String section) {
    // Trouver le ScrollController dans le contexte
    final scrollView = context.findAncestorWidgetOfExactType<SingleChildScrollView>();
    if (scrollView != null) {
      // Logique de scroll vers la section
      // À implémenter selon vos besoins
    }
  }
}