// frontend/lib/features/exercices/presentation/widgets/exercice_filter.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/exercices_provider.dart';

class ExerciceFilter extends StatelessWidget {
  const ExerciceFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExercicesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Rechercher un exercice...',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 12),

          // Filtres
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Matière',
                  value: provider.selectedSubject,
                  items: provider.subjects,
                  onChanged: provider.setSubject,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  label: 'Niveau',
                  value: provider.selectedLevel,
                  items: provider.levels,
                  onChanged: provider.setLevel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  label: 'Difficulté',
                  value: provider.selectedDifficulty,
                  items: provider.difficulties,
                  onChanged: provider.setDifficulty,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear_all, color: AppColors.primary),
                onPressed: provider.resetFilters,
                tooltip: 'Réinitialiser les filtres',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: (value) => onChanged(value!),
      isDense: true,
      icon: const Icon(Icons.arrow_drop_down),
    );
  }
}