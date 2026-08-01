// lib/features/profile/pages/cas_suivis_page.dart
// Entrée "Cas suivis" du Profil — liste des signalements que l'utilisateur
// suit (bouton "Suivre" déjà existant sur les cartes/détail de
// signalement, persistance réelle via ReportStore.reportFollowerIds).

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/report_card.dart';
import '../../home/models/home_report_model.dart';
import '../../reports/pages/report_detail_page.dart';

class CasSuivisPage extends StatelessWidget {
  const CasSuivisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ReportStore.instance, AuthStore.instance]),
      builder: (context, _) {
        final userId = AuthStore.instance.currentUser?.id;
        final List<HomeReportModel> followed = userId == null
            ? const []
            : ReportStore.instance.followedReportsFor(userId);
        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: followed.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            CliinAppConstants.pagePadding,
                            CliinAppConstants.spacingM,
                            CliinAppConstants.pagePadding,
                            MediaQuery.of(context).padding.bottom +
                                CliinAppConstants.spacingXL,
                          ),
                          itemCount: followed.length,
                          separatorBuilder: (_, _) => const SizedBox(
                              height: CliinAppConstants.spacingM),
                          itemBuilder: (context, i) {
                            final report = followed[i];
                            return ReportCard(
                              data: report,
                              // Un simple suiveur voit toujours le détail
                              // public du cas, jamais un détail privé/
                              // intervenant (règle déjà validée ailleurs).
                              onTap: () => Navigator.push(
                                context,
                                fastFadeRoute<void>(
                                    ReportDetailPage(data: report)),
                              ),
                            );
                          },
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
            child:
                Text('Cas suivis', style: CliinAppTextStyles.headingMedium),
          ),
        ],
      ),
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
            const Icon(Icons.notifications_none_rounded,
                size: 56, color: CliinAppColors.textSecondary),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(
              'Vous ne suivez aucun cas pour le moment. Suivez un cas pour '
              'être informé de son évolution.',
              textAlign: TextAlign.center,
              style: CliinAppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
