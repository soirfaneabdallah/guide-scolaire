// frontend/lib/features/home/widgets/home_footer.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0A1929), // Bleu profond moderne
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
            vertical: isMobile ? 40 : 60,
          ),
          child: Column(
            children: [
              // Logo et newsletter (optionnel)
              if (!isMobile) _buildTopSection(),
              if (!isMobile) const SizedBox(height: 40),
              
              // Liens principaux
              _buildMainLinks(isMobile),
              
              const SizedBox(height: 40),
              
              // Réseaux sociaux et copyright
              _buildBottomSection(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo et description
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '📚',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Guide Scolaire',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        
        // Newsletter (optionnel)
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Votre email',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('S\'inscrire'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainLinks(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildMobileSection(
            title: 'App',
            links: ['Fonctionnalités', 'Télécharger', 'FAQ'],
          ),
          const SizedBox(height: 32),
          _buildMobileSection(
            title: 'À propos',
            links: ['Qui sommes-nous', 'Blog', 'Contact'],
          ),
          const SizedBox(height: 32),
          _buildMobileSection(
            title: 'Légal',
            links: ['Confidentialité', 'CGU', 'Mentions légales'],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDesktopColumn(
          title: 'App',
          links: ['Fonctionnalités', 'Télécharger', 'FAQ', 'API'],
        ),
        _buildDesktopColumn(
          title: 'À propos',
          links: ['Qui sommes-nous', 'Blog', 'Carrières', 'Contact'],
        ),
        _buildDesktopColumn(
          title: 'Ressources',
          links: ['Documentation', 'Tutoriels', 'Support', 'Communauté'],
        ),
        _buildDesktopColumn(
          title: 'Légal',
          links: ['Confidentialité', 'CGU', 'Mentions légales', 'Cookies'],
        ),
      ],
    );
  }

  Widget _buildDesktopColumn({
    required String title,
    required List<String> links,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => _buildFooterLink(link)),
      ],
    );
  }

  Widget _buildMobileSection({
    required String title,
    required List<String> links,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: links.map((link) => _buildMobileLink(link)).toList(),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: Colors.white70,
          overlayColor: Colors.white.withOpacity(0.1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLink(String text) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          foregroundColor: Colors.white70,
          overlayColor: Colors.white.withOpacity(0.1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isMobile) {
    return Column(
      children: [
        // Réseaux sociaux
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.facebook,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              icon: Icons.telegram,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              icon: Icons.link,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              icon: Icons.alternate_email,
              onPressed: () {},
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Copyright
        const Divider(color: Colors.white24),
        const SizedBox(height: 20),
        
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 10,
          children: [
            const Text(
              '© 2026 Guide Scolaire Comores. Tous droits réservés.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
            if (!isMobile) ...[
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white30,
                  shape: BoxShape.circle,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: Colors.white60,
                ),
                child: const Text(
                  'Mentions légales',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white30,
                  shape: BoxShape.circle,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: Colors.white60,
                ),
                child: const Text(
                  'CGU',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}