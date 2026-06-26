// lib/features/home/pages/home_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/data/dummy_user.dart';
import '../../../shared/store/report_store.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../widgets/home_quick_report.dart';
import '../widgets/home_alert_banner.dart';
import '../widgets/home_nearby_reports.dart';
import '../widgets/home_action_banner.dart';
import '../widgets/home_groups.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_recent_reports.dart';
import '../data/home_dummy_data.dart';
import '../models/home_report_model.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../reports/pages/intervenant_detail_page.dart';
import '../../reports/widgets/take_charge_flow.dart';
import '../../map/pages/map_page.dart';
import '../../map/models/map_filter_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    ReportStore.instance.addListener(_onStoreUpdate);
    // init() est déjà appelé dans main() avant runApp() — ne pas rappeler ici
  }

  @override
  void dispose() {
    ReportStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  void _openCamera() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ReportCameraPage()));
  }

  void _onNavTap(int index) {
    if (index == 1) { _goToMap(); return; }
    setState(() => _currentNavIndex = index);
  }

  void _goToMap({
    Set<MapPriorityFilter>? priorities,
    Set<ReportCategory>? categories,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) => MapPage(
          initialPriorityFilters: priorities ?? const {},
          initialCategoryFilters: categories ?? const {},
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _goToMapUrgents()    => _goToMap(priorities: {MapPriorityFilter.urgents});
  void _goToMapProches()    => _goToMap(priorities: {MapPriorityFilter.proches});
  void _goToMapRecents()    => _goToMap(priorities: {MapPriorityFilter.recents});
  void _goToMapCategorie(ReportCategory cat) => _goToMap(categories: {cat});
  void _goToMapCategories() => _goToMap();

  ReportCategory? _labelToCategory(String label) {
    const map = {
      'Dépôts sauvages':      ReportCategory.depotsSauvages,
      'Caniveaux bouchés':    ReportCategory.caniveauxBouches,
      'Eaux stagnantes':      ReportCategory.eauxStagnantes,
      'Bac à déchets saturé': ReportCategory.bacDechetsSature,
      'Conteneur saturé':     ReportCategory.conteneurSature,
      'Zone insalubre':       ReportCategory.zoneInsalubre,
      'Déchets industriels':  ReportCategory.dechetsIndustriels,
      'Déchets médicaux':     ReportCategory.dechetsMedicaux,
      'Brûlage des déchets':  ReportCategory.brulageDesDechets,
    };
    return map[label];
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

  void _onViewDetails(HomeReportModel report) {
    if (report.intervenant != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IntervenantDetailPage(report: report),
        ),
      );
    }
  }

  // ── Contacter via WhatsApp — carte publique ───────────────────
  // Déclenché uniquement si intervenant.isContactable = true
  // (whatsAppVisible = true ET whatsAppNumber != null)
  void _onContact(HomeReportModel report) {
    openWhatsApp(
      context: context,
      intervenant: report.intervenant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStore.instance;

    final nearbyReports = store.nearbyReports.isNotEmpty
        ? store.nearbyReports
        : HomeDummyData.nearbyReports;

    final recentReports = store.recentReports.isNotEmpty
        ? store.recentReports
        : HomeDummyData.recentReports
            .where((r) => r.status == ReportStatus.disponible)
            .take(1)
            .toList();

    final firstName = DummyUser.currentUser.name.split(' ').first;
    final contextLine =
        '${HomeDummyData.position.value} · ${nearbyReports.length} cas à proximité';

    final sections = <Widget>[
      HomeQuickReport(data: HomeDummyData.quickReport, onTap: _openCamera),
      HomeAlertBanner(
          data: HomeDummyData.alertBanner, onVoirTap: _goToMapUrgents),
      HomeNearbyReports(
        reports: nearbyReports,
        onVoirTout: _goToMapProches,
        onCardTap: (_) {},
        onTakeCharge: _onTakeCharge,
        onContact: _onContact,       // ← branché
        onViewDetails: _onViewDetails,
      ),
      HomeActionBanner(data: HomeDummyData.actionBanner, onTap: () {}),
      HomeGroups(
          groups: HomeDummyData.groups,
          onVoirTout: () {},
          onCardTap: (_) {}),
      HomeCategories(
        categories: HomeDummyData.categories,
        onVoirTout: _goToMapCategories,
        onCardTap: (cat) {
          final rc = _labelToCategory(cat.label);
          if (rc != null) _goToMapCategorie(rc);
        },
      ),
      HomeRecentReports(
        reports: recentReports,
        onVoirTout: _goToMapRecents,
        onCardTap: (_) {},
        onTakeCharge: _onTakeCharge,
        onContact: _onContact,       // ← branché
        onViewDetails: _onViewDetails,
      ),
      const SizedBox(height: 100),
    ];

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              user: DummyUser.currentUser,
              greeting: 'Bonjour, $firstName',
              contextLine: contextLine,
              onSearch: (_) {},
              onNotificationTap: () {},
              onAvatarTap: () {},
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: CliinAppConstants.spacingM),
                itemCount: sections.length,
                itemBuilder: (_, i) => sections[i],
                separatorBuilder: (_, i) {
                  if (i == 0) return const SizedBox(height: CliinAppConstants.spacingM);
                  if (i == sections.length - 2) return const SizedBox.shrink();
                  return const SizedBox(height: 32);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        onSignalerTap: _openCamera,
      ),
    );
  }
}