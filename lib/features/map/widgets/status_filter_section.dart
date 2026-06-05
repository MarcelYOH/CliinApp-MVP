// lib/features/map/widgets/status_filter_section.dart
// Filtres statut — multi-sélection — Page Carte — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

enum MapStatusFilter {
  urgents,
  proches,
  recents,
  traites,
  enCours,
  nonTraites,
}

extension MapStatusFilterExt on MapStatusFilter {
  String get label {
    switch (this) {
      case MapStatusFilter.urgents:    return 'Urgents';
      case MapStatusFilter.proches:    return 'Proches';
      case MapStatusFilter.recents:    return 'Récents';
      case MapStatusFilter.traites:    return 'Traités';
      case MapStatusFilter.enCours:    return 'En cours';
      case MapStatusFilter.nonTraites: return 'Non traités';
    }
  }

  IconData get icon {
    switch (this) {
      case MapStatusFilter.urgents:    return Icons.warning_amber_rounded;
      case MapStatusFilter.proches:    return Icons.location_on_rounded;
      case MapStatusFilter.recents:    return Icons.access_time_rounded;
      case MapStatusFilter.traites:    return Icons.check_circle_rounded;
      case MapStatusFilter.enCours:    return Icons.autorenew_rounded;
      case MapStatusFilter.nonTraites: return Icons.cancel_outlined;
    }
  }

  Color get activeColor {
    switch (this) {
      case MapStatusFilter.urgents:    return const Color(0xFFE53935);
      case MapStatusFilter.proches:    return CliinAppColors.primary;
      case MapStatusFilter.recents:    return const Color(0xFF1E88E5);
      case MapStatusFilter.traites:    return CliinAppColors.primary;
      case MapStatusFilter.enCours:    return const Color(0xFFFF9800);
      case MapStatusFilter.nonTraites: return CliinAppColors.textSecondary;
    }
  }
}

class StatusFilterSection extends StatelessWidget {
  final Set<MapStatusFilter> selected;
  final ValueChanged<Set<MapStatusFilter>> onChanged;

  const StatusFilterSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(MapStatusFilter filter) {
    final next = Set<MapStatusFilter>.from(selected);
    if (next.contains(filter)) {
      next.remove(filter);
    } else {
      next.add(filter);
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
                  'Statut',
                  style: CliinAppTextStyles.headingSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CliinAppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
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
                    Icons.layers_rounded,
                    size: 15,
                    color: selected.isEmpty
                        ? CliinAppColors.primary
                        : CliinAppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
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

          // ── Chips scrollables ─────────────────────────────────
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: 10,
                right: CliinAppConstants.pagePadding,
              ),
              children: MapStatusFilter.values.map((filter) {
                final isActive = selected.contains(filter);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _toggle(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? filter.activeColor.withValues(alpha: 0.10)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? filter.activeColor
                              : CliinAppColors.divider,
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(filter.icon,
                              size: 13,
                              color: isActive
                                  ? filter.activeColor
                                  : CliinAppColors.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            filter.label,
                            style: CliinAppTextStyles.badge.copyWith(
                              fontSize: 12,
                              color: isActive
                                  ? filter.activeColor
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