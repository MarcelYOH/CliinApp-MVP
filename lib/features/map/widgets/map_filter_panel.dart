// lib/features/map/widgets/map_filter_panel.dart
// Panneau de filtres — Bottom Sheet modal — Page Carte — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/report_category.dart';
import '../models/map_filter_model.dart';

class MapFilterPanel extends StatefulWidget {
  final MapFilterState initialFilters;
  final ValueChanged<MapFilterState> onApply;

  const MapFilterPanel({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required MapFilterState initialFilters,
    required ValueChanged<MapFilterState> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapFilterPanel(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<MapFilterPanel> createState() => _MapFilterPanelState();
}

class _MapFilterPanelState extends State<MapFilterPanel> {
  late Set<ReportStatus>       _statuses;
  late Set<MapPriorityFilter>  _priorities;
  late Set<ReportCategory>     _categories;
  late Set<MapGravityFilter>   _gravities;

  @override
  void initState() {
    super.initState();
    _statuses    = Set.from(widget.initialFilters.statuses);
    _priorities  = Set.from(widget.initialFilters.priorities);
    _categories  = Set.from(widget.initialFilters.categories);
    _gravities   = Set.from(widget.initialFilters.gravities);
  }

  int get _totalActive =>
      _statuses.length + _priorities.length +
      _categories.length + _gravities.length;

  void _reset() => setState(() {
    _statuses.clear();
    _priorities.clear();
    _categories.clear();
    _gravities.clear();
  });

  void _apply() {
    widget.onApply(MapFilterState(
      statuses:   Set.from(_statuses),
      priorities: Set.from(_priorities),
      categories: Set.from(_categories),
      gravities:  Set.from(_gravities),
    ));
    Navigator.pop(context);
  }

  // ── Toggle helpers ────────────────────────────────────────────
  void _toggleStatus(ReportStatus s) => setState(() {
    _statuses.contains(s) ? _statuses.remove(s) : _statuses.add(s);
  });

  void _togglePriority(MapPriorityFilter p) => setState(() {
    _priorities.contains(p) ? _priorities.remove(p) : _priorities.add(p);
  });

  void _toggleCategory(ReportCategory c) => setState(() {
    _categories.contains(c) ? _categories.remove(c) : _categories.add(c);
  });

  void _toggleGravity(MapGravityFilter g) => setState(() {
    _gravities.contains(g) ? _gravities.remove(g) : _gravities.add(g);
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1, color: CliinAppColors.divider),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                CliinAppConstants.pagePadding,
                CliinAppConstants.spacingL,
                CliinAppConstants.pagePadding,
                CliinAppConstants.spacingXL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. État du signalement ──────────────────
                  _buildSectionTitle(
                    icon: Icons.swap_horiz_rounded,
                    title: 'État du signalement',
                    subtitle: 'Cycle de vie du cas',
                  ),
                  const SizedBox(height: CliinAppConstants.spacingM),
                  _buildStatusChips(),

                  _buildSectionDivider(),

                  // ── 2. Priorité d'action ────────────────────
                  _buildSectionTitle(
                    icon: Icons.bolt_rounded,
                    title: 'Priorité d\'action',
                    subtitle: 'Préparez vos interventions',
                    iconColor: const Color(0xFFFF9800),
                  ),
                  const SizedBox(height: CliinAppConstants.spacingM),
                  _buildPriorityChips(),

                  _buildSectionDivider(),

                  // ── 3. Catégories ───────────────────────────
                  _buildSectionTitle(
                    icon: Icons.category_outlined,
                    title: 'Catégories',
                    subtitle: 'Type de problème signalé',
                  ),
                  const SizedBox(height: CliinAppConstants.spacingM),
                  _buildCategoryChips(),

                  _buildSectionDivider(),

                  // ── 4. Niveau de gravité ────────────────────
                  _buildSectionTitle(
                    icon: Icons.warning_amber_rounded,
                    title: 'Niveau de gravité',
                    subtitle: 'Optionnel — indépendant de la priorité',
                    iconColor: const Color(0xFFE53935),
                  ),
                  const SizedBox(height: CliinAppConstants.spacingM),
                  _buildGravityChips(),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: CliinAppColors.divider),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Drag handle ───────────────────────────────────────────────
  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(
              top: CliinAppConstants.spacingM,
              bottom: CliinAppConstants.spacingS),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: CliinAppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(
          CliinAppConstants.pagePadding,
          CliinAppConstants.spacingS,
          CliinAppConstants.pagePadding,
          CliinAppConstants.spacingM,
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filtres',
                    style: CliinAppTextStyles.headingMedium
                        .copyWith(color: CliinAppColors.textDark)),
                if (_totalActive > 0)
                  Text('$_totalActive filtre${_totalActive > 1 ? 's' : ''} actif${_totalActive > 1 ? 's' : ''}',
                      style: CliinAppTextStyles.bodySmall
                          .copyWith(color: CliinAppColors.primary)),
              ],
            ),
          ),
          if (_totalActive > 0)
            GestureDetector(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.spacingM,
                    vertical: CliinAppConstants.spacingXS + 2),
                decoration: BoxDecoration(
                  color: CliinAppColors.alertRedBg,
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.close_rounded,
                      size: 14, color: CliinAppColors.alertRed),
                  const SizedBox(width: 4),
                  Text('Réinitialiser',
                      style: CliinAppTextStyles.badge.copyWith(
                          color: CliinAppColors.alertRed, fontSize: 11)),
                ]),
              ),
            ),
        ]),
      );

  // ── Titre de section ──────────────────────────────────────────
  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) =>
      Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (iconColor ?? CliinAppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
          ),
          child: Icon(icon,
              size: 18, color: iconColor ?? CliinAppColors.primary),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: CliinAppTextStyles.headingSmall
                  .copyWith(color: CliinAppColors.textDark, fontSize: 14)),
          Text(subtitle,
              style: CliinAppTextStyles.bodySmall
                  .copyWith(color: CliinAppColors.textSecondary, fontSize: 11)),
        ]),
      ]);

  Widget _buildSectionDivider() => Padding(
        padding: const EdgeInsets.symmetric(
            vertical: CliinAppConstants.spacingL),
        child: Container(height: 1, color: CliinAppColors.divider),
      );

  // ── 1. Chips état ─────────────────────────────────────────────
  Widget _buildStatusChips() => Wrap(
        spacing: CliinAppConstants.spacingS,
        runSpacing: CliinAppConstants.spacingS,
        children: [
          _statusChip(
            ReportStatus.disponible,
            label: 'Disponible',
            icon: Icons.circle,
            color: CliinAppColors.primary,
          ),
          _statusChip(
            ReportStatus.enCours,
            label: 'Pris en charge',
            icon: Icons.access_time_rounded,
            color: const Color(0xFFFF9800),
          ),
          _statusChip(
            ReportStatus.traite,
            label: 'Traité',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF1E88E5),
          ),
        ],
      );

  Widget _statusChip(ReportStatus s,
      {required String label,
      required IconData icon,
      required Color color}) {
    final isActive = _statuses.contains(s);
    return GestureDetector(
      onTap: () => _toggleStatus(s),
      child: _FilterChip(
          label: label, icon: icon, color: color, isActive: isActive),
    );
  }

  // ── 2. Chips priorité ─────────────────────────────────────────
  Widget _buildPriorityChips() => Wrap(
        spacing: CliinAppConstants.spacingS,
        runSpacing: CliinAppConstants.spacingS,
        children: MapPriorityFilter.values
            .map((p) => GestureDetector(
                  onTap: () => _togglePriority(p),
                  child: _FilterChip(
                    label: p.label,
                    icon: p.icon,
                    color: p.color,
                    isActive: _priorities.contains(p),
                  ),
                ))
            .toList(),
      );

  // ── 3. Chips catégories ───────────────────────────────────────
  Widget _buildCategoryChips() => Wrap(
        spacing: CliinAppConstants.spacingS,
        runSpacing: CliinAppConstants.spacingS,
        children: ReportCategory.values
            .map((c) => GestureDetector(
                  onTap: () => _toggleCategory(c),
                  child: _FilterChip(
                    label: c.label,
                    icon: c.icon,
                    color: c.color,
                    isActive: _categories.contains(c),
                  ),
                ))
            .toList(),
      );

  // ── 4. Chips gravité ──────────────────────────────────────────
  Widget _buildGravityChips() => Wrap(
        spacing: CliinAppConstants.spacingS,
        runSpacing: CliinAppConstants.spacingS,
        children: MapGravityFilter.values
            .map((g) => GestureDetector(
                  onTap: () => _toggleGravity(g),
                  child: _FilterChip(
                    label: g.label,
                    icon: g.icon,
                    color: g.color,
                    isActive: _gravities.contains(g),
                  ),
                ))
            .toList(),
      );

  // ── Footer : Appliquer ────────────────────────────────────────
  Widget _buildFooter() => Padding(
        padding: EdgeInsets.fromLTRB(
          CliinAppConstants.pagePadding,
          CliinAppConstants.spacingM,
          CliinAppConstants.pagePadding,
          CliinAppConstants.spacingM +
              MediaQuery.of(context).padding.bottom,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: CliinAppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
              ),
              elevation: 0,
            ),
            child: Text(
              _totalActive > 0
                  ? 'Appliquer ($_totalActive filtre${_totalActive > 1 ? 's' : ''})'
                  : 'Appliquer',
              style: CliinAppTextStyles.button
                  .copyWith(color: CliinAppColors.textWhite),
            ),
          ),
        ),
      );
}

// ── Widget chip générique réutilisable ────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(
          color: isActive ? color : CliinAppColors.divider,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 14,
            color: isActive ? color : CliinAppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label,
            style: CliinAppTextStyles.badge.copyWith(
              fontSize: 12,
              color: isActive ? color : CliinAppColors.textDark,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            )),
        if (isActive) ...[
          const SizedBox(width: 6),
          Icon(Icons.check_rounded, size: 13, color: color),
        ],
      ]),
    );
  }
}