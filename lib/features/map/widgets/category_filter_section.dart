// lib/features/map/widgets/category_filter_section.dart
// Filtres catégories officielles MVP — multi-sélection — Page Carte — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/report_category.dart';

// On réexporte ReportCategory pour que map_page puisse l'importer depuis ici
export '../../../shared/models/report_category.dart' show ReportCategory;

class CategoryFilterSection extends StatelessWidget {
  final Set<ReportCategory> selected;
  final ValueChanged<Set<ReportCategory>> onChanged;

  const CategoryFilterSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(ReportCategory cat) {
    final next = Set<ReportCategory>.from(selected);
    if (next.contains(cat)) {
      next.remove(cat);
    } else {
      next.add(cat);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Section fixe ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: CliinAppConstants.pagePadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Catégorie',
                  style: CliinAppTextStyles.headingSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CliinAppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                // Icône Tout
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected.isEmpty
                        ? CliinAppColors.primaryLight
                        : CliinAppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    size: 15,
                    color: selected.isEmpty
                        ? CliinAppColors.primary
                        : CliinAppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                // Bouton Tout ▼
                GestureDetector(
                  onTap: () => onChanged({}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected.isEmpty
                          ? CliinAppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected.isEmpty
                            ? CliinAppColors.primary
                            : CliinAppColors.divider,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tout',
                          style: CliinAppTextStyles.badge.copyWith(
                            fontSize: 12,
                            color: selected.isEmpty
                                ? Colors.white
                                : CliinAppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: selected.isEmpty
                              ? Colors.white
                              : CliinAppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                    width: 1, height: 24, color: CliinAppColors.divider),
              ],
            ),
          ),

          // ── Chips scrollables — catégories officielles MVP ────
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: 10,
                right: CliinAppConstants.pagePadding,
              ),
              children: ReportCategory.values.map((cat) {
                final isActive = selected.contains(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _toggle(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? cat.color.withValues(alpha: 0.10)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isActive ? cat.color : CliinAppColors.divider,
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 13,
                            color: isActive
                                ? cat.color
                                : CliinAppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.label,
                            style: CliinAppTextStyles.badge.copyWith(
                              fontSize: 12,
                              color: isActive
                                  ? cat.color
                                  : CliinAppColors.textDark,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}