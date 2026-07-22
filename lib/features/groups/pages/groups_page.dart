// lib/features/groups/pages/groups_page.dart
// Page principale du module Groupes — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/group_card.dart';
import '../../auth/auth_guard.dart';
import '../../reports/pages/report_camera_page.dart';
import '../data/groups_dummy_data.dart';
import '../models/group_model.dart';
import 'create_group_page.dart';
import 'group_search_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  static const int _navIndex = 3;

  // "Découvrir" sélectionné par défaut à l'arrivée sur la page.
  int _selectedTab = 1;

  @override
  void initState() {
    super.initState();
    GroupStore.instance.addListener(_onStoreUpdate);
    AuthStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    GroupStore.instance.removeListener(_onStoreUpdate);
    AuthStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

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

  void _openSearch({String origine = 'recherche'}) {
    Navigator.push(
      context,
      fastFadeRoute<void>(GroupSearchPage(origine: origine)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = GroupStore.instance;
    final userId = AuthStore.instance.currentUser?.id;

    // Chaque section : priorité systématique aux vraies données, cartes
    // factices "accroche" (GroupsDummyData) uniquement tant qu'aucune
    // vraie donnée équivalente n'existe — jamais les deux mélangés
    // (correction 3, bascule totale).
    final groupesActifsReal = store.getGroupsActifsVitrine();
    final groupesActifs = groupesActifsReal.isEmpty
        ? GroupsDummyData.forSection('actifs')
        : groupesActifsReal;

    final mesGroupesReal =
        userId != null ? store.getMesGroupes(userId) : const <GroupModel>[];
    final mesGroupes = mesGroupesReal.isEmpty
        ? GroupsDummyData.forSection('mesgroupes')
        : mesGroupesReal;

    final decouvrirReal =
        userId != null ? store.getGroupesADecouvrir(userId) : store.allGroups;
    final decouvrir = decouvrirReal.isEmpty
        ? GroupsDummyData.forSection('decouvrir')
        : decouvrirReal;

    final tabGroups =
        (_selectedTab == 0 ? mesGroupes : decouvrir).take(3).toList();

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                children: [
                  const SizedBox(height: CliinAppConstants.spacingS),
                  _buildSearchBar(),
                  const SizedBox(height: CliinAppConstants.spacingL),
                  _buildActifsSection(groupesActifs),
                  const SizedBox(height: 32),
                  _buildTabsSection(tabGroups),
                ],
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

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + 16,
        CliinAppConstants.pagePadding,
        12,
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
            const Icon(Icons.add_rounded,
                color: CliinAppColors.textWhite, size: 16),
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

  // ── Barre de recherche ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: GestureDetector(
        onTap: () => _openSearch(),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: CliinAppColors.cardWhite,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusMedium),
            border: Border.all(color: CliinAppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: CliinAppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rechercher un groupe...',
                  style:
                      CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
                ),
              ),
              const Icon(Icons.tune_rounded,
                  color: CliinAppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Groupes actifs ─────────────────────────────────────────────
  Widget _buildActifsSection(List<GroupModel> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Groupes actifs', style: CliinAppTextStyles.headingMedium),
              GestureDetector(
                onTap: () => _openSearch(origine: 'actifs'),
                child: Row(children: [
                  Text('Voir tout',
                      style: CliinAppTextStyles.link.copyWith(fontSize: 13)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right,
                      color: CliinAppColors.primary, size: 18),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: CliinAppConstants.spacingM),
        groups.isEmpty
            ? _buildEmptyHint('Aucun groupe actif pour le moment.')
            : _buildHorizontalList(groups),
      ],
    );
  }

  // ── Mes groupes / Découvrir ────────────────────────────────────
  Widget _buildTabsSection(List<GroupModel> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: _buildTabsRow(),
        ),
        const SizedBox(height: CliinAppConstants.spacingS),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _openSearch(
                  origine: _selectedTab == 0 ? 'mesgroupes' : 'decouvrir'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Voir plus',
                    style: CliinAppTextStyles.link.copyWith(fontSize: 11.5)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    color: CliinAppColors.primary, size: 16),
              ]),
            ),
          ),
        ),
        const SizedBox(height: CliinAppConstants.spacingS),
        groups.isEmpty
            ? _buildEmptyHint(_selectedTab == 0
                ? 'Vous ne suivez encore aucun groupe.'
                : 'Aucun groupe à découvrir pour le moment.')
            : _buildHorizontalList(groups),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Row(children: [
      _buildTabItem('Mes groupes', 0),
      const SizedBox(width: CliinAppConstants.spacingL),
      _buildTabItem('Découvrir', 1),
    ]);
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isSelected ? CliinAppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: CliinAppTextStyles.headingSmall.copyWith(
            fontSize: 14,
            color: isSelected
                ? CliinAppColors.primary
                : CliinAppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Helpers communs ────────────────────────────────────────────
  // 1 seule carte -> pleine largeur (même comportement que "Cas récents"
  // sur l'accueil de l'application, correction 3.4) ; sinon scroll
  // horizontal habituel.
  Widget _buildHorizontalList(List<GroupModel> groups) {
    if (groups.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding),
        child: GroupCard(data: groups.first, width: double.infinity),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(groups.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index < groups.length - 1
                    ? CliinAppConstants.spacingM
                    : 0,
              ),
              child: GroupCard(data: groups[index]),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding),
      child: Text(text, style: CliinAppTextStyles.bodySmall),
    );
  }
}
