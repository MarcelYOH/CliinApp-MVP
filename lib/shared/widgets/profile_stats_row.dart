// lib/shared/widgets/profile_stats_row.dart
//
// Bloc de statistiques du profil (Correction 1 — fusion) — composant
// UNIQUE réutilisé par profile_page.dart (Profil privé) ET
// public_profile_page.dart (Profil public), pour que toute statistique
// affichée reste automatiquement synchronisée aux deux endroits (même
// source, même ordre, même style) — plus jamais deux implémentations
// séparées à maintenir.
//
// Correction 2 — jamais condensé pour faire tenir plus de statistiques :
// chaque carte garde une largeur confortable fixe (identique au design
// original à 3 statistiques) ; si l'ensemble dépasse la largeur de
// l'écran (4 statistiques ou plus à l'avenir), la rangée défile
// horizontalement au lieu de rétrécir les cartes.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../store/action_store.dart';
import '../store/report_store.dart';

class ProfileStatsRow extends StatelessWidget {
  final String? userId;
  const ProfileStatsRow({super.key, required this.userId});

  // Largeur confortable par carte — identique au rendu du design original
  // à 3 statistiques (icône 28 + valeur 22 + libellé sur 2 lignes max).
  static const double _itemWidth = 104;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ReportStore.instance, ActionStore.instance]),
      builder: (context, _) {
        final id = userId;
        final casPublies =
            id != null ? ReportStore.instance.casPubliesCount(id) : 0;
        final prisEnCharge =
            id != null ? ReportStore.instance.prisEnChargeCount(id) : 0;
        final casTraites =
            id != null ? ReportStore.instance.casTraitesCount(id) : 0;
        // Actions organisées en nom personnel uniquement (les actions
        // organisées au nom d'un groupe relèvent de Mes contributions,
        // jamais comptées deux fois ici) — même règle que l'ancien
        // composant de profile_page.dart.
        final actionsOrganisees = id != null
            ? ActionStore.instance.myActionsOrganiseesCount(id)
            : 0;

        final stats = <(IconData, String, String, Color)>[
          (Icons.description_outlined, '$casPublies', 'Cas publiés',
              CliinAppColors.primary),
          (Icons.volunteer_activism_outlined, '$prisEnCharge',
              'Pris en charge', CliinAppColors.alertOrange),
          (Icons.check_circle_outline_rounded, '$casTraites', 'Cas traités',
              CliinAppColors.infoBlue),
          (Icons.bolt_rounded, '$actionsOrganisees', 'Actions organisées',
              CliinAppColors.levelEngage),
        ];

        return Container(
          decoration: BoxDecoration(
            color: CliinAppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      const VerticalDivider(
                          width: 1, thickness: 1, color: CliinAppColors.divider),
                    _buildStatItem(stats[i].$1, stats[i].$2, stats[i].$3,
                        stats[i].$4),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return SizedBox(
      width: _itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: CliinAppTextStyles.headingMedium.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: CliinAppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
