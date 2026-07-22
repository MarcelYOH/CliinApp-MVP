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
import '../../../shared/store/group_store.dart';
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
import '../../groups/models/group_model.dart';
import '../data/home_dummy_data.dart';
import '../models/home_report_model.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../reports/pages/report_detail_page.dart';
import '../../reports/pages/intervenant_detail_page.dart';
import '../../reports/widgets/take_charge_flow.dart';
import '../../map/pages/map_page.dart';
import '../../map/models/map_filter_model.dart';
import '../../groups/pages/groups_page.dart';
import '../../groups/pages/group_search_page.dart';
import '../../groups/data/groups_dummy_data.dart';
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
    GroupStore.instance.addListener(_onStoreUpdate);
    pendingHomeTabIndex.addListener(_onPendingTabIndex);
    // init() est déjà appelé dans main() avant runApp() — ne pas rappeler ici
  }

  @override
  void dispose() {
    ReportStore.instance.removeListener(_onStoreUpdate);
    GroupStore.instance.removeListener(_onStoreUpdate);
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
    if (index == 3) {
      _goToGroups();
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

  void _goToGroups() {
    Navigator.push(context, fastFadeRoute<void>(const GroupsPage()));
  }

  // "Voir tout" de la section "Groupes actifs" de l'accueil : mène
  // DIRECTEMENT à la page dédiée, sans passer par l'accueil du module
  // Groupes (règle de navigation de la correction 1.1).
  void _goToGroupesActifs() {
    Navigator.push(
      context,
      fastFadeRoute<void>(const GroupSearchPage(origine: 'actifs')),
    );
  }

  // Section "Groupes actifs" de l'accueil : priorité systématique aux
  // vrais groupes à 3 badges simultanément (GroupStore) ; cartes factices
  // "accroche" (GroupsDummyData) uniquement tant qu'aucun n'existe encore
  // — jamais les deux mélangés (correction 3).
  List<GroupModel> _groupsActifsVitrine() {
    final real = GroupStore.instance.getGroupsActifsVitrine();
    return real.isEmpty ? GroupsDummyData.forSection('actifs') : real;
  }

  void _goToMap({
    Set<MapPriorityFilter>? priorities,
    Set<ReportCategory>? categories,
    String searchQuery = '',
  }) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) => MapPage(
          initialPriorityFilters: priorities ?? const {},
          initialCategoryFilters: categories ?? const {},
          initialSearchQuery: searchQuery,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  // Barre de recherche du header — périmètre TOUS les cas publics de la
  // plateforme (pas seulement ceux de l'utilisateur) : navigue vers la
  // Carte avec la recherche déjà appliquée, cohérent avec les autres points
  // d'entrée qui y renvoient (_goToMapUrgents, etc.).
  void _onHomeSearch(String query) {
    if (query.trim().isEmpty) return;
    _goToMap(searchQuery: query.trim());
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

  // ── Cartes factices "accroche" — message explicatif au tap, jamais de
  // navigation vers un faux détail ni d'action réelle (prise en charge,
  // contact) sur du contenu qui n'existe pas dans ReportStore ───────────
  void _showFakeReportNotice() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
        'Ceci est un exemple. Soyez le premier à signaler un cas réel dans '
        'votre zone !',
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
    ));
  }

  void _onCardTap(HomeReportModel report) {
    if (HomeDummyData.isFakeReport(report)) {
      _showFakeReportNotice();
      return;
    }
    Navigator.push(
      context,
      fastFadeRoute<void>(ReportDetailPage(data: report)),
    );
  }

  void _onTakeCharge(HomeReportModel report) async {
    if (HomeDummyData.isFakeReport(report)) {
      _showFakeReportNotice();
      return;
    }
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
    if (HomeDummyData.isFakeReport(report)) {
      _showFakeReportNotice();
      return;
    }
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

    // Priorité systématique aux vrais signalements du ReportStore — les
    // cartes factices ne servent que d'accroche tant qu'aucun vrai contenu
    // équivalent n'existe, et s'effacent individuellement dès qu'un vrai
    // cas remplit les mêmes critères (statut Disponible, rayon 2km pour "À
    // proximité" ; statut Disponible le plus récent pour "Cas récents").
    // 1 seul vrai résultat -> occupe toute la largeur (jamais accompagné
    // d'une carte factice) ; 0 -> les 2/1 cartes factices habituelles.
    final realNearbyReports = store.nearbyReports;
    final nearbyReports = realNearbyReports.isEmpty
        ? HomeDummyData.fakeNearbyReports
        : realNearbyReports;
    final realRecentReports = store.recentReports;
    final recentReports = realRecentReports.isEmpty
        ? HomeDummyData.fakeRecentReports
        : realRecentReports;

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
        groups: _groupsActifsVitrine(),
        onVoirTout: _goToGroupesActifs,
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
                    '$locationLabel · ${store.nearbyDisponibleCount} cas à proximité';

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
                  onSearch: _onHomeSearch,
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
