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
import '../../../shared/utils/search_helper.dart';
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

  // Filtres combinables (logique ET) — même principe que
  // GroupSearchPage : une valeur nullable par catégorie (null = pas de
  // filtre actif), re-tap sur la valeur déjà sélectionnée la désélectionne.
  // Proximité INACTIVE par défaut (Correction 5) : "sans action de
  // l'utilisateur" doit afficher le tri par défaut (statut puis proximité,
  // voir _filteredActions), jamais une liste restreinte à 2km ni vide en
  // attendant le GPS. L'utilisateur peut toujours activer ce filtre manuel
  // pour restreindre la liste à un rayon précis.
  ActionType? _selectedType;
  ActionStatus? _selectedStatut;
  bool _proximityActive = false;
  // Filtre manuel "Trier par date" (Correction 5) — restreint la liste à une
  // date précise choisie via un date picker standard ; se combine en ET avec
  // les 3 filtres ci-dessus. Indépendant du tri par défaut (voir
  // _filteredActions).
  DateTime? _selectedDateFilter;

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

  // Filtres Type/Statut/Proximité combinés en ET, cohérent avec la logique
  // déjà en place pour la recherche de groupes (GroupSearchPage) — une
  // valeur nullable par catégorie, recherche texte toujours combinée en
  // plus. La distance réutilise UserLocationService (même calcul que
  // ActionCard/DynamicDistanceLabel), aucun Haversine ré-écrit ici.
  List<ActionModel> get _filteredActions {
    final position = UserLocationService.instance.lastKnownPosition;
    if (_proximityActive && position == null) return const [];

    var actions = ActionStore.instance.allActions.where((a) {
      final matchesType = _selectedType == null || a.type == _selectedType;
      final matchesStatut = _selectedStatut == null || a.statut == _selectedStatut;
      final matchesProximity = !_proximityActive ||
          ((UserLocationService.instance.distanceMetersTo(a.latitude, a.longitude) ??
                  double.infinity) <=
              2000);
      final matchesDate = _selectedDateFilter == null ||
          (a.date.year == _selectedDateFilter!.year &&
              a.date.month == _selectedDateFilter!.month &&
              a.date.day == _selectedDateFilter!.day);
      return matchesType && matchesStatut && matchesProximity && matchesDate;
    }).toList();

    // Recherche texte unique et réutilisable (Correction 6) — titre/type,
    // description, lieu de l'action.
    actions = actions
        .where((a) =>
            matchesSearch(_searchQuery, [a.type.label, a.description, a.lieu]))
        .toList();

    // Tri par défaut (Correction 5) — plus récemment publiées en premier,
    // sans action de l'utilisateur ; indépendant du filtre manuel
    // "Proximité (0-2km)" (qui ne fait plus que restreindre le rayon, voir
    // matchesProximity ci-dessus).
    actions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return actions;
  }

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _selectedStatut != null ||
      _proximityActive ||
      _selectedDateFilter != null;

  void _toggleProximity() => setState(() => _proximityActive = !_proximityActive);

  Future<void> _pickDateFilter() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDateFilter = picked);
  }

  void _clearDateFilter() => setState(() => _selectedDateFilter = null);

  Future<void> _pickType() async {
    final result = await _showSingleSelectSheet<ActionType>(
      title: 'Type d\'action',
      options: ActionType.values,
      current: _selectedType,
      labelBuilder: (t) => t.label,
      iconBuilder: (t) => t.icon,
      colorBuilder: (t) => t.color,
    );
    // null = feuille fermée sans choix (tap en dehors) — ne touche pas au
    // filtre actif. _PickResult(null) = "Tous" tapé explicitement.
    if (result != null) setState(() => _selectedType = result.value);
  }

  Future<void> _pickStatut() async {
    final result = await _showSingleSelectSheet<ActionStatus>(
      title: 'Statut',
      options: ActionStatus.values,
      current: _selectedStatut,
      labelBuilder: (s) => s.label,
      iconBuilder: (_) => Icons.flag_rounded,
      colorBuilder: (s) => s.color,
    );
    if (result != null) setState(() => _selectedStatut = result.value);
  }

  // Sélecteur générique liste + coche — pas de composant équivalent
  // existant à réutiliser (voir recherche). Retour enveloppé dans
  // _PickResult pour distinguer "fermé sans choix" (null, filtre inchangé)
  // de "Tous" tapé explicitement (_PickResult(null), filtre effacé).
  Future<_PickResult<T>?> _showSingleSelectSheet<T>({
    required String title,
    required List<T> options,
    required T? current,
    required String Function(T) labelBuilder,
    required IconData Function(T) iconBuilder,
    required Color Function(T) colorBuilder,
  }) {
    return showModalBottomSheet<_PickResult<T>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(CliinAppConstants.radiusLarge),
            topRight: Radius.circular(CliinAppConstants.radiusLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    CliinAppConstants.pagePadding, CliinAppConstants.spacingL,
                    CliinAppConstants.pagePadding, CliinAppConstants.spacingM),
                child: Text(title, style: CliinAppTextStyles.headingMedium.copyWith(fontSize: 16)),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
                  itemCount: options.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: CliinAppColors.divider),
                  itemBuilder: (context, i) {
                    final option = options[i];
                    final selected = option == current;
                    return InkWell(
                      onTap: () => Navigator.pop(
                          context, _PickResult<T>(selected ? null : option)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(iconBuilder(option), color: colorBuilder(option), size: 20),
                            const SizedBox(width: CliinAppConstants.spacingM),
                            Expanded(
                              child: Text(labelBuilder(option),
                                  style: CliinAppTextStyles.bodyMedium
                                      .copyWith(color: CliinAppColors.textDark)),
                            ),
                            if (selected)
                              const Icon(Icons.check_rounded,
                                  color: CliinAppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: CliinAppConstants.spacingS),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = _filteredActions;

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
                child: Text(
                    _proximityActive ? 'Actions à proximité' : 'Toutes les actions terrain',
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
                  'Actions terrain',
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
            icon: Icons.category_outlined,
            label: _selectedType?.label ?? 'Type d\'action',
            active: _selectedType != null,
            onTap: _pickType,
          ),
          const SizedBox(width: CliinAppConstants.spacingS),
          _buildFilterChip(
            icon: Icons.flag_outlined,
            label: _selectedStatut?.label ?? 'Statut',
            active: _selectedStatut != null,
            onTap: _pickStatut,
          ),
          const SizedBox(width: CliinAppConstants.spacingS),
          _buildFilterChip(
            icon: Icons.near_me_outlined,
            label: 'À proximité (0–2 km)',
            active: _proximityActive,
            showDropdownArrow: false,
            onTap: _toggleProximity,
          ),
          const SizedBox(width: CliinAppConstants.spacingS),
          _buildDateFilterChip(),
        ],
      ),
    );
  }

  // Filtre "Trier par date" (Correction 5) — sélection d'une date précise
  // via le date picker standard Flutter ; bouton de réinitialisation ("x")
  // affiché à côté dès qu'une date est active, pour revenir facilement à la
  // liste complète triée par défaut.
  Widget _buildDateFilterChip() {
    final active = _selectedDateFilter != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? CliinAppColors.primaryLight : CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        border: Border.all(
            color: active ? CliinAppColors.primary : CliinAppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickDateFilter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_rounded,
                    size: 16,
                    color: active ? CliinAppColors.primary : CliinAppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  active ? formatActionDate(_selectedDateFilter!) : 'Trier par date',
                  style: CliinAppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: active ? CliinAppColors.primary : null,
                      fontWeight: active ? FontWeight.w600 : null),
                ),
                if (!active) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: CliinAppColors.textSecondary),
                ],
              ],
            ),
          ),
          if (active) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _clearDateFilter,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: CliinAppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    bool showDropdownArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? CliinAppColors.primaryLight : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(
              color: active ? CliinAppColors.primary : CliinAppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? CliinAppColors.primary : CliinAppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: CliinAppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: active ? CliinAppColors.primary : null,
                    fontWeight: active ? FontWeight.w600 : null)),
            if (showDropdownArrow) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: active ? CliinAppColors.primary : CliinAppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final noPosition =
        _proximityActive && UserLocationService.instance.lastKnownPosition == null;
    final message = noPosition
        ? 'Localisation en cours... les actions à proximité '
            's\'afficheront dès que votre position sera connue.'
        : (_hasActiveFilters
            ? 'Aucune action ne correspond à ces filtres.'
            : (_proximityActive
                ? 'Aucune action à proximité pour le moment.'
                : 'Aucune action pour le moment.'));
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
              message,
              textAlign: TextAlign.center,
              style: CliinAppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// Enveloppe le résultat du sélecteur mono-sélection pour distinguer "feuille
// fermée sans choix" (null) de "Tous" tapé explicitement (_PickResult(null)).
class _PickResult<T> {
  final T? value;
  const _PickResult(this.value);
}
