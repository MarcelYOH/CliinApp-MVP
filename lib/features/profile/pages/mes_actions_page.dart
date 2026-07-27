// lib/features/profile/pages/mes_actions_page.dart
// "Mes actions" (Profil individuel) / "Nos actions" (Espace gestion d'un
// groupe, via headerTitle + filterOverride) — même principe de réutilisation
// dual-contexte que mes_cas_signales_page.dart, sans dupliquer l'UI.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../actions/models/action_model.dart';
import '../../actions/pages/action_detail_page.dart';
import '../../actions/pages/actions_page.dart';
import '../../actions/pages/create_action_page.dart';

class MesActionsPage extends StatefulWidget {
  // Overrides optionnels — permettent de réutiliser cette page telle quelle
  // pour "Nos actions" (Espace gestion d'un groupe) sans dupliquer son UI.
  // Aucun impact sur l'appel standard depuis le Profil individuel.
  final String? headerTitle;
  final bool Function(ActionModel)? filterOverride;

  const MesActionsPage({super.key, this.headerTitle, this.filterOverride});

  @override
  State<MesActionsPage> createState() => _MesActionsPageState();
}

class _MesActionsPageState extends State<MesActionsPage> {
  List<ActionModel> get _myActions {
    List<ActionModel> result;
    if (widget.filterOverride != null) {
      result = ActionStore.instance.allActions.where(widget.filterOverride!).toList();
    } else {
      final userId = AuthStore.instance.currentUser?.id;
      if (userId == null) return const [];
      result = ActionStore.instance.allActions
          .where((a) => a.organisateurId == userId && !a.organisateurEstGroupe)
          .toList();
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  void _openDecouvrir() {
    Navigator.push(context, fastFadeRoute<void>(const ActionsPage()));
  }

  void _openDetail(ActionModel action) {
    Navigator.push(context, fastFadeRoute<void>(ActionDetailPage(data: action)));
  }

  void _openCreate() {
    Navigator.push(context, fastFadeRoute<void>(const CreateActionPage()));
  }

  void _openEdit(ActionModel action) {
    Navigator.push(
      context,
      fastFadeRoute<void>(CreateActionPage(actionId: action.id)),
    );
  }

  Future<void> _confirmDelete(ActionModel action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette action ?'),
        content: const Text(
          'Cette action est irréversible. L\'action sera définitivement supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: CliinAppColors.alertRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ActionStore.instance.deleteAction(action.id);
    }
  }

  Future<void> _showActionMenu(ActionModel action) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(CliinAppConstants.radiusLarge),
            topRight: Radius.circular(CliinAppConstants.radiusLarge),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
            CliinAppConstants.pagePadding, 0, CliinAppConstants.pagePadding, 0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: CliinAppConstants.spacingM),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CliinAppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: CliinAppConstants.spacingL),
              _menuOption(
                icon: Icons.visibility_outlined,
                label: 'Voir les détails',
                onTap: () => Navigator.pop(context, 'details'),
              ),
              _menuOption(
                icon: Icons.edit_outlined,
                label: 'Modifier',
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              _menuOption(
                icon: Icons.delete_outline_rounded,
                label: 'Supprimer',
                destructive: true,
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'details':
        _openDetail(action);
      case 'edit':
        _openEdit(action);
      case 'delete':
        await _confirmDelete(action);
    }
  }

  Widget _menuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? CliinAppColors.alertRed : CliinAppColors.textDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: CliinAppConstants.spacingM),
            Text(label,
                style: CliinAppTextStyles.bodyMedium.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ActionStore.instance,
      builder: (context, _) {
        final actions = _myActions;
        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabs(),
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
                          itemBuilder: (context, i) => _buildActionTile(actions[i]),
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
            child: Text(widget.headerTitle ?? 'Mes actions',
                style: CliinAppTextStyles.headingMedium),
          ),
        ],
      ),
    );
  }

  // Deux onglets — "Mes actions"/"Nos actions" reste affiché sur cette page
  // (jamais de contenu propre pour "Découvrir", simple raccourci de
  // navigation vers ActionsPage, cf. correction 3 point 3).
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: Row(
        children: [
          Expanded(child: _buildTabPill(widget.headerTitle ?? 'Mes actions', true, null)),
          const SizedBox(width: CliinAppConstants.spacingS),
          Expanded(child: _buildTabPill('Découvrir', false, _openDecouvrir)),
        ],
      ),
    );
  }

  Widget _buildTabPill(String label, bool selected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? CliinAppColors.primary : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(
              color: selected ? CliinAppColors.primary : CliinAppColors.divider),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CliinAppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? CliinAppColors.textWhite : CliinAppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // Superpose un bouton "..." discret sur l'ActionCard partagée, sans la
  // modifier — voir/modifier/supprimer restent un menu contextuel séparé.
  Widget _buildActionTile(ActionModel action) {
    return Stack(
      children: [
        ActionCard(data: action, onTap: () => _openDetail(action)),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _showActionMenu(action),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: CliinAppColors.cardWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.more_vert_rounded,
                  color: CliinAppColors.textDark, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded,
                size: 56, color: CliinAppColors.textSecondary),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(
              'Aucune action pour le moment.',
              textAlign: TextAlign.center,
              style: CliinAppTextStyles.bodyMedium,
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            GestureDetector(
              onTap: _openCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: CliinAppColors.primary,
                  borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: CliinAppColors.textWhite, size: 18),
                    const SizedBox(width: 6),
                    Text('Créer une action', style: CliinAppTextStyles.button),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
