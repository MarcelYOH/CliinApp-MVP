// lib/features/home/widgets/home_nearby_reports.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/report_card.dart';
import '../models/home_report_model.dart';

class HomeNearbyReports extends StatelessWidget {
  final List<HomeReportModel> reports;
  final VoidCallback? onVoirTout;
  final void Function(HomeReportModel)? onCardTap;
  final void Function(HomeReportModel)? onTakeCharge;
  final void Function(HomeReportModel)? onContact;
  final void Function(HomeReportModel)? onViewDetails;

  const HomeNearbyReports({
    super.key,
    required this.reports,
    this.onVoirTout,
    this.onCardTap,
    this.onTakeCharge,
    this.onContact,
    this.onViewDetails,
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
                    'À proximité',
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

        // ── Scroll horizontal avec hauteur uniforme ──
        // UniformCardRow mesure la hauteur de la plus grande carte
        // et impose cette hauteur à toutes via SizedBox
        _UniformHeightCardRow(
          reports: reports,
          cardWidth: 300,
          onCardTap: onCardTap,
          onTakeCharge: onTakeCharge,
          onContact: onContact,
          onViewDetails: onViewDetails,
        ),
      ],
    );
  }
}

/// Rend toutes les cartes à la même hauteur :
/// mesure d'abord avec Offstage, puis affiche avec hauteur fixe.
class _UniformHeightCardRow extends StatefulWidget {
  final List<HomeReportModel> reports;
  final double cardWidth;
  final void Function(HomeReportModel)? onCardTap;
  final void Function(HomeReportModel)? onTakeCharge;
  final void Function(HomeReportModel)? onContact;
  final void Function(HomeReportModel)? onViewDetails;

  const _UniformHeightCardRow({
    required this.reports,
    required this.cardWidth,
    this.onCardTap,
    this.onTakeCharge,
    this.onContact,
    this.onViewDetails,
  });

  @override
  State<_UniformHeightCardRow> createState() => _UniformHeightCardRowState();
}

class _UniformHeightCardRowState extends State<_UniformHeightCardRow> {
  double? _maxHeight;
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _keys.addAll(List.generate(widget.reports.length, (_) => GlobalKey()));
    // Mesure après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeights());
  }

  void _measureHeights() {
    double max = 0;
    for (final key in _keys) {
      final ctx = key.currentContext;
      if (ctx != null) {
        final h = ctx.size?.height ?? 0;
        if (h > max) max = h;
      }
    }
    if (max > 0 && max != _maxHeight) {
      setState(() => _maxHeight = max);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.reports.length; i++) ...[
            if (i > 0) const SizedBox(width: CliinAppConstants.spacingM),
            _maxHeight != null
                // ── Hauteur fixe connue : toutes les cartes à la même taille ──
                ? SizedBox(
                    width: widget.cardWidth,
                    height: _maxHeight,
                    child: ReportCard(
                      data: widget.reports[i],
                      width: widget.cardWidth,
                      onTap: () => widget.onCardTap?.call(widget.reports[i]),
                      onTakeCharge: () =>
                          widget.onTakeCharge?.call(widget.reports[i]),
                      onContact: () =>
                          widget.onContact?.call(widget.reports[i]),
                      onViewDetails: () =>
                          widget.onViewDetails?.call(widget.reports[i]),
                    ),
                  )
                // ── Premier rendu : mesure invisible ──
                : SizedBox(
                    key: _keys[i],
                    width: widget.cardWidth,
                    child: ReportCard(
                      data: widget.reports[i],
                      width: widget.cardWidth,
                      onTap: () => widget.onCardTap?.call(widget.reports[i]),
                      onTakeCharge: () =>
                          widget.onTakeCharge?.call(widget.reports[i]),
                      onContact: () =>
                          widget.onContact?.call(widget.reports[i]),
                      onViewDetails: () =>
                          widget.onViewDetails?.call(widget.reports[i]),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}