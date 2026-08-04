// frontend/lib/features/cahier/presentation/widgets/cahier_toolbar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/cahier_provider.dart';

class CahierToolbar extends StatelessWidget {
  const CahierToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CahierProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Couleurs
          _ColorButton(
            color: Colors.black,
            isSelected: provider.selectedColor == Colors.black && !provider.isEraser,
            onTap: () => provider.setColor(Colors.black),
          ),
          _ColorButton(
            color: Colors.red,
            isSelected: provider.selectedColor == Colors.red && !provider.isEraser,
            onTap: () => provider.setColor(Colors.red),
          ),
          _ColorButton(
            color: Colors.blue,
            isSelected: provider.selectedColor == Colors.blue && !provider.isEraser,
            onTap: () => provider.setColor(Colors.blue),
          ),
          _ColorButton(
            color: Colors.green,
            isSelected: provider.selectedColor == Colors.green && !provider.isEraser,
            onTap: () => provider.setColor(Colors.green),
          ),
          _ColorButton(
            color: Colors.orange,
            isSelected: provider.selectedColor == Colors.orange && !provider.isEraser,
            onTap: () => provider.setColor(Colors.orange),
          ),
          const VerticalDivider(width: 16, thickness: 1),

          // Taille du stylo
          _SizeButton(
            size: 2,
            isSelected: provider.strokeWidth == 2,
            onTap: () => provider.setStrokeWidth(2),
          ),
          _SizeButton(
            size: 4,
            isSelected: provider.strokeWidth == 4,
            onTap: () => provider.setStrokeWidth(4),
          ),
          _SizeButton(
            size: 6,
            isSelected: provider.strokeWidth == 6,
            onTap: () => provider.setStrokeWidth(6),
          ),
          const VerticalDivider(width: 16, thickness: 1),

          // Gomme
          IconButton(
            icon: Icon(
              Icons.cleaning_services,
              color: provider.isEraser ? AppColors.primary : null,
            ),
            onPressed: provider.toggleEraser,
            tooltip: 'Gomme',
          ),

          // Annuler / Rétablir
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: provider.canUndo ? provider.undo : null,
            tooltip: 'Annuler',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: provider.canRedo ? provider.redo : null,
            tooltip: 'Rétablir',
          ),

          // Effacer tout
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearDialog(context);
            },
            tooltip: 'Effacer tout',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer tout'),
        content: const Text('Voulez-vous vraiment effacer tout le contenu ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<CahierProvider>(context, listen: false);
              provider.clearCanvas();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Container(
          width: size + 4,
          height: size + 4,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}