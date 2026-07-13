// lib/features/map/pages/map_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/report_store.dart';
import '../../../core/utils/user_location_service.dart';
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
import 'package:cliinapp/features/auth/auth_guard.dart';

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

  // ── Filtres "Urgent" / "Proche" / "Récent" ────────────────────────
  // Règle fondamentale : ces 3 filtres ne travaillent JAMAIS qu'avec le
  // statut Disponible — jamais En cours, jamais Traité, quoi que
  // sélectionne par ailleurs le filtre "État du signalement". Quand
  // plusieurs sont actifs simultanément, leurs critères se cumulent
  // (ET, pas OU) — Urgent prime toujours, Proche/Récent le restreignent
  // davantage.
  static const Duration _recentWindow = Duration(hours: 72);
  static const double _nearbyRadiusMeters = 2000;

  List<HomeReportModel> get _filteredReports {
    List<HomeReportModel> result = List.from(ReportStore.instance.mapReports);

    final priorities = _filters.priorities;
    if (priorities.isNotEmpty) {
      result =
          result.where((r) => r.status == ReportStatus.disponible).toList();

      if (priorities.contains(MapPriorityFilter.urgents)) {
        result =
            result.where((r) => r.severity == ReportSeverity.critique).toList();
      }
      if (priorities.contains(MapPriorityFilter.proches)) {
        result = result.where((r) {
          final meters = UserLocationService.instance
              .distanceMetersTo(r.latitude, r.longitude);
          return meters != null && meters <= _nearbyRadiusMeters;
        }).toList();
      }
      if (priorities.contains(MapPriorityFilter.recents)) {
        result = result.where((r) {
          return r.createdAt != null &&
              DateTime.now().difference(r.createdAt!) <= _recentWindow;
        }).toList();
      }

      // Tri : "Proche" impose le tri par distance croissante, sinon
      // "Récent" impose le tri par date décroissante.
      if (priorities.contains(MapPriorityFilter.proches)) {
        result.sort((a, b) {
          final da = UserLocationService.instance
                  .distanceMetersTo(a.latitude, a.longitude) ??
              double.infinity;
          final db = UserLocationService.instance
                  .distanceMetersTo(b.latitude, b.longitude) ??
              double.infinity;
          return da.compareTo(db);
        });
      } else if (priorities.contains(MapPriorityFilter.recents)) {
        result.sort((a, b) {
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      }
    }

    if (_filters.statuses.isNotEmpty) {
      result = result.where((r) => _filters.statuses.contains(r.status)).toList();
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

  void _openCamera() async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      Navigator.push(context, fastFadeRoute<void>(const ReportCameraPage()));
    }
  }

  void _onNavTap(int index) =>
      navigateToTab(context, currentIndex: _navIndex, targetIndex: index);

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
      fastFadeRoute<void>(ReportDetailPage(data: report)),
    );
  }

  void _onTakeCharge(HomeReportModel report) async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      showTakeChargeFlow(
        context: context,
        report: report,
        onSuccess: (updated) {
          if (mounted) {
            Navigator.push(
              context,
              fastFadeRoute<void>(IntervenantDetailPage(report: updated)),
            );
          }
        },
      );
    }
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