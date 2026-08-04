// frontend/lib/features/cahier/presentation/widgets/cahier_page_controls.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/cahier_provider.dart';

class CahierPageControls extends StatelessWidget {
  const CahierPageControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CahierProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page précédente
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.goToPreviousPage,
            tooltip: 'Page précédente',
          ),

          // Indicateur de page
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Numéro de page
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    'Page ${provider.currentPageIndex + 1} / ${provider.pageCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Miniatures des pages
                if (!isMobile)
                  ...List.generate(
                    provider.pageCount > 5 ? 5 : provider.pageCount,
                    (index) {
                      final pageIndex = index;
                      final isActive = pageIndex == provider.currentPageIndex;
                      return GestureDetector(
                        onTap: () => provider.goToPage(pageIndex),
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                            border: isActive
                                ? Border.all(color: AppColors.primaryLight, width: 2)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Page suivante
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.goToNextPage,
            tooltip: 'Page suivante',
          ),

          const VerticalDivider(width: 8, thickness: 1),

          // Ajouter page
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: provider.canAddPage ? provider.addPage : null,
            tooltip: 'Ajouter une page',
            color: provider.canAddPage ? AppColors.primary : Colors.grey,
          ),

          // Supprimer page
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: provider.canDeletePage
                ? () => _showDeletePageDialog(context)
                : null,
            tooltip: 'Supprimer cette page',
            color: provider.canDeletePage ? Colors.red : Colors.grey,
          ),
        ],
      ),
    );
  }

  void _showDeletePageDialog(BuildContext context) {
    final provider = Provider.of<CahierProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la page'),
        content: Text(
          'Voulez-vous vraiment supprimer la page ${provider.currentPageIndex + 1} ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePage(provider.currentPageIndex);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}