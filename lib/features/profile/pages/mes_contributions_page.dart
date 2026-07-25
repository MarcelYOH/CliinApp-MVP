// lib/features/profile/pages/mes_contributions_page.dart
// Entrée "Mes contributions" du Profil — statistiques de contribution par
// groupe. Page minimale volontairement : la vraie logique de calcul sera
// implémentée dans un lot séparé (correction 1.3).

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/circle_icon_button.dart';

class MesContributionsPage extends StatelessWidget {
  const MesContributionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
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
                    child: Text('Mes contributions',
                        style: CliinAppTextStyles.headingMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.pagePadding),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          size: 56, color: CliinAppColors.textSecondary),
                      const SizedBox(height: CliinAppConstants.spacingM),
                      Text('Bientôt disponible',
                          style: CliinAppTextStyles.headingMedium),
                      const SizedBox(height: CliinAppConstants.spacingS),
                      Text(
                        'Retrouvez ici vos statistiques de contribution au '
                        'sein de vos groupes.',
                        textAlign: TextAlign.center,
                        style: CliinAppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
