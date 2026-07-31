// lib/features/groups/pages/groups_page.dart
// Page principale du module Groupes — CliinApp
//
// Redesign (Correction 2) — bloc fixe en haut (header + recherche + 3
// onglets + bouton Filtres compact) jamais scrollé, feed vertical à scroll
// infini en dessous. Règles de définition/tri des 3 catégories de groupes
// INCHANGÉES (mêmes méthodes GroupStore que l'ancien aperçu ET que
// GroupSearchPage, jamais réinventées) — seule la présentation change.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/user_location_service.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/utils/search_helper.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/group_card.dart';
import '../../../shared/widgets/left_filter_panel.dart';
import '../../auth/auth_guard.dart';
import '../../reports/pages/report_camera_page.dart';
import '../data/groups_dummy_data.dart';
import '../models/group_model.dart';
import 'create_group_page.dart';

enum _GroupsTab { actifs, decouvrir, mesgroupes }

enum _SortOption { proches, recents }

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  static const int _navIndex = 3;
  static const int _pageSize = 10;

  // "Groupes actifs" sélectionné par défaut à l'arrivée sur la page
  // (Correction 2.1).
  _GroupsTab _selectedTab = _GroupsTab.actifs;

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
    GroupStore.instance.addListener(_onStoreUpdate);
    AuthStore.instance.addListener(_onStoreUpdate);
    // Nécessaire pour le tri "Plus proches" — même motif que
    // group_search_page.dart/map_page.dart.
    UserLocationService.instance.getCurrentPosition();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    GroupStore.instance.removeListener(_onStoreUpdate);
    AuthStore.instance.removeListener(_onStoreUpdate);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      final total = _results.length;
      if (_visibleCount < total) {
        setState(() => _visibleCount = (_visibleCount + _pageSize).clamp(0, total));
      }
    }
  }

  void _resetVisibleCount() => _visibleCount = _pageSize;

  void _onNavTap(int index) =>
      navigateToTab(context, currentIndex: _navIndex, targetIndex: index);

  void _openCamera() async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      Navigator.push(context, fastFadeRoute<void>(const ReportCameraPage()));
    }
  }

  Future<void> _openCreateGroup() async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      Navigator.push(context, fastFadeRoute<void>(const CreateGroupPage()));
    }
  }

  void _onTabTap(_GroupsTab tab) {
    setState(() {
      _selectedTab = tab;
      // Les options de "Niveau d'impact" changent selon l'onglet (2.2) — un
      // choix valide sur l'onglet précédent peut ne plus exister ici.
      _selectedBadgeCount = null;
      // "Découvrir" priorise par défaut les groupes les plus proches, sauf
      // si l'utilisateur a déjà choisi un tri explicitement.
      if (tab == _GroupsTab.decouvrir && _selectedSort == null) {
        _selectedSort = _SortOption.proches;
      }
      _resetVisibleCount();
    });
  }

  // Chips "Niveau d'impact" — dynamique selon l'onglet actif (Correction
  // 2.2), même logique déjà validée que group_search_page.dart.
  List<int> get _badgeCountOptions =>
      _selectedTab == _GroupsTab.actifs ? const [3, 2] : const [0, 1, 2, 3];

  String _badgeCountLabel(int count) => count <= 1 ? '$count badge' : '$count badges';

  // Liste de base selon l'onglet, AVANT recherche/filtres — règles de
  // définition INCHANGÉES (mêmes méthodes GroupStore que précédemment) :
  // - Groupes actifs = au moins 2 badges, 3 badges triés en premier
  //   (GroupStore.getGroupsActifs, déjà validé).
  // - Découvrir = tous les groupes non suivis.
  // - Mes groupes = uniquement les groupes suivis.
  List<GroupModel> get _baseGroups {
    final userId = AuthStore.instance.currentUser?.id;
    final real = switch (_selectedTab) {
      _GroupsTab.actifs => GroupStore.instance.getGroupsActifs(),
      _GroupsTab.decouvrir => userId != null
          ? GroupStore.instance.getGroupesADecouvrir(userId)
          : GroupStore.instance.allGroups,
      _GroupsTab.mesgroupes => userId != null
          ? GroupStore.instance.getMesGroupes(userId)
          : const <GroupModel>[],
    };
    if (real.isNotEmpty) return real;
    // Aucune vraie donnée pour cet onglet -> cartes factices "accroche",
    // jamais mélangées à de vraies données (règle déjà validée).
    return GroupsDummyData.forSection(switch (_selectedTab) {
      _GroupsTab.actifs => 'actifs',
      _GroupsTab.decouvrir => 'decouvrir',
      _GroupsTab.mesgroupes => 'mesgroupes',
    });
  }

  List<GroupModel> get _results {
    final filtered = _baseGroups.where((g) {
      final matchesQuery = matchesSearch(_searchQuery, [g.nom, g.description, g.zone]);
      final matchesType = _selectedType == null || g.type == _selectedType;
      final matchesBadges =
          _selectedBadgeCount == null || g.badges.length == _selectedBadgeCount;
      return matchesQuery && matchesType && matchesBadges;
    }).toList();

    final sorted = List<GroupModel>.from(filtered);
    switch (_selectedSort) {
      case _SortOption.recents:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOption.proches:
        sorted.sort((a, b) {
          final da =
              UserLocationService.instance.distanceMetersTo(a.latitude, a.longitude) ??
                  double.infinity;
          final db =
              UserLocationService.instance.distanceMetersTo(b.latitude, b.longitude) ??
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
            const SizedBox(height: CliinAppConstants.spacingS),
            _buildSearchBar(),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildTabsRow(),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildFiltersButton(),
            const SizedBox(height: CliinAppConstants.spacingM),
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
                        // Correction 7 — "Mes groupes" ne contient par
                        // définition que des groupes déjà suivis ; ses
                        // cartes factices (jamais dans GroupStore, donc
                        // jamais "suivies" au sens réel) doivent afficher
                        // "Suivi", pas "Suivre".
                        forceFollowingState: _selectedTab == _GroupsTab.mesgroupes &&
                                GroupsDummyData.isFakeGroup(visibleResults[i])
                            ? true
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        onSignalerTap: _openCamera,
      ),
    );
  }

  // ── Header (bloc fixe) ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + 16,
        CliinAppConstants.pagePadding,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Groupes',
                  style: CliinAppTextStyles.headingLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: CliinAppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rejoignez des groupes qui agissent',
                  style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: _openCreateGroup,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: CliinAppColors.primary,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: CliinAppColors.textWhite, size: 16),
            const SizedBox(width: 4),
            Text(
              'Créer un groupe',
              maxLines: 1,
              softWrap: false,
              style: CliinAppTextStyles.button.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre de recherche (bloc fixe) ─────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
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
            const Icon(Icons.search_rounded, color: CliinAppColors.textSecondary, size: 20),
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
                  hintStyle: CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
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

  // ── 3 onglets (bloc fixe) — ordre exact : Groupes actifs, Découvrir,
  // Mes groupes (Correction 2.1) ──────────────────────────────────────
  Widget _buildTabsRow() {
    const tabs = [
      (_GroupsTab.actifs, 'Groupes actifs'),
      (_GroupsTab.decouvrir, 'Découvrir'),
      (_GroupsTab.mesgroupes, 'Mes groupes'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: Row(
        children: [
          for (final t in tabs)
            Padding(
              padding: const EdgeInsets.only(right: CliinAppConstants.spacingL),
              child: _buildTabItem(t.$2, t.$1),
            ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, _GroupsTab tab) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => _onTabTap(tab),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? CliinAppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: CliinAppTextStyles.headingSmall.copyWith(
            fontSize: 14,
            color: isSelected ? CliinAppColors.primary : CliinAppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Bouton "Filtres" compact (bloc fixe, Correction 2.1) ───────────
  int get _activeFilterCount =>
      (_selectedType != null ? 1 : 0) +
      (_selectedBadgeCount != null ? 1 : 0) +
      (_selectedSort != null ? 1 : 0);

  Widget _buildFiltersButton() {
    final count = _activeFilterCount;
    final active = count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: GestureDetector(
        onTap: _showFiltersSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? CliinAppColors.primaryLight : CliinAppColors.cardWhite,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
            border: Border.all(
                color: active ? CliinAppColors.primary : CliinAppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 18,
                  color: active ? CliinAppColors.primary : CliinAppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Filtres',
                  style: CliinAppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? CliinAppColors.primary : CliinAppColors.textDark)),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: CliinAppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: CliinAppTextStyles.badge.copyWith(
                        color: CliinAppColors.textWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Panneau ancré à gauche (Correction 2 — jamais centré) regroupant les 3
  // catégories de filtres (Type/Niveau d'impact/Trier par, chacun sur une
  // ligne horizontale scrollable), avec un bouton "Appliquer" en bas pour
  // fermer le panneau.
  void _showFiltersSheet() {
    showLeftFilterPanel(
      context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                top: CliinAppConstants.spacingM, bottom: CliinAppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CliinAppConstants.pagePadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filtres',
                          style: CliinAppTextStyles.headingMedium.copyWith(fontSize: 16)),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: const Icon(Icons.close_rounded,
                            color: CliinAppColors.textSecondary, size: 22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CliinAppConstants.spacingM),
                _buildFilterRow(
                  label: 'Type',
                  children: GroupType.values.map((t) {
                    final selected = _selectedType == t;
                    return _buildPill(
                      label: t.label,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedType = selected ? null : t;
                          _resetVisibleCount();
                        });
                        setModalState(() {});
                      },
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
                      onTap: () {
                        setState(() {
                          _selectedBadgeCount = selected ? null : count;
                          _resetVisibleCount();
                        });
                        setModalState(() {});
                      },
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
                      onChanged: () => setModalState(() {}),
                    ),
                    _buildSortPill(
                      label: 'Plus récents',
                      icon: Icons.access_time_rounded,
                      option: _SortOption.recents,
                      onChanged: () => setModalState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: CliinAppConstants.spacingL),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CliinAppConstants.pagePadding),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CliinAppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(CliinAppConstants.radiusMedium)),
                      ),
                      child: Text('Appliquer',
                          style: CliinAppTextStyles.button
                              .copyWith(color: CliinAppColors.textWhite)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow({required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
          child: Text(label,
              style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: CliinAppColors.textSecondary)),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                      right: i < children.length - 1 ? CliinAppConstants.spacingS : 0),
                  child: children[i],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CliinAppColors.primary : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border:
              Border.all(color: selected ? CliinAppColors.primary : CliinAppColors.divider),
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
    VoidCallback? onChanged,
  }) {
    final selected = _selectedSort == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSort = selected ? null : option;
          _resetVisibleCount();
        });
        onChanged?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CliinAppColors.primary : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border:
              Border.all(color: selected ? CliinAppColors.primary : CliinAppColors.divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: selected ? CliinAppColors.textWhite : CliinAppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: CliinAppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? CliinAppColors.textWhite : CliinAppColors.textDark,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Grâce au repli sur les cartes factices (_baseGroups), ce message
    // n'apparaît en pratique que lorsque la recherche/les filtres ne
    // correspondent à rien — même message générique que
    // group_search_page.dart, jamais réinventé.
    const message = 'Aucun groupe ne correspond à votre recherche.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: CliinAppColors.textSecondary, size: 40),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(message, style: CliinAppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
