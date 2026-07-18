// lib/features/groups/pages/group_search_page.dart
//
// Placeholder — la page de recherche complète (filtres combinables, champ
// de recherche fonctionnel, résultats de rechercherGroupes()...) sera
// construite au Lot 5. Ce squelette minimal existe uniquement pour que la
// navigation du Lot 1 (barre de recherche, "Voir tout"/"Voir plus" de la
// page principale) ait une destination réelle en attendant.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

class GroupSearchPage extends StatelessWidget {
  // "actifs" | "mesgroupes" | "decouvrir" — détermine le focus initial de
  // la recherche une fois le Lot 5 construit.
  final String origine;

  const GroupSearchPage({super.key, required this.origine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                CliinAppConstants.pagePadding,
                MediaQuery.of(context).padding.top + 12,
                CliinAppConstants.pagePadding,
                12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: CliinAppColors.textDark, size: 24),
                  ),
                  const SizedBox(width: CliinAppConstants.spacingM),
                  Text('Rechercher un groupe',
                      style: CliinAppTextStyles.headingSmall),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'La recherche complète des groupes arrive au Lot 5.',
                  style: CliinAppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
