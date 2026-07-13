// lib/shared/widgets/ghost_report_card.dart
// Carte "fantôme" — état vide professionnel pour les sections de la page
// d'accueil sans données réelles (ex: "À proximité", "Cas récents").
//
// Reprend la mise en page de ReportCard (zone photo, lignes de texte,
// footer à 3 statistiques) mais avec des blocs gris neutres à la place
// de vraies données, pour suggérer l'espace qu'occuperait un signalement
// plutôt que de laisser un vide plat — comme les "ghost cards" utilisées
// par LinkedIn ou Airbnb dans leurs états vides.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class GhostReportCard extends StatelessWidget {
  final double? width;

  const GhostReportCard({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusMedium + 2),
          border: Border.all(color: CliinAppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zone photo — rectangle uni + icône discrète ──
            Container(
              height: 200,
              width: double.infinity,
              color: CliinAppColors.background,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: CliinAppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),

            // ── Lignes de texte — skeleton statique ──
            Padding(
              padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonLine(width: 160, height: 14),
                  const SizedBox(height: 10),
                  _skeletonLine(width: 110, height: 11),
                  const SizedBox(height: 12),
                  _skeletonLine(width: double.infinity, height: 11),
                  const SizedBox(height: 6),
                  _skeletonLine(width: 200, height: 11),
                ],
              ),
            ),

            Container(height: 1, color: CliinAppColors.divider),

            // ── Footer — 3 statistiques fantômes ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.pagePadding,
                vertical: CliinAppConstants.spacingM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (_) => _skeletonLine(width: 36, height: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CliinAppColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
