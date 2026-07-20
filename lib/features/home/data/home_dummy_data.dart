// lib/features/home/data/home_dummy_data.dart

import 'package:flutter/material.dart';
import '../models/position_model.dart';
import '../models/quick_report_model.dart';
import '../models/alert_banner_model.dart';
import '../models/action_banner_model.dart';
import '../models/category_model.dart';
import '../models/home_report_model.dart';

class HomeDummyData {
  HomeDummyData._();

  static const PositionModel position = PositionModel(
    label: 'Ma position',
    value: 'Cocody, Angré',
    radiusLabel: 'Autour de moi',
    radiusKm: 2,
  );

  static const QuickReportModel quickReport = QuickReportModel(
    title: 'Un problème de salubrité ?\nprès de vous',
    description: 'Signalez-le rapidement\net améliorez votre communauté.',
    buttonLabel: 'Signaler',
  );

  static const AlertBannerModel alertBanner = AlertBannerModel(
    badgeLabel: 'ALERTE',
    textLine1: 'Zones critiques nécessitant',
    textLine2Prefix: 'une ',
    textLine2Highlight: 'intervention urgente.',
    buttonLabel: 'Voir',
  );

  static const ActionBannerModel actionBanner = ActionBannerModel(
    badgeLabel: 'Agissons ensemble',
    title: 'Rejoignez une\naction citoyenne',
    description:
        'Participer aux campagnes de nettoyage, de sensibilisation et autres actions citoyennes durables.',
    buttonLabel: 'Voir les actions',
    imageAsset: 'assets/images/action.jpg',
  );

  // Métadonnées d'affichage UNIQUEMENT (icône, libellé, couleur) — le
  // compteur réel de chaque catégorie est calculé dynamiquement depuis
  // ReportStore.categoryCount() dans home_page.dart, jamais lu d'ici.
  // `count: 0` ci-dessous n'est qu'un placeholder de construction du
  // CategoryModel, toujours écrasé avant affichage.
  static const List<CategoryModel> categories = [
    CategoryModel(icon: Icons.delete_outline_rounded,
        label: 'Bac/Poubelle saturée', count: 0, color: Color(0xFF4CAF50)),
    CategoryModel(icon: Icons.delete_sweep_outlined,
        label: 'Dépôts sauvages', count: 0, color: Color(0xFFFF9800)),
    CategoryModel(icon: Icons.water_damage_outlined,
        label: 'Caniveaux bouchés', count: 0, color: Color(0xFF1E88E5)),
    CategoryModel(icon: Icons.water_outlined,
        label: 'Eaux usées', count: 0, color: Color(0xFF00ACC1)),
    CategoryModel(icon: Icons.inventory_2_outlined,
        label: 'Conteneur saturé', count: 0, color: Color(0xFF8D6E63)),
    CategoryModel(icon: Icons.warning_amber_outlined,
        label: 'Zone insalubre', count: 0, color: Color(0xFFE53935)),
    CategoryModel(icon: Icons.local_fire_department_outlined,
        label: 'Brûlage des déchets', count: 0, color: Color(0xFFFF5722)),
    CategoryModel(icon: Icons.factory_outlined,
        label: 'Déchets industriels', count: 0, color: Color(0xFF546E7A)),
    CategoryModel(icon: Icons.medical_services_outlined,
        label: 'Déchets médicaux', count: 0, color: Color(0xFF9C27B0)),
  ];

  // ── Cartes factices "accroche" — accueil ──────────────────────────
  // Rôle : donner un aperçu vivant de l'application à un nouvel utilisateur
  // dans une zone encore vide de vrais signalements. Chaque carte s'efface
  // INDIVIDUELLEMENT dès qu'un vrai signalement équivalent existe (voir
  // home_page.dart) — jamais ajoutées à côté de vraies données, seulement
  // à défaut. Identifiables sans ambiguïté via leur id 'demo_*' : jamais
  // interactives (prise en charge / contact désactivés), tap = message
  // explicatif plutôt qu'une navigation vers un faux détail.
  // Coordonnées : ville pilote San-Pedro (cf. pubspec).
  static List<HomeReportModel> get fakeNearbyReports => [
        HomeReportModel(
          id: 'demo_nearby_1',
          reference: '#CLN-DEMO',
          title: 'Dépôt sauvage de déchets',
          location: 'Quartier Bardot, San-Pedro',
          description:
              'Amas de déchets ménagers abandonnés sur le trottoir, attire '
              'les nuisibles.',
          severity: ReportSeverity.eleve,
          category: ReportCategory.depotsSauvages,
          imageAsset: ReportCategory.depotsSauvages.imageAsset,
          distance: '—',
          latitude: 4.7485,
          longitude: -6.6363,
          timeAgo: 'Il y a 2h',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: ReportStatus.disponible,
          views: 24,
          comments: 3,
          shares: 1,
        ),
        HomeReportModel(
          id: 'demo_nearby_2',
          reference: '#CLN-DEMO',
          title: 'Caniveau bouché et débordant',
          location: 'Zone Lac, San-Pedro',
          description:
              'Eaux stagnantes bloquées par des déchets, risque sanitaire '
              'pour le voisinage.',
          severity: ReportSeverity.critique,
          category: ReportCategory.caniveauxBouches,
          imageAsset: ReportCategory.caniveauxBouches.imageAsset,
          distance: '—',
          latitude: 4.7510,
          longitude: -6.6400,
          timeAgo: 'Il y a 5h',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: ReportStatus.disponible,
          views: 41,
          comments: 6,
          shares: 2,
        ),
      ];

  static List<HomeReportModel> get fakeRecentReports => [
        HomeReportModel(
          id: 'demo_recent_1',
          reference: '#CLN-DEMO',
          title: 'Poubelle collective saturée',
          location: 'Cité, San-Pedro',
          description:
              'Bac de collecte plein depuis plusieurs jours, déchets qui '
              'débordent au sol.',
          severity: ReportSeverity.moyen,
          category: ReportCategory.bacPoubelleSature,
          imageAsset: ReportCategory.bacPoubelleSature.imageAsset,
          distance: '—',
          latitude: 4.7450,
          longitude: -6.6320,
          timeAgo: 'Il y a 8h',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          status: ReportStatus.disponible,
          views: 18,
          comments: 2,
          shares: 0,
        ),
      ];

  // Préfixe distinctif — utilisé partout où une carte factice doit être
  // traitée différemment d'un vrai signalement (pas de navigation, pas de
  // prise en charge/contact réels).
  static bool isFakeReport(HomeReportModel r) => r.id.startsWith('demo_');
}