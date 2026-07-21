// lib/dev/report_card_test_page.dart
// ⚠️ PAGE TEMPORAIRE — À supprimer avant mise en production

import 'package:flutter/material.dart';
import 'package:cliinapp/core/constants/app_colors.dart';
import 'package:cliinapp/core/constants/app_constants.dart';
import 'package:cliinapp/core/constants/app_text_styles.dart';
import 'package:cliinapp/shared/widgets/report_card.dart';
import 'package:cliinapp/features/home/models/home_report_model.dart';

class ReportCardTestPage extends StatelessWidget {
  const ReportCardTestPage({super.key});

  static const _disponible = HomeReportModel(
    id: '1',
    reference: '#CLN-9021',
    title: 'Dépôts sauvages',
    location: 'Yopougon, Sicogi',
    description: "Accumulation importante d'ordures ménagères non collectées.",
    severity: ReportSeverity.critique,
    category: ReportCategory.depotsSauvages,
    imageAsset: 'assets/images/depot.jpg',
    distance: '250 m',
    timeAgo: 'Il y a 45 min',
    status: ReportStatus.disponible,
    views: 7,
    comments: 1,
    shares: 2,
  );

  static const _enCours = HomeReportModel(
    id: '2',
    reference: '#CLN-9022',
    title: 'Dépôts sauvages',
    location: 'Yopougon, Sicogi',
    description: "Accumulation importante d'ordures ménagères non collectées.",
    severity: ReportSeverity.critique,
    category: ReportCategory.depotsSauvages,
    imageAsset: 'assets/images/depot.jpg',
    distance: '250 m',
    timeAgo: 'Il y a 45 min',
    status: ReportStatus.enCours,
    intervenant: IntervenantModel(
      id: 'eco-jeune',
      name: 'Eco Jeune',
      takenAgo: 'Il y a 10 min',
    ),
    views: 7,
    comments: 1,
    shares: 2,
  );

  static const _traite = HomeReportModel(
    id: '3',
    reference: '#CLN-9023',
    title: 'Dépôts sauvages',
    location: 'Yopougon, Sicogi',
    description: "Accumulation importante d'ordures ménagères non collectées.",
    severity: ReportSeverity.critique,
    category: ReportCategory.depotsSauvages,
    imageAsset: 'assets/images/depot.jpg',
    imageAfterAsset: 'assets/images/caniveau.jpg',
    distance: '300 m',
    timeAgo: 'Il y a 2h',
    status: ReportStatus.traite,
    intervenant: IntervenantModel(
      id: 'eco-jeune',
      name: 'Eco Jeune',
    ),
    views: 24,
    comments: 3,
    shares: 5,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      appBar: AppBar(
        backgroundColor: CliinAppColors.cardWhite,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.spacingS,
                vertical: CliinAppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: CliinAppColors.alertOrange.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: Text(
                'DEV',
                style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.alertOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: CliinAppConstants.spacingS),
            Text('Test ReportCard',
                style: CliinAppTextStyles.headingSmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
        children: [
          _SectionLabel(
            label: '🟢  État 1 — Disponible',
            subtitle: 'Bouton "Prendre en charge" visible',
          ),
          const SizedBox(height: CliinAppConstants.spacingS),
          ReportCard(
            data: _disponible,
            onTakeCharge: () =>
                _showSnack(context, '✅ Prendre en charge tapé'),
          ),
          const SizedBox(height: CliinAppConstants.spacingXL),
          _SectionLabel(
            label: '🟡  État 2 — En cours',
            subtitle: 'Bloc intervenant + bouton Contacter',
          ),
          const SizedBox(height: CliinAppConstants.spacingS),
          ReportCard(
            data: _enCours,
            onContact: () => _showSnack(context, '💬 Contacter tapé'),
          ),
          const SizedBox(height: CliinAppConstants.spacingXL),
          _SectionLabel(
            label: '🔵  État 3 — Traité',
            subtitle: 'Double photo AVANT/APRÈS + Voir les détails',
          ),
          const SizedBox(height: CliinAppConstants.spacingS),
          ReportCard(
            data: _traite,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: CliinAppColors.primaryDark,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String subtitle;
  const _SectionLabel({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CliinAppTextStyles.headingSmall),
        const SizedBox(height: 2),
        Text(subtitle,
            style: CliinAppTextStyles.bodySmall
                .copyWith(color: CliinAppColors.textSecondary)),
      ],
    );
  }
}