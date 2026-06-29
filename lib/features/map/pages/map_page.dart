// lib/features/map/pages/map_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/store/report_store.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../../features/reports/pages/report_camera_page.dart';
import '../../../features/reports/pages/report_detail_page.dart';
import '../../../features/reports/pages/intervenant_detail_page.dart';
import '../../../features/reports/widgets/take_charge_flow.dart';
import '../../../features/home/models/home_report_model.dart';
import '../models/map_filter_model.dart';
import '../widgets/map_search_header.dart';
import '../widgets/interactive_map_widget.dart';
import '../widgets/reports_bottom_sheet.dart';
import '../widgets/map_filter_panel.dart';
import '../widgets/map_active_filters_bar.dart';

class MapPage extends StatefulWidget {
  final Set<MapPriorityFilter> initialPriorityFilters;
  final Set<ReportCategory> initialCategoryFilters;

  const MapPage({
    super.key,
    this.initialPriorityFilters = const {},
    this.initialCategoryFilters = const {},
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const int _navIndex = 1;

  late MapFilterState _filters;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = MapFilterState(
      priorities: Set.from(widget.initialPriorityFilters),
      categories: Set.from(widget.initialCategoryFilters),
    );
    // Enregistrement différé : évite des setState() parasites pendant
    // l'animation d'ouverture de la page (transition de navigation).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ReportStore.instance.addListener(_onStoreUpdate);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    ReportStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  List<HomeReportModel> get _filteredReports {
    List<HomeReportModel> result = List.from(ReportStore.instance.mapReports);

    if (_filters.statuses.isNotEmpty) {
      result = result.where((r) => _filters.statuses.contains(r.status)).toList();
    }
    if (_filters.priorities.isNotEmpty) {
      result = result.where((r) {
        return _filters.priorities.any((p) {
          switch (p) {
            case MapPriorityFilter.urgents:
              return r.severity == ReportSeverity.critique;
            case MapPriorityFilter.proches:
              return _toMeters(r.distance) <= 2000;
            case MapPriorityFilter.recents:
              return _toMinutes(r.timeAgo) <= 4320;
          }
        });
      }).toList();
    }
    if (_filters.categories.isNotEmpty) {
      result = result.where((r) => _filters.categories.contains(r.category)).toList();
    }
    if (_filters.gravities.isNotEmpty) {
      result = result.where((r) {
        return _filters.gravities.any((g) {
          switch (g) {
            case MapGravityFilter.critique: return r.severity == ReportSeverity.critique;
            case MapGravityFilter.eleve:    return r.severity == ReportSeverity.eleve;
            case MapGravityFilter.moyen:    return r.severity == ReportSeverity.moyen;
            case MapGravityFilter.faible:   return r.severity == ReportSeverity.faible;
          }
        });
      }).toList();
    }
    return result;
  }

  double _toMeters(String distance) {
    final s = distance.toLowerCase().trim();
    if (s.contains('km')) {
      return (double.tryParse(s.replaceAll('km', '').trim()) ?? 9999) * 1000;
    }
    return double.tryParse(s.replaceAll('m', '').trim()) ?? 9999;
  }

  double _toMinutes(String timeAgo) {
    final s = timeAgo.toLowerCase();
    final n = double.tryParse(RegExp(r'\d+').firstMatch(s)?.group(0) ?? '999') ?? 999;
    if (s.contains('min')) return n;
    if (s.contains(' h')) return n * 60;
    if (s.contains('j'))  return n * 1440;
    return 999;
  }

  void _openCamera() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportCameraPage()));
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    if (index == 0) Navigator.pop(context);
  }

  void _onMyLocationTap() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Recentrage sur votre position...'),
      duration: Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _openFilterPanel() {
    MapFilterPanel.show(
      context: context,
      initialFilters: _filters,
      onApply: (f) => setState(() => _filters = f),
    );
  }

  void _onCardTap(HomeReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => ReportDetailPage(data: report)),
    );
  }

  void _onTakeCharge(HomeReportModel report) {
    showTakeChargeFlow(
      context: context,
      report: report,
      onSuccess: (updated) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IntervenantDetailPage(report: updated),
            ),
          );
        }
      },
    );
  }

  // ── Contacter via WhatsApp — carte publique ───────────────────
  void _onContact(HomeReportModel report) {
    openWhatsApp(
      context: context,
      intervenant: report.intervenant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = !_filters.isEmpty;

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  MapSearchHeader(
                    controller: _searchController,
                    onMyLocationTap: _onMyLocationTap,
                    onSearch: (_) {},
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        CliinAppConstants.pagePadding, 0,
                        CliinAppConstants.pagePadding, CliinAppConstants.spacingS),
                    child: Row(children: [
                      GestureDetector(
                        onTap: _openFilterPanel,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: CliinAppConstants.spacingM + 2,
                              vertical: CliinAppConstants.spacingS + 2),
                          decoration: BoxDecoration(
                            color: hasFilters ? CliinAppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
                            border: Border.all(
                              color: hasFilters ? CliinAppColors.primary : CliinAppColors.divider,
                              width: 1.2,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.tune_rounded,
                                size: 16,
                                color: hasFilters ? Colors.white : CliinAppColors.textDark),
                            const SizedBox(width: 6),
                            Text(
                              hasFilters ? 'Filtres (${_filters.totalActive})' : 'Filtres',
                              style: CliinAppTextStyles.badge.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasFilters ? Colors.white : CliinAppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: hasFilters ? Colors.white : CliinAppColors.textSecondary),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  if (hasFilters)
                    Padding(
                      padding: const EdgeInsets.only(bottom: CliinAppConstants.spacingS),
                      child: MapActiveFiltersBar(
                        filters: _filters,
                        onClearAll: () => setState(() => _filters = const MapFilterState()),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveMapWidget(
                        onLayersTap: () {},
                        onRecenterTap: _onMyLocationTap,
                      ),
                    ),
                    ReportsBottomSheet(
                      reports: _filteredReports,
                      activeFilters: const {},
                      availableHeight: constraints.maxHeight,
                      onCardTap: _onCardTap,
                      onTakeCharge: _onTakeCharge,
                      onContact: _onContact,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        onSignalerTap: _openCamera,
      ),
    );
  }
}