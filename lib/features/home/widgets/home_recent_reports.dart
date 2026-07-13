// lib/features/home/widgets/home_recent_reports.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/ghost_report_card.dart';
import '../models/home_report_model.dart';

class HomeRecentReports extends StatelessWidget {
  final List<HomeReportModel> reports;
  final VoidCallback? onVoirTout;
  final void Function(HomeReportModel)? onCardTap;
  final void Function(HomeReportModel)? onTakeCharge;
  final void Function(HomeReportModel)? onContact;

  const HomeRecentReports({
    super.key,
    required this.reports,
    this.onVoirTout,
    this.onCardTap,
    this.onTakeCharge,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête ──
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cas récents',
                    style: CliinAppTextStyles.headingMedium
                        .copyWith(color: const Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: CliinAppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onVoirTout,
                child: Row(children: [
                  Text('Voir tout',
                      style: CliinAppTextStyles.link.copyWith(fontSize: 13)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right,
                      color: CliinAppColors.primary, size: 18),
                ]),
              ),
            ],
          ),
        ),

        const SizedBox(height: CliinAppConstants.spacingM),

        // ── Liste verticale ──
        if (reports.isEmpty)
          const _EmptyRecentReports()
        else
          ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.pagePadding),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: reports.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: CliinAppConstants.spacingM),
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportCard(
                data: report,
                onTap: onCardTap != null ? () => onCardTap!.call(report) : null,
                onTakeCharge: onTakeCharge != null
                    ? () => onTakeCharge!.call(report)
                    : null,
                onContact:
                    onContact != null ? () => onContact!.call(report) : null,
              );
            },
          ),
      ],
    );
  }
}

class _EmptyRecentReports extends StatelessWidget {
  const _EmptyRecentReports();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding,
          vertical: CliinAppConstants.spacingL,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const GhostReportCard(),
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: CliinAppConstants.spacingL),
              padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.spacingL,
                vertical: CliinAppConstants.spacingM,
              ),
              decoration: BoxDecoration(
                color: CliinAppColors.cardWhite,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
                border: Border.all(color: CliinAppColors.divider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 32,
                      color: CliinAppColors.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun cas récent dans votre zone',
                    textAlign: TextAlign.center,
                    style: CliinAppTextStyles.bodyMedium.copyWith(
                      color: CliinAppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
