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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ===== Outils =====
            _ToolButton(
              icon: Icons.edit_outlined,
              isSelected: provider.currentTool == ToolType.pen,
              onTap: () => provider.setTool(ToolType.pen),
              tooltip: 'Stylo',
            ),
            _ToolButton(
              icon: Icons.cleaning_services,
              isSelected: provider.currentTool == ToolType.eraser,
              onTap: () => provider.setTool(ToolType.eraser),
              tooltip: 'Gomme',
            ),
            const VerticalDivider(width: 8, thickness: 1),

            // ===== Formes =====
            _ToolButton(
              icon: Icons.horizontal_rule,
              isSelected: provider.currentTool == ToolType.line,
              onTap: () => provider.setTool(ToolType.line),
              tooltip: 'Ligne',
            ),
            _ToolButton(
              icon: Icons.crop_square,
              isSelected: provider.currentTool == ToolType.rectangle,
              onTap: () => provider.setTool(ToolType.rectangle),
              tooltip: 'Rectangle',
            ),
            _ToolButton(
              icon: Icons.circle_outlined,
              isSelected: provider.currentTool == ToolType.circle,
              onTap: () => provider.setTool(ToolType.circle),
              tooltip: 'Cercle',
            ),
            _ToolButton(
              icon: Icons.text_fields,
              isSelected: provider.currentTool == ToolType.text,
              onTap: () => provider.setTool(ToolType.text),
              tooltip: 'Texte',
            ),
            const VerticalDivider(width: 8, thickness: 1),

            // ===== Couleurs =====
            _ColorButton(
              color: Colors.black,
              isSelected: provider.selectedColor == Colors.black,
              onTap: () => provider.setColor(Colors.black),
            ),
            _ColorButton(
              color: Colors.red,
              isSelected: provider.selectedColor == Colors.red,
              onTap: () => provider.setColor(Colors.red),
            ),
            _ColorButton(
              color: Colors.blue,
              isSelected: provider.selectedColor == Colors.blue,
              onTap: () => provider.setColor(Colors.blue),
            ),
            _ColorButton(
              color: Colors.green,
              isSelected: provider.selectedColor == Colors.green,
              onTap: () => provider.setColor(Colors.green),
            ),
            _ColorButton(
              color: Colors.orange,
              isSelected: provider.selectedColor == Colors.orange,
              onTap: () => provider.setColor(Colors.orange),
            ),
            const VerticalDivider(width: 8, thickness: 1),

            // ===== Taille =====
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
            const VerticalDivider(width: 8, thickness: 1),

            // ===== Options =====
            IconButton(
              icon: Icon(
                Icons.format_color_fill,  // ✅ CORRIGÉ
                color: provider.isFilled ? AppColors.primary : null,
              ),
              onPressed: provider.toggleFilled,
              tooltip: 'Remplir',
            ),
            IconButton(
              icon: Icon(
                Icons.grid_on,
                color: provider.showGrid ? AppColors.primary : null,
              ),
              onPressed: provider.toggleGrid,
              tooltip: 'Lignes du cahier',
            ),
            const VerticalDivider(width: 8, thickness: 1),

            // ===== Actions =====
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
              provider.clearAll();
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

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppColors.primary : null,
      ),
      onPressed: onTap,
      tooltip: tooltip,
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
        width: 28,
        height: 28,
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
        width: 28,
        height: 28,
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