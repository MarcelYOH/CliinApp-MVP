// lib/features/groups/pages/group_search_page.dart
//
// Page UNIQUE de recherche de groupes — réutilisée peu importe l'origine du
// clic ("Groupes actifs" Voir tout, "Mes groupes" Voir plus, "Découvrir"
// Voir plus) : le titre du header ET la liste de base (filtrée par
// origine) changent selon [origine], seuls les filtres Type/recherche
// texte s'appliquent ensuite de la même façon partout.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/user_location_service.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/group_card.dart';
import '../data/groups_dummy_data.dart';
import '../models/group_model.dart';

enum _SortOption { proches, recents }

class GroupSearchPage extends StatefulWidget {
  // "actifs" | "mesgroupes" | "decouvrir" | "recherche" — détermine le
  // titre affiché dans le header ET la liste de base interrogée (voir
  // _baseGroups) ; la recherche texte/le filtre Type s'appliquent ensuite
  // de la même façon quelle que soit l'origine.
  final String origine;

  const GroupSearchPage({super.key, required this.origine});

  @override
  State<GroupSearchPage> createState() => _GroupSearchPageState();
}

class _GroupSearchPageState extends State<GroupSearchPage> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  GroupType? _selectedType;
  int? _selectedBadgeCount;
  _SortOption? _selectedSort;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    // "Découvrir" priorise par défaut les groupes les plus proches (5.2) —
    // les autres origines n'ont pas de tri par défaut imposé.
    if (widget.origine == 'decouvrir') {
      _selectedSort = _SortOption.proches;
    }
    // Rafraîchit/amorce l'ancre de position partagée — même motif que
    // map_page.dart (aucun listener dédié : la position se stabilise pour
    // les tris ultérieurs sans bloquer l'affichage initial).
    UserLocationService.instance.getCurrentPosition();
    _scrollController.addListener(_onScroll);
    // Synchronisation immédiate (4.2) : si l'utilisateur suit/ne suit plus
    // un groupe pendant qu'il consulte cette liste, elle se met à jour
    // sans avoir besoin de revenir en arrière.
    GroupStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    GroupStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  // Scroll infini : révèle un lot de plus dès qu'on approche du bas de la
  // liste — jamais un chargement complet d'un coup, jamais de pagination
  // à numéros de page (correction 6).
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      final total = _results.length;
      if (_visibleCount < total) {
        setState(() => _visibleCount =
            (_visibleCount + _pageSize).clamp(0, total));
      }
    }
  }

  void _resetVisibleCount() => _visibleCount = _pageSize;

  String get _headerTitle => switch (widget.origine) {
        'actifs' => 'Groupes actifs',
        'mesgroupes' => 'Mes groupes',
        'decouvrir' => 'Découvrir des groupes',
        'espacegestion' => 'Mes groupes',
        _ => 'Tous les groupes',
      };

  // Chips "Niveau d'impact" : nombre de badges exact, différent selon
  // l'origine (correction 2 pour "actifs", 4.4/5.4 pour les autres).
  List<int> get _badgeCountOptions =>
      widget.origine == 'actifs' ? const [3, 2] : const [0, 1, 2, 3];

  String _badgeCountLabel(int count) =>
      count <= 1 ? '$count badge' : '$count badges';

  // Liste de base selon l'origine, AVANT recherche texte/filtre Type — sert
  // aussi à détecter l'absence de vraie donnée (bascule vers les cartes
  // factices, correction 3/7).
  List<GroupModel> get _baseGroups {
    final userId = AuthStore.instance.currentUser?.id;
    switch (widget.origine) {
      case 'actifs':
        // Page dédiée : TOUS les groupes actifs au sens large (2 OU 3
        // badges), déjà triés 3 badges d'abord puis 2 badges (1.2).
        return GroupStore.instance.getGroupsActifs();
      case 'mesgroupes':
        // Uniquement les groupes suivis, peu importe leur nombre de
        // badges (4.1).
        return userId != null
            ? GroupStore.instance.getMesGroupes(userId)
            : const <GroupModel>[];
      case 'decouvrir':
        // Tous les groupes NON suivis, peu importe leur nombre de badges
        // (5.1).
        return userId != null
            ? GroupStore.instance.getGroupesADecouvrir(userId)
            : GroupStore.instance.allGroups;
      case 'espacegestion':
        // "Mes groupes" du Profil — UNIQUEMENT les groupes où l'utilisateur
        // est administrateur (Espace gestion), seul point d'entrée où la
        // modification devient accessible (correction 4).
        return userId != null
            ? GroupStore.instance.adminGroups(userId)
            : const <GroupModel>[];
      default:
        return GroupStore.instance.allGroups;
    }
  }

  List<GroupModel> get _results {
    final base = _baseGroups;
    // "Mes groupes" du Profil (administration) : jamais de cartes factices
    // — ce n'est pas une section de découverte, en afficher ici suggérerait
    // à tort que l'utilisateur administre des groupes fictifs.
    if (base.isEmpty && widget.origine == 'espacegestion') {
      return const <GroupModel>[];
    }
    // Aucune vraie donnée pour cette section -> cartes factices "accroche"
    // (exactement 3, jamais mélangées à de vraies données, correction 3).
    if (base.isEmpty) return GroupsDummyData.forSection(widget.origine);

    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filtered = base.where((g) {
      final matchesQuery = normalizedQuery.isEmpty ||
          g.nom.toLowerCase().contains(normalizedQuery);
      final matchesType = _selectedType == null || g.type == _selectedType;
      final matchesBadges = _selectedBadgeCount == null ||
          g.badges.length == _selectedBadgeCount;
      return matchesQuery && matchesType && matchesBadges;
    }).toList();

    final sorted = List<GroupModel>.from(filtered);
    switch (_selectedSort) {
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
    final visibleResults = results.take(_visibleCount).toList();
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
                  onTap: () => setState(() {
                    _selectedType = selected ? null : t;
                    _resetVisibleCount();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildFilterRow(
              label: 'Niveau d\'impact',
              children: _badgeCountOptions.map((count) {
                final selected = _selectedBadgeCount == count;
                return _buildPill(
                  label: _badgeCountLabel(count),
                  selected: selected,
                  activeColor: CliinAppColors.primary,
                  onTap: () => setState(() {
                    _selectedBadgeCount = selected ? null : count;
                    _resetVisibleCount();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildFilterRow(
              label: 'Trier par',
              children: [
                _buildSortPill(
                  label: 'Plus proches',
                  icon: Icons.near_me_rounded,
                  option: _SortOption.proches,
                ),
                _buildSortPill(
                  label: 'Plus récents',
                  icon: Icons.access_time_rounded,
                  option: _SortOption.recents,
                ),
              ],
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            Expanded(
              child: visibleResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        CliinAppConstants.pagePadding,
                        0,
                        CliinAppConstants.pagePadding,
                        MediaQuery.of(context).padding.bottom +
                            CliinAppConstants.spacingXL,
                      ),
                      itemCount: visibleResults.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: CliinAppConstants.spacingM),
                      itemBuilder: (_, i) => GroupCard(
                        data: visibleResults[i],
                        width: double.infinity,
                      ),
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
          CircleIconButton.back(onTap: () => Navigator.pop(context)),
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
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _resetVisibleCount();
                }),
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
                  _resetVisibleCount();
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

  // Forme de pilule commune aux 3 rangées de filtres.
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
      onTap: () => setState(() {
        _selectedSort = selected ? null : option;
        _resetVisibleCount();
      }),
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
    // "Mes groupes" du Profil sans aucune vraie donnée : message dédié
    // (pas de cartes factices ici, voir _results) plutôt que le message
    // générique "aucun résultat de recherche".
    final message = (widget.origine == 'espacegestion' && _baseGroups.isEmpty)
        ? 'Vous n\'administrez aucun groupe pour l\'instant.'
        : 'Aucun groupe ne correspond à votre recherche.';
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
              message,
              style: CliinAppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
