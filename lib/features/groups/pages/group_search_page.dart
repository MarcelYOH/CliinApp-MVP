// lib/features/groups/pages/group_search_page.dart
//
// Page UNIQUE de recherche de groupes — réutilisée peu importe l'origine du
// clic ("Groupes actifs" Voir tout, "Mes groupes" Voir plus, "Découvrir"
// Voir plus) : seul le titre du header change selon [origine].

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/user_location_service.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/widgets/group_badge_chip.dart';
import '../../../shared/widgets/group_card.dart';
import '../models/group_model.dart';

enum _SortOption { actifs, recents, proches }

class GroupSearchPage extends StatefulWidget {
  // "actifs" | "mesgroupes" | "decouvrir" — détermine uniquement le titre
  // affiché dans le header ; la recherche/les filtres portent toujours sur
  // l'ensemble des groupes (GroupStore.rechercherGroupes()).
  final String origine;

  const GroupSearchPage({super.key, required this.origine});

  @override
  State<GroupSearchPage> createState() => _GroupSearchPageState();
}

class _GroupSearchPageState extends State<GroupSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GroupType? _selectedType;
  String? _selectedNiveau;
  _SortOption? _selectedSort;

  @override
  void initState() {
    super.initState();
    // Rafraîchit/amorce l'ancre de position partagée — même motif que
    // map_page.dart (aucun listener dédié : la position se stabilise pour
    // les tris ultérieurs sans bloquer l'affichage initial).
    UserLocationService.instance.getCurrentPosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _headerTitle => switch (widget.origine) {
        'actifs' => 'Groupes actifs',
        'mesgroupes' => 'Mes groupes',
        'decouvrir' => 'Découvrir des groupes',
        _ => 'Tous les groupes',
      };

  int _badgeRank(GroupModel g) {
    if (g.badges.contains('officiel')) return 3;
    if (g.badges.contains('impact')) return 2;
    if (g.badges.contains('engage')) return 1;
    return 0;
  }

  List<GroupModel> get _results {
    final base = GroupStore.instance.rechercherGroupes(
      _searchQuery,
      type: _selectedType,
      niveauImpact: _selectedNiveau,
    );
    final sorted = List<GroupModel>.from(base);
    switch (_selectedSort) {
      case _SortOption.actifs:
        sorted.sort((a, b) {
          if (a.estActif != b.estActif) {
            return a.estActif ? -1 : 1;
          }
          final rankCompare = _badgeRank(b).compareTo(_badgeRank(a));
          if (rankCompare != 0) return rankCompare;
          return b.actionsCount.compareTo(a.actionsCount);
        });
      case _SortOption.recents:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOption.proches:
        sorted.sort((a, b) {
          final da = UserLocationService.instance
                  .distanceMetersTo(a.latitude, a.longitude) ??
              double.infinity;
          final db = UserLocationService.instance
                  .distanceMetersTo(b.latitude, b.longitude) ??
              double.infinity;
          return da.compareTo(db);
        });
      case null:
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildFilterRow(
              label: 'Type',
              children: GroupType.values.map((t) {
                final selected = _selectedType == t;
                return _buildPill(
                  label: t.label,
                  selected: selected,
                  activeColor: CliinAppColors.primary,
                  onTap: () => setState(
                      () => _selectedType = selected ? null : t),
                );
              }).toList(),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildFilterRow(
              label: 'Niveau d\'impact',
              children: kGroupBadgeOrder.map((badge) {
                final selected = _selectedNiveau == badge;
                return _buildPill(
                  label: groupBadgeLabel(badge),
                  selected: selected,
                  activeColor: groupBadgeColor(badge),
                  onTap: () => setState(
                      () => _selectedNiveau = selected ? null : badge),
                );
              }).toList(),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildFilterRow(
              label: 'Trier par',
              children: [
                _buildSortPill(
                  label: 'Plus actifs',
                  icon: Icons.bolt_rounded,
                  option: _SortOption.actifs,
                ),
                _buildSortPill(
                  label: 'Plus récents',
                  icon: Icons.access_time_rounded,
                  option: _SortOption.recents,
                ),
                _buildSortPill(
                  label: 'Plus proches',
                  icon: Icons.near_me_rounded,
                  option: _SortOption.proches,
                ),
              ],
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        CliinAppConstants.pagePadding,
                        0,
                        CliinAppConstants.pagePadding,
                        MediaQuery.of(context).padding.bottom +
                            CliinAppConstants.spacingXL,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: CliinAppConstants.spacingM),
                      itemBuilder: (_, i) =>
                          Center(child: GroupCard(data: results[i])),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + 12,
        CliinAppConstants.pagePadding,
        12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded,
                color: CliinAppColors.textDark, size: 24),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          Text(_headerTitle, style: CliinAppTextStyles.headingSmall),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: CliinAppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher un groupe...',
                  hintStyle:
                      CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
                child: const Icon(Icons.close_rounded,
                    color: CliinAppColors.textSecondary, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow({required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Text(label,
              style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: CliinAppColors.textSecondary)),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                      right: i < children.length - 1
                          ? CliinAppConstants.spacingS
                          : 0),
                  child: children[i],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Forme de pilule commune aux 3 rangées de filtres — seule la couleur
  // change selon la sélection (Type/Niveau d'impact).
  Widget _buildPill({
    required String label,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(
              color: selected ? activeColor : CliinAppColors.divider),
        ),
        child: Text(
          label,
          style: CliinAppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? CliinAppColors.textWhite : CliinAppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSortPill({
    required String label,
    required IconData icon,
    required _SortOption option,
  }) {
    final selected = _selectedSort == option;
    return GestureDetector(
      onTap: () =>
          setState(() => _selectedSort = selected ? null : option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CliinAppColors.primary : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(
              color: selected ? CliinAppColors.primary : CliinAppColors.divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: selected
                  ? CliinAppColors.textWhite
                  : CliinAppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: CliinAppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  selected ? CliinAppColors.textWhite : CliinAppColors.textDark,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: CliinAppColors.textSecondary, size: 40),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(
              'Aucun groupe ne correspond à votre recherche.',
              style: CliinAppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
