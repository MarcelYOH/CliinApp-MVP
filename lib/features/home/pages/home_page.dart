// lib/features/home/pages/home_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../auth/pages/auth_gate_sheet.dart';
import '../widgets/home_quick_report.dart';
import '../widgets/home_alert_banner.dart';
import '../widgets/home_nearby_reports.dart';
import '../widgets/home_action_banner.dart';
import '../widgets/home_groups.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_recent_reports.dart';
import '../models/category_model.dart';
import '../data/home_dummy_data.dart';
import '../models/home_report_model.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../reports/pages/report_detail_page.dart';
import '../../reports/pages/intervenant_detail_page.dart';
import '../../reports/widgets/take_charge_flow.dart';
import '../../map/pages/map_page.dart';
import '../../map/models/map_filter_model.dart';
import '../../auth/auth_guard.dart';
import '../../profile/pages/profile_page.dart';

// Salutation selon l'heure du téléphone :
// 00h-11h59 -> Bonjour · 12h-17h59 -> Bon après-midi · 18h-23h59 -> Bonsoir
String _greetingByHour() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bonjour';
  if (hour < 18) return 'Bon après-midi';
  return 'Bonsoir';
}

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
    pendingHomeTabIndex.addListener(_onPendingTabIndex);
    // init() est déjà appelé dans main() avant runApp() — ne pas rappeler ici
  }

  @override
  void dispose() {
    ReportStore.instance.removeListener(_onStoreUpdate);
    pendingHomeTabIndex.removeListener(_onPendingTabIndex);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  // HomePage n'est jamais reconstruite lors d'un popUntil (voir
  // tab_navigation.dart) — son State persiste depuis le tout premier
  // affichage, donc _currentNavIndex ne peut refléter un onglet choisi
  // depuis une page enfant (Profil, détail d'un cas, ...) qu'en écoutant
  // ce canal explicite.
  void _onPendingTabIndex() {
    final target = pendingHomeTabIndex.value;
    if (target == null || !mounted) return;
    setState(() => _currentNavIndex = target);
    pendingHomeTabIndex.value = null;
  }

  void _openCamera() async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      Navigator.push(
        context,
        fastFadeRoute<void>(const ReportCameraPage()),
      );
    }
  }

  void _onNavTap(int index) {
    if (index == 1) {
      _goToMap();
      return;
    }
    // "Plus" n'ouvre plus le Profil — uniquement le menu des modules à
    // venir. Le Profil reste accessible uniquement via l'avatar du header.
    if (index == 4) {
      navigateToTab(context, currentIndex: 0, targetIndex: 4);
      return;
    }
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

  void _goToMapUrgents() => _goToMap(priorities: {MapPriorityFilter.urgents});
  void _goToMapProches() => _goToMap(priorities: {MapPriorityFilter.proches});
  void _goToMapRecents() => _goToMap(priorities: {MapPriorityFilter.recents});
  void _goToMapCategorie(ReportCategory cat) => _goToMap(categories: {cat});
  void _goToMapCategories() => _goToMap();

  ReportCategory? _labelToCategory(String label) {
    const map = {
      'Bac/Poubelle saturée': ReportCategory.bacPoubelleSature,
      'Dépôts sauvages': ReportCategory.depotsSauvages,
      'Caniveaux bouchés': ReportCategory.caniveauxBouches,
      'Eaux usées': ReportCategory.eauxUsees,
      'Conteneur saturé': ReportCategory.conteneurSature,
      'Zone insalubre': ReportCategory.zoneInsalubre,
      'Brûlage des déchets': ReportCategory.brulageDesDechets,
      'Déchets industriels': ReportCategory.dechetsIndustriels,
      'Déchets médicaux': ReportCategory.dechetsMedicaux,
    };
    return map[label];
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
  // Déclenché uniquement si intervenant.isContactable = true
  // (whatsAppVisible = true ET whatsAppNumber != null)
  void _onContact(HomeReportModel report) {
    openWhatsApp(context: context, intervenant: report.intervenant);
  }

  Widget _buildInitialsWidget(String username) {
    final parts = username.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (username.isEmpty ? '?' : username[0].toUpperCase());
    return Container(
      color: CliinAppColors.primaryLight,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: CliinAppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStore.instance;

    // Zéro donnée de repli : uniquement les vrais cas disponibles du
    // ReportStore, jamais de carte inventée.
    final nearbyReports = store.nearbyReports;
    final recentReports = store.recentReports;

    // Compteurs par catégorie — calculés dynamiquement depuis ReportStore
    // (tous statuts confondus), jamais lus depuis HomeDummyData qui ne
    // fournit plus que l'icône/libellé/couleur de chaque catégorie.
    final categoriesWithCounts = HomeDummyData.categories.map((c) {
      final rc = _labelToCategory(c.label);
      return CategoryModel(
        icon: c.icon,
        label: c.label,
        count: rc != null ? store.categoryCount(rc) : 0,
        color: c.color,
      );
    }).toList();

    final sections = <Widget>[
      HomeQuickReport(data: HomeDummyData.quickReport, onTap: _openCamera),
      HomeAlertBanner(
        data: HomeDummyData.alertBanner,
        onVoirTap: _goToMapUrgents,
      ),
      HomeNearbyReports(
        reports: nearbyReports,
        onVoirTout: _goToMapProches,
        onCardTap: _onCardTap,
        onTakeCharge: _onTakeCharge,
        onContact: _onContact,
      ),
      HomeActionBanner(data: HomeDummyData.actionBanner, onTap: () {}),
      HomeGroups(
        groups: HomeDummyData.groups,
        onVoirTout: () {},
        onCardTap: (_) {},
      ),
      HomeCategories(
        categories: categoriesWithCounts,
        onVoirTout: _goToMapCategories,
        onCardTap: (cat) {
          final rc = _labelToCategory(cat.label);
          if (rc != null) _goToMapCategorie(rc);
        },
      ),
      HomeRecentReports(
        reports: recentReports,
        onVoirTout: _goToMapRecents,
        onCardTap: _onCardTap,
        onTakeCharge: _onTakeCharge,
        onContact: _onContact,
      ),
    ];

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            ListenableBuilder(
              listenable: AuthStore.instance,
              builder: (ctx, _) {
                final authUser = AuthStore.instance.currentUser;
                final isAuthed = AuthStore.instance.isAuthenticated;

                final greeting = isAuthed
                    ? '${_greetingByHour()}, ${authUser!.username.split(' ').first}'
                    : 'Bienvenue !';
                final locationLabel = (isAuthed && authUser!.zone.isNotEmpty)
                    ? authUser.zone
                    : 'Votre position';
                // Compteur indépendant des 2 cartes affichées — tous
                // statuts confondus dans le rayon de 2km.
                final contextLine =
                    '$locationLabel · ${store.nearbyAllStatusesCount} cas à proximité';

                Widget avatarContent;
                if (!isAuthed) {
                  avatarContent = Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  );
                } else if (authUser!.avatarPath != null &&
                    authUser.avatarPath!.isNotEmpty) {
                  avatarContent = Image.file(
                    File(authUser.avatarPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildInitialsWidget(authUser.username),
                  );
                } else {
                  avatarContent = _buildInitialsWidget(authUser.username);
                }

                return AppHeader(
                  user: const UserModel(
                    id: 'guest',
                    name: '',
                    avatarUrl: '',
                    notificationCount: 0,
                  ),
                  greeting: greeting,
                  contextLine: contextLine,
                  avatarOverride: avatarContent,
                  onSearch: (_) {},
                  onNotificationTap: () {},
                  onAvatarTap: isAuthed
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        )
                      : () => showAuthGateSheet(context),
                );
              },
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  0,
                  CliinAppConstants.spacingM,
                  0,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                itemCount: sections.length,
                itemBuilder: (_, i) => sections[i],
                separatorBuilder: (_, i) => i == 0
                    ? const SizedBox(height: CliinAppConstants.spacingM)
                    : const SizedBox(height: 32),
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
