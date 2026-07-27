// lib/features/actions/pages/actions_page.dart
// Page principale du module Actions Terrain — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/user_location_service.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../auth/auth_guard.dart';
import '../../reports/pages/report_camera_page.dart';
import '../models/action_model.dart';
import 'action_detail_page.dart';
import 'create_action_page.dart';

class ActionsPage extends StatefulWidget {
  const ActionsPage({super.key});

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  // "Plus" (index 4) reste actif sur cette page — Actions Terrain n'a pas
  // d'onglet dédié dans AppBottomNav, on y accède depuis le menu "Plus".
  static const int _navIndex = 4;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    ActionStore.instance.addListener(_onStoreUpdate);
    UserLocationService.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    ActionStore.instance.removeListener(_onStoreUpdate);
    UserLocationService.instance.removeListener(_onStoreUpdate);
    _searchController.dispose();
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

  Future<void> _openCreateAction() async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      Navigator.push(context, fastFadeRoute<void>(const CreateActionPage()));
    }
  }

  void _openActionDetail(ActionModel action) {
    Navigator.push(
      context,
      fastFadeRoute<void>(ActionDetailPage(data: action)),
    );
  }

  // Sélecteurs de filtre — implémentation sommaire pour ce lot, logique
  // complète prévue plus tard.
  void _showFilterComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Filtre "$label" bientôt disponible.'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  List<ActionModel> get _actionsAProximite {
    final position = UserLocationService.instance.lastKnownPosition;
    if (position == null) return const [];
    var actions = ActionStore.instance
        .getActionsAProximite(position.latitude, position.longitude);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      actions = actions
          .where((a) =>
              a.type.label.toLowerCase().contains(q) ||
              a.lieu.toLowerCase().contains(q) ||
              a.organisateurNom.toLowerCase().contains(q))
          .toList();
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actionsAProximite;

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
              child: _buildSearchBar(),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildFiltersRow(),
            const SizedBox(height: CliinAppConstants.spacingL),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: CliinAppConstants.pagePadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Actions à proximité',
                    style: CliinAppTextStyles.headingSmall.copyWith(
                        fontSize: 14.5, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            Expanded(
              child: actions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        CliinAppConstants.pagePadding,
                        0,
                        CliinAppConstants.pagePadding,
                        MediaQuery.of(context).padding.bottom +
                            CliinAppConstants.spacingXL,
                      ),
                      itemCount: actions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: CliinAppConstants.spacingM),
                      itemBuilder: (context, i) => ActionCard(
                        data: actions[i],
                        onTap: () => _openActionDetail(actions[i]),
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
                  'Actions',
                  style: CliinAppTextStyles.headingLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: CliinAppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Agissons ensemble pour une ville propre',
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
      onTap: _openCreateAction,
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
              'Créer une action',
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

  // ── Barre de recherche ────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
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
              onChanged: (value) => setState(() => _searchQuery = value),
              style: CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher une action...',
                hintStyle: CliinAppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: CliinAppColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filtres ─────────────────────────────────────────────────────
  Widget _buildFiltersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding),
      child: Row(
        children: [
          _buildFilterChip(
              icon: Icons.category_outlined, label: 'Type d\'action'),
          const SizedBox(width: CliinAppConstants.spacingS),
          _buildFilterChip(
              icon: Icons.flag_outlined, label: 'Statut'),
          const SizedBox(width: CliinAppConstants.spacingS),
          _buildFilterChip(
              icon: Icons.near_me_outlined, label: 'À proximité (0–2 km)'),
          const SizedBox(width: CliinAppConstants.spacingS),
          _buildFilterChip(
              icon: Icons.swap_vert_rounded, label: 'Trier'),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required IconData icon, required String label}) {
    return GestureDetector(
      onTap: () => _showFilterComingSoon(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: CliinAppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: CliinAppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final noPosition = UserLocationService.instance.lastKnownPosition == null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noPosition ? Icons.location_searching_rounded : Icons.search_off_rounded,
              size: 56,
              color: CliinAppColors.textSecondary,
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(
              noPosition
                  ? 'Localisation en cours... les actions à proximité '
                      's\'afficheront dès que votre position sera connue.'
                  : 'Aucune action à proximité pour le moment.',
              textAlign: TextAlign.center,
              style: CliinAppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
