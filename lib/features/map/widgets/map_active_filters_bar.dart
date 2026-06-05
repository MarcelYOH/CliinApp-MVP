// lib/features/map/widgets/map_active_filters_bar.dart
// Barre des filtres actifs — chips visibles — Page Carte — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/report_category.dart';
import '../models/map_filter_model.dart';

class MapActiveFiltersBar extends StatelessWidget {
  final MapFilterState filters;
  final VoidCallback? onClearAll;

  const MapActiveFiltersBar({
    super.key,
    required this.filters,
    this.onClearAll,
  });

  // ── Construit la liste plate de tous les chips actifs ─────────
  List<_ActiveChip> get _allChips {
    final chips = <_ActiveChip>[];

    // États
    for (final s in filters.statuses) {
      chips.add(_ActiveChip(
        label: _statusLabel(s),
        icon: _statusIcon(s),
        color: _statusColor(s),
      ));
    }

    // Priorités
    for (final p in filters.priorities) {
      chips.add(_ActiveChip(
        label: p.chipLabel,
        icon: p.icon,
        color: p.color,
      ));
    }

    // Catégories
    for (final c in filters.categories) {
      chips.add(_ActiveChip(
        label: c.label,
        icon: c.icon,
        color: c.color,
      ));
    }

    // Gravités
    for (final g in filters.gravities) {
      chips.add(_ActiveChip(
        label: g.label,
        icon: g.icon,
        color: g.color,
      ));
    }

    return chips;
  }

  String _statusLabel(ReportStatus s) {
    switch (s) {
      case ReportStatus.disponible: return 'Disponible';
      case ReportStatus.enCours:    return 'Pris en charge';
      case ReportStatus.traite:     return 'Traité';
    }
  }

  IconData _statusIcon(ReportStatus s) {
    switch (s) {
      case ReportStatus.disponible: return Icons.circle;
      case ReportStatus.enCours:    return Icons.access_time_rounded;
      case ReportStatus.traite:     return Icons.check_circle_rounded;
    }
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.disponible: return CliinAppColors.primary;
      case ReportStatus.enCours:    return const Color(0xFFFF9800);
      case ReportStatus.traite:     return const Color(0xFF1E88E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();

    final chips = _allChips;
    // Max 3 chips visibles
    const maxVisible = 3;
    final visible = chips.take(maxVisible).toList();
    final overflow = chips.length - maxVisible;

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding),
        children: [
          // Chips visibles
          ...visible.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _ActiveChipWidget(chip: chip),
              )),

          // +N si overflow
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CliinAppColors.background,
                  borderRadius: BorderRadius.circular(
                      CliinAppConstants.radiusMedium),
                  border: Border.all(color: CliinAppColors.divider),
                ),
                child: Text('+$overflow',
                    style: CliinAppTextStyles.badge.copyWith(
                        color: CliinAppColors.textSecondary,
                        fontSize: 11)),
              ),
            ),

          // Bouton tout effacer
          GestureDetector(
            onTap: onClearAll,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CliinAppColors.alertRedBg,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.close_rounded,
                    size: 12, color: CliinAppColors.alertRed),
                const SizedBox(width: 4),
                Text('Effacer tout',
                    style: CliinAppTextStyles.badge.copyWith(
                        color: CliinAppColors.alertRed, fontSize: 11)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip {
  final String label;
  final IconData icon;
  final Color color;
  const _ActiveChip(
      {required this.label, required this.icon, required this.color});
}

class _ActiveChipWidget extends StatelessWidget {
  final _ActiveChip chip;
  const _ActiveChipWidget({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chip.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: chip.color, width: 1.2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(chip.icon, size: 12, color: chip.color),
        const SizedBox(width: 5),
        Text(chip.label,
            style: CliinAppTextStyles.badge.copyWith(
                color: chip.color,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}