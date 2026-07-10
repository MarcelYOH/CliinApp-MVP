// lib/features/map/widgets/reports_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../features/home/models/home_report_model.dart';
import 'status_filter_section.dart';

enum MapSortOption { distance, recence, gravite, popularite }

extension MapSortOptionExt on MapSortOption {
  String get label {
    switch (this) {
      case MapSortOption.distance:   return 'Distance';
      case MapSortOption.recence:    return 'Récence';
      case MapSortOption.gravite:    return 'Gravité';
      case MapSortOption.popularite: return 'Popularité';
    }
  }
}

class ReportsBottomSheet extends StatefulWidget {
  final List<HomeReportModel> reports;
  final Set<MapStatusFilter> activeFilters;
  // onCardTap = ouvrir détails (futur) — NE déclenche PAS la prise en charge
  final void Function(HomeReportModel)? onCardTap;
  final void Function(HomeReportModel)? onTakeCharge;
  final void Function(HomeReportModel)? onContact; // ← WhatsApp public
  final double availableHeight;

  const ReportsBottomSheet({
    super.key,
    required this.reports,
    required this.activeFilters,
    required this.availableHeight,
    this.onCardTap,
    this.onTakeCharge,
    this.onContact,
  });

  @override
  State<ReportsBottomSheet> createState() => _ReportsBottomSheetState();
}

class _ReportsBottomSheetState extends State<ReportsBottomSheet>
    with SingleTickerProviderStateMixin {
  MapSortOption _sortOption = MapSortOption.distance;

  late double _sheetHeight;
  double _dragStartHeight = 0;
  double _dragStartY      = 0;

  late AnimationController _animController;
  double _animFrom = 0;
  double _animTo   = 0;

  final ScrollController _scrollController = ScrollController();

  static const double _fracMin  = 0.22;
  static const double _fracMid1 = 0.35;
  static const double _fracMid2 = 0.65;
  static const double _fracMax  = 1.00;

  @override
  void initState() {
    super.initState();
    _sheetHeight = widget.availableHeight * _fracMid1;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animController.addListener(() {
      setState(() {
        _sheetHeight = _animFrom + (_animTo - _animFrom) *
            CurvedAnimation(parent: _animController, curve: Curves.easeOut)
                .value;
      });
    });
  }

  @override
  void didUpdateWidget(ReportsBottomSheet old) {
    super.didUpdateWidget(old);
    if (old.availableHeight != widget.availableHeight) {
      _sheetHeight = widget.availableHeight * _fracMid1;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double get _maxH => widget.availableHeight * _fracMax;
  double get _minH => widget.availableHeight * _fracMin;

  List<double> get _snaps => [
    widget.availableHeight * _fracMin,
    widget.availableHeight * _fracMid1,
    widget.availableHeight * _fracMid2,
    widget.availableHeight * _fracMax,
  ];

  void _snapTo(double targetH) {
    _animController.stop();
    _animFrom = _sheetHeight;
    _animTo   = targetH.clamp(_minH, _maxH);
    _animController.forward(from: 0);
  }

  void _snapToNearest(double velocityDy) {
    final snaps   = _snaps;
    final current = _sheetHeight;
    double target;

    if (velocityDy > 600) {
      target = snaps.firstWhere(
        (s) => s < current - widget.availableHeight * 0.05,
        orElse: () => snaps.first,
      );
    } else if (velocityDy < -600) {
      target = snaps.lastWhere(
        (s) => s > current + widget.availableHeight * 0.05,
        orElse: () => snaps.last,
      );
    } else {
      target = snaps.reduce(
        (a, b) => (a - current).abs() < (b - current).abs() ? a : b,
      );
    }
    _snapTo(target);
  }

  Color get _labelColor {
    if (widget.activeFilters.isEmpty) return CliinAppColors.textDark;
    switch (widget.activeFilters.first) {
      case MapStatusFilter.urgents:    return CliinAppColors.alertRed;
      case MapStatusFilter.proches:    return CliinAppColors.primary;
      case MapStatusFilter.recents:    return const Color(0xFF1E88E5);
      case MapStatusFilter.enCours:    return CliinAppColors.alertOrange;
      case MapStatusFilter.traites:    return CliinAppColors.primary;
      case MapStatusFilter.nonTraites: return CliinAppColors.textSecondary;
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(CliinAppConstants.radiusLarge)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding,
            vertical: CliinAppConstants.spacingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trier par',
                  style: CliinAppTextStyles.headingMedium
                      .copyWith(color: CliinAppColors.textDark)),
              const SizedBox(height: CliinAppConstants.spacingL),
              ...MapSortOption.values.map((opt) {
                final sel = _sortOption == opt;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    sel
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: sel
                        ? CliinAppColors.primary
                        : CliinAppColors.textSecondary,
                  ),
                  title: Text(opt.label,
                      style: CliinAppTextStyles.bodyMedium.copyWith(
                        color: sel
                            ? CliinAppColors.primary
                            : CliinAppColors.textDark,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400,
                      )),
                  onTap: () {
                    setState(() => _sortOption = opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = _sheetHeight.clamp(_minH, _maxH);

    return Positioned(
      left: 0, right: 0, bottom: 0,
      height: height,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          _animController.stop();
          _dragStartY      = details.globalPosition.dy;
          _dragStartHeight = _sheetHeight;
        },
        onVerticalDragUpdate: (details) {
          final dy   = details.globalPosition.dy - _dragStartY;
          final newH = (_dragStartHeight - dy).clamp(_minH, _maxH);
          if (dy > 0) {
            setState(() => _sheetHeight = newH);
          } else {
            if (height < _maxH - 2) {
              setState(() => _sheetHeight = newH);
            }
          }
        },
        onVerticalDragEnd: (details) {
          _snapToNearest(details.velocity.pixelsPerSecond.dy);
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(CliinAppConstants.radiusLarge),
              topRight: Radius.circular(CliinAppConstants.radiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(
                    top: CliinAppConstants.spacingM,
                    bottom: CliinAppConstants.spacingXS,
                  ),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: CliinAppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──
              SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CliinAppConstants.pagePadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildTitle()),
                      const SizedBox(width: CliinAppConstants.spacingS),
                      GestureDetector(
                        onTap: () => _showSortSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: CliinAppConstants.spacingM,
                              vertical: 8),
                          decoration: BoxDecoration(
                            color: CliinAppColors.background,
                            borderRadius: BorderRadius.circular(
                                CliinAppConstants.radiusMedium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_vert_rounded,
                                  size: 16, color: CliinAppColors.textDark),
                              const SizedBox(width: 4),
                              Text('Trier',
                                  style: CliinAppTextStyles.bodySmall.copyWith(
                                    color: CliinAppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  )),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: CliinAppColors.textDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

              // ── Liste scrollable ──
              Expanded(
                child: widget.reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: CliinAppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun cas trouvé avec ces critères',
                              textAlign: TextAlign.center,
                              style: CliinAppTextStyles.bodyMedium.copyWith(
                                  color: CliinAppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          CliinAppConstants.pagePadding,
                          CliinAppConstants.spacingM,
                          CliinAppConstants.pagePadding,
                          80,
                        ),
                        itemCount: widget.reports.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: CliinAppConstants.spacingM),
                        itemBuilder: (context, index) {
                          final report = widget.reports[index];
                          return ReportCard(
                            data: report,
                            onTap: widget.onCardTap != null
                                ? () => widget.onCardTap!.call(report)
                                : null,
                            onTakeCharge: widget.onTakeCharge != null
                                ? () => widget.onTakeCharge!.call(report)
                                : null,
                            onContact: widget.onContact != null
                                ? () => widget.onContact!.call(report)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    if (widget.activeFilters.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Cas d\'insalubrité',
              style: CliinAppTextStyles.headingMedium
                  .copyWith(color: CliinAppColors.textDark, fontSize: 16),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${widget.reports.length} résultats dans cette zone',
              style: CliinAppTextStyles.bodySmall
                  .copyWith(color: CliinAppColors.textSecondary, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      );
    }

    final labels = widget.activeFilters.map((f) => f.label).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cas d\'insalubrité ',
                style: CliinAppTextStyles.headingMedium.copyWith(
                    color: CliinAppColors.textDark, fontSize: 16),
                maxLines: 1),
            Flexible(
              child: Text('($labels)',
                  style: CliinAppTextStyles.headingMedium.copyWith(
                      color: _labelColor, fontSize: 16),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        Text('${widget.reports.length} résultats dans cette zone',
            style: CliinAppTextStyles.bodySmall.copyWith(
                color: CliinAppColors.textSecondary, fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}