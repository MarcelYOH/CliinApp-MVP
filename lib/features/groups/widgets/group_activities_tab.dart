// lib/features/groups/widgets/group_activities_tab.dart
//
// Onglet "Activités" du profil groupe. Le module Actions Terrain
// (ActionModel, ActionCard, CreateActionPage) n'existe pas encore dans le
// projet — conformément à la consigne du Lot 3, cet onglet reste un état
// "Bientôt disponible" plutôt qu'une carte approximative recréée à la main.
// À reconstruire avec le vrai ActionCard partagé une fois le module Actions
// Terrain implémenté.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import 'group_profile_widgets.dart';

class GroupActivitiesTab extends StatelessWidget {
  const GroupActivitiesTab({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le module Actions Terrain arrive bientôt.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
      child: Column(
        children: [
          Expanded(
            child: Center(
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
            ),
          ),
          GestureDetector(
            onTap: () => _showComingSoon(context),
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
  }
}
