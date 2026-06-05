// lib/features/home/widgets/home_recent_reports.dart
// Bloc "Récents signalements" — liste verticale — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/report_card.dart';
import '../models/report_model.dart';

class HomeRecentReports extends StatelessWidget {
  final List<HomeReportModel> reports;
  final VoidCallback? onVoirTout;
  final void Function(HomeReportModel)? onCardTap;

  const HomeRecentReports({
    super.key,
    required this.reports,
    this.onVoirTout,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête section ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Récents signalements',
                style: CliinAppTextStyles.headingMedium.copyWith(
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: onVoirTout,
                child: Row(
                  children: [
                    Text(
                      'Voir tout',
                      style: CliinAppTextStyles.link.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      color: CliinAppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: CliinAppConstants.spacingM),

        // ── Liste verticale — pleine largeur ──
        ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: reports.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: CliinAppConstants.spacingM),
          itemBuilder: (context, index) {
            return ReportCard(
              data: reports[index],
              onTap: () => onCardTap?.call(reports[index]),
            );
          },
        ),
      ],
    );
  }
}