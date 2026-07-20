// lib/features/map/pages/map_page.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
import '../../../shared/utils/report_search.dart';
import 'package:cliinapp/features/auth/auth_guard.dart';

class MapPage extends StatefulWidget {
  final Set<MapPriorityFilter> initialPriorityFilters;
  final Set<ReportCategory> initialCategoryFilters;
  // Recherche déjà appliquée en arrivant depuis un autre écran (ex: barre
  // de recherche de l'accueil) — combinée aux filtres, jamais à leur place.
  final String initialSearchQuery;

  const MapPage({
    super.key,
    this.initialPriorityFilters = const {},
    this.initialCategoryFilters = const {},
    this.initialSearchQuery = '',
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const int _navIndex = 1;

  late MapFilterState _filters;
  final TextEditingController _searchController = TextEditingController();
  late String _searchQuery;

  // ── Correction 4/5 — recentrage "Ma position" + recherche par zone ──
  // Centre effectif d'un mode "proximité" (2km) : soit la position réelle
  // de l'utilisateur (après tap "Ma position"), soit le centre géocodé
  // d'une zone recherchée. null tant qu'aucune des deux actions n'a été
  // déclenchée — la carte reste alors en mode "explorer tout" (comportement
  // existant, jamais modifié par défaut).
  ({double lat, double lng})? _zoneCenter;
  bool _proximityModeActive = false;
  String? _searchedZoneLabel;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _filters = MapFilterState(
      priorities: Set.from(widget.initialPriorityFilters),
      categories: Set.from(widget.initialCategoryFilters),
    );
    _searchQuery = widget.initialSearchQuery;
    _searchController.text = widget.initialSearchQuery;
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

  // Distance vers le centre effectif (position réelle ou zone recherchée) —
  // même rayon de 2km que "À proximité" sur l'accueil, appliqué autour d'un
  // centre potentiellement différent de la position de l'utilisateur.
  double? _distanceToZoneCenter(HomeReportModel r) {
    final center = _zoneCenter;
    if (center == null) {
      return UserLocationService.instance.distanceMetersTo(r.latitude, r.longitude);
    }
    if (r.latitude == null || r.longitude == null) return null;
    return Geolocator.distanceBetween(
      center.lat, center.lng, r.latitude!, r.longitude!,
    );
  }

  List<HomeReportModel> get _filteredReports {
    // ── Mode proximité (Ma position / recherche de zone) — NOUVELLE
    // LOGIQUE MÉTIER : recentre l'affichage sur un centre (position réelle
    // ou zone recherchée) et ne montre que les cas Disponibles dans un
    // rayon de 2km autour de ce centre, triés du plus proche au plus
    // éloigné — cohérent avec Google Maps. Remplace entièrement le mode
    // "explorer tout" tant que ce mode est actif.
    if (_proximityModeActive) {
      final result = ReportStore.instance.mapReports
          .where((r) => r.status == ReportStatus.disponible)
          .map((r) => (report: r, meters: _distanceToZoneCenter(r)))
          .where((e) => e.meters != null && e.meters! <= _nearbyRadiusMeters)
          .toList()
        ..sort((a, b) => a.meters!.compareTo(b.meters!));
      var filtered = result.map((e) => e.report).toList();
      if (_filters.categories.isNotEmpty) {
        filtered =
            filtered.where((r) => _filters.categories.contains(r.category)).toList();
      }
      if (_filters.gravities.isNotEmpty) {
        filtered = filtered.where((r) {
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
      return filtered;
    }

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
    if (_searchQuery.isNotEmpty) {
      result =
          result.where((r) => matchesReportSearch(r, _searchQuery)).toList();
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

  // ── Correction 4 — "Ma position" réinitialise complètement la vue ────
  Future<void> _onMyLocationTap() async {
    _searchToken++;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Recentrage sur votre position...'),
      duration: Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
    // Position GPS actuelle réelle — force un nouveau relevé plutôt que le
    // cache, pour garantir qu'on recentre bien sur la position présente.
    await UserLocationService.instance.getCurrentPosition(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _zoneCenter = null; // centre = position réelle (live), pas un point figé
      _proximityModeActive = true;
      _searchedZoneLabel = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // ── Correction 5 — recherche par zone : recentrage + rayon 2km ───────
  Future<void> _onSearch(String query) async {
    final token = ++_searchToken;
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _zoneCenter = null;
        _proximityModeActive = false;
        _searchedZoneLabel = null;
      });
      return;
    }

    // Recherche par code identifiant (#CLN-...) : comportement texte
    // existant, jamais transformé en recherche de zone géographique.
    final looksLikeCode =
        query.startsWith('#') || RegExp(r'^cln', caseSensitive: false).hasMatch(query);
    if (looksLikeCode) {
      setState(() {
        _searchQuery = query;
        _zoneCenter = null;
        _proximityModeActive = false;
        _searchedZoneLabel = null;
      });
      return;
    }

    // Géocodage du nom de zone tapé — pilote San-Pedro, Côte d'Ivoire
    // (cf. pubspec) : suffixe le pays pour lever l'ambiguïté des noms de
    // quartiers/communes locaux.
    try {
      final locations = await locationFromAddress('$query, Côte d\'Ivoire');
      if (token != _searchToken || !mounted) return;
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _zoneCenter = (lat: loc.latitude, lng: loc.longitude);
          _proximityModeActive = true;
          _searchedZoneLabel = query;
          _searchQuery = '';
        });
        return;
      }
    } catch (_) {
      // Géocodage indisponible/échoué — repli sur la recherche texte
      // existante ci-dessous plutôt que de bloquer l'utilisateur.
    }

    if (token != _searchToken || !mounted) return;
    setState(() {
      _searchQuery = query;
      _zoneCenter = null;
      _proximityModeActive = false;
      _searchedZoneLabel = null;
    });
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

  // ── Bandeau "autour de..." — confirme visuellement le centre actif et
  // permet de revenir au mode "explorer tout" ─────────────────────────
  Widget _buildProximityBanner() {
    final label = _zoneCenter != null
        ? 'Autour de « $_searchedZoneLabel » (2 km)'
        : 'Autour de votre position (2 km)';
    return Padding(
      padding: const EdgeInsets.only(bottom: CliinAppConstants.spacingS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CliinAppColors.primaryLight,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(
          children: [
            const Icon(Icons.my_location_rounded,
                size: 14, color: CliinAppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.primary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _proximityModeActive = false;
                _zoneCenter = null;
                _searchedZoneLabel = null;
              }),
              child: Text(
                'Tout afficher',
                style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = !_filters.isEmpty;

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Column(
                children: [
                  MapSearchHeader(
                    controller: _searchController,
                    onMyLocationTap: _onMyLocationTap,
                    onSearch: _onSearch,
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
                  if (_proximityModeActive) _buildProximityBanner(),
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
                      emptyStateMessage: _proximityModeActive && _zoneCenter != null
                          ? 'Aucun cas dans cette zone pour le moment'
                          : null,
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