// lib/features/groups/widgets/group_activities_tab.dart
//
// Onglet "Activités" du profil groupe — liste les actions terrain
// organisées par ce groupe (ActionStore, organisateurEstGroupe &&
// organisateurId == group.id), même ActionCard partagée que la page
// principale du module Actions, jamais dupliquée. "Organiser une action"
// ouvre exactement CreateActionPage, avec ce groupe pré-sélectionné.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/widgets/action_card.dart';
import '../../actions/models/action_model.dart';
import '../../actions/pages/action_detail_page.dart';
import '../../actions/pages/create_action_page.dart';
import '../../auth/auth_guard.dart';
import '../models/group_model.dart';
import 'group_profile_widgets.dart';

class GroupActivitiesTab extends StatelessWidget {
  final GroupModel group;
  const GroupActivitiesTab({super.key, required this.group});

  bool _isGroupAction(ActionModel a) =>
      a.organisateurEstGroupe && a.organisateurId == group.id;

  Future<void> _openCreateAction(BuildContext context) async {
    if (await requireAuth(context)) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        fastFadeRoute<void>(CreateActionPage(preselectedGroupId: group.id)),
      );
    }
  }

  void _openDetail(BuildContext context, ActionModel action) {
    Navigator.push(context, fastFadeRoute<void>(ActionDetailPage(data: action)));
  }

  @override
  Widget build(BuildContext context) {
    // Écoute ActionStore pour qu'une action publiée depuis "Organiser une
    // action" (ou depuis la page principale Actions) apparaisse ici
    // automatiquement, sans avoir à rouvrir le profil du groupe.
    return ListenableBuilder(
      listenable: ActionStore.instance,
      builder: (context, _) {
        final actions = ActionStore.instance.allActions.where(_isGroupAction).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Padding(
          padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
          child: Column(
            children: [
              Expanded(
                child: actions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                color: CliinAppColors.textSecondary, size: 40),
                            const SizedBox(height: CliinAppConstants.spacingM),
                            Text('Aucune action pour l\'instant',
                                style: CliinAppTextStyles.headingSmall),
                            const SizedBox(height: 4),
                            Text(
                              'Les actions organisées par ce groupe apparaîtront ici.',
                              style: CliinAppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: actions.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: CliinAppConstants.spacingM),
                        itemBuilder: (context, i) => ActionCard(
                          data: actions[i],
                          onTap: () => _openDetail(context, actions[i]),
                        ),
                      ),
              ),
              const SizedBox(height: CliinAppConstants.spacingM),
              GestureDetector(
                onTap: () => _openCreateAction(context),
                child: CustomPaint(
                  painter: const GroupDashedRectPainter(
                      color: CliinAppColors.primary,
                      radius: CliinAppConstants.radiusMedium),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: CliinAppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text('Organiser une action',
                            style: CliinAppTextStyles.link.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
