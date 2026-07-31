// lib/features/profile/pages/mes_contributions_page.dart
// Entrée "Mes contributions" du Profil — statistiques réelles de
// contribution par groupe (Correction 8), basées sur ReportStore/GroupStore.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/groups/models/group_model.dart';
import '../../../features/groups/pages/group_profile_page.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/report_card.dart' show buildReportImage;

enum _SortOption { plusActif, alphabetique }

class _GroupContribution {
  final GroupModel group;
  final int casSignales;
  final int prisesEnCharge;
  final int actionsOrganisees;
  const _GroupContribution({
    required this.group,
    required this.casSignales,
    required this.prisesEnCharge,
    required this.actionsOrganisees,
  });
  int get total => casSignales + prisesEnCharge + actionsOrganisees;
}

class MesContributionsPage extends StatefulWidget {
  const MesContributionsPage({super.key});

  @override
  State<MesContributionsPage> createState() => _MesContributionsPageState();
}

class _MesContributionsPageState extends State<MesContributionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.plusActif;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_GroupContribution> get _allContributions {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return const [];
    final result = <_GroupContribution>[];
    for (final group in GroupStore.instance.allGroups) {
      final signales =
          ReportStore.instance.casSignalesCountForUserInGroup(group.id, userId);
      final prisesEnCharge = ReportStore.instance
          .prisEnChargeCountForUserInGroup(group.nom, userId);
      // Correction 2 — même structure que cas signalés/prises en charge,
      // jamais dupliquée sous une forme différente.
      final actionsOrganisees = ActionStore.instance
          .actionsOrganiseesCountForUserInGroup(group.id, userId);
      if (signales + prisesEnCharge + actionsOrganisees > 0) {
        result.add(_GroupContribution(
          group: group,
          casSignales: signales,
          prisesEnCharge: prisesEnCharge,
          actionsOrganisees: actionsOrganisees,
        ));
      }
    }
    return result;
  }

  List<_GroupContribution> get _filtered {
    var result = _allContributions;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result =
          result.where((c) => c.group.nom.toLowerCase().contains(q)).toList();
    }
    result = [...result];
    if (_sortOption == _SortOption.plusActif) {
      result.sort((a, b) => b.total.compareTo(a.total));
    } else {
      result.sort((a, b) =>
          a.group.nom.toLowerCase().compareTo(b.group.nom.toLowerCase()));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ReportStore.instance,
        GroupStore.instance,
        AuthStore.instance,
        ActionStore.instance,
      ]),
      builder: (context, _) {
        final userId = AuthStore.instance.currentUser?.id;
        final allContributions = _allContributions;
        final filtered = _filtered;
        final totalCasSignales = userId == null
            ? 0
            : ReportStore.instance.casSignalesTotalForUserAllGroups(userId);
        final totalPrisesEnCharge = userId == null
            ? 0
            : ReportStore.instance.prisEnChargeTotalForUserAllGroups(userId);
        final totalActionsOrganisees = userId == null
            ? 0
            : ActionStore.instance.actionsOrganiseesTotalForUserAllGroups(userId);

        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CliinAppConstants.pagePadding),
                  child: _buildSummaryCard(
                      totalCasSignales, totalPrisesEnCharge, totalActionsOrganisees),
                ),
                const SizedBox(height: CliinAppConstants.spacingL),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CliinAppConstants.pagePadding),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: CliinAppConstants.spacingM),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CliinAppConstants.pagePadding),
                  child: _buildSortPills(),
                ),
                const SizedBox(height: CliinAppConstants.spacingM),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(allContributions.isEmpty)
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              CliinAppConstants.pagePadding,
                              0,
                              CliinAppConstants.pagePadding,
                              MediaQuery.of(context).padding.bottom +
                                  CliinAppConstants.spacingXL),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: CliinAppConstants.spacingM),
                          itemBuilder: (context, i) =>
                              _buildGroupCard(context, filtered[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 12),
      child: Row(
        children: [
          CircleIconButton.back(
            onTap: () => Navigator.pop(context),
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Mes contributions',
                style: CliinAppTextStyles.headingMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      int totalCasSignales, int totalPrisesEnCharge, int totalActionsOrganisees) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.spacingL,
          vertical: CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryDark,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryColumn(
              value: totalCasSignales,
              label: 'Cas signalés\n(tous groupes)',
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: CliinAppColors.textWhite.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _buildSummaryColumn(
              value: totalPrisesEnCharge,
              label: 'Prises en charge\n(tous groupes)',
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: CliinAppColors.textWhite.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _buildSummaryColumn(
              value: totalActionsOrganisees,
              label: 'Actions organisées\n(tous groupes)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn({required int value, required String label}) {
    return Column(
      children: [
        Text(
          '$value',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: CliinAppColors.textWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CliinAppColors.textWhite.withValues(alpha: 0.85),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Rechercher un groupe...',
          hintStyle: CliinAppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            color: CliinAppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: CliinAppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : GestureDetector(
                  onTap: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                  child: const Icon(Icons.close_rounded,
                      color: CliinAppColors.textSecondary, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSortPills() {
    return Row(
      children: [
        _buildSortPill('Plus actif', _SortOption.plusActif),
        const SizedBox(width: 8),
        _buildSortPill('A → Z', _SortOption.alphabetique),
      ],
    );
  }

  Widget _buildSortPill(String label, _SortOption option) {
    final isSelected = _sortOption == option;
    return GestureDetector(
      onTap: () => setState(() => _sortOption = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CliinAppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CliinAppColors.primary : CliinAppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: CliinAppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : CliinAppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, _GroupContribution c) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        fastFadeRoute<void>(GroupProfilePage(groupId: c.group.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(CliinAppConstants.spacingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(c.group),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.group.nom,
                          style: CliinAppTextStyles.headingSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: CliinAppColors.textSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(c.group.zone,
                                style: CliinAppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: CliinAppColors.textSecondary),
              ],
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.folder_rounded,
                    value: c.casSignales,
                    label: 'Cas signalés',
                    bg: CliinAppColors.primaryLight,
                    color: CliinAppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.volunteer_activism_rounded,
                    value: c.prisesEnCharge,
                    label: 'Prises en charge',
                    bg: CliinAppColors.alertOrange.withValues(alpha: 0.1),
                    color: CliinAppColors.alertOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.bolt_rounded,
                    value: c.actionsOrganisees,
                    label: 'Actions organisées',
                    bg: CliinAppColors.levelEngage.withValues(alpha: 0.1),
                    color: CliinAppColors.levelEngage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            const Divider(height: 1, color: CliinAppColors.divider),
            const SizedBox(height: 8),
            Text(
              '${c.total} contribution${c.total > 1 ? 's' : ''} au total dans ce groupe',
              style: CliinAppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(GroupModel group) {
    const size = 44.0;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: CliinAppColors.primaryDark,
        shape: BoxShape.circle,
      ),
      child: group.photoPath != null
          ? ClipOval(
              child: buildReportImage(
                group.photoPath!,
                fit: BoxFit.cover,
                alignment: Alignment(0, group.photoAlignY),
                errorBuilder: (_, _, _) => _avatarInitials(group.nom),
              ),
            )
          : _avatarInitials(group.nom),
    );
  }

  Widget _avatarInitials(String nom) {
    final initials = nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase();
    return Center(
      child: Text(initials,
          style: const TextStyle(
              color: CliinAppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required int value,
    required String label,
    required Color bg,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noContributionsAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noContributionsAtAll
                  ? Icons.groups_outlined
                  : Icons.search_off_rounded,
              size: 56,
              color: CliinAppColors.textSecondary,
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(
              noContributionsAtAll
                  ? 'Vous n\'avez pas encore contribué à un groupe. '
                      'Signalez ou prenez en charge un cas au nom d\'un '
                      'groupe pour voir votre contribution ici.'
                  : 'Aucun groupe ne correspond à votre recherche.',
              textAlign: TextAlign.center,
              style: CliinAppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
