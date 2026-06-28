// lib/features/home/data/home_dummy_data.dart

import 'package:flutter/material.dart';
import '../models/position_model.dart';
import '../models/quick_report_model.dart';
import '../models/alert_banner_model.dart';
import '../models/home_report_model.dart';
import '../models/action_banner_model.dart';
import '../models/group_model.dart';
import '../models/category_model.dart';

class HomeDummyData {
  HomeDummyData._();

  static const PositionModel position = PositionModel(
    label: 'Ma position',
    value: 'Cocody, Angré',
    radiusLabel: 'Autour de moi',
    radiusKm: 2,
  );

  static const QuickReportModel quickReport = QuickReportModel(
    title: 'Un problème de salubrité\nprès de vous ?',
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

  static final List<HomeReportModel> nearbyReports = [
    // ── État 1 : Disponible ──
    const HomeReportModel(
      id: 'CLN-2481',
      reference: '#CLN-2481',
      title: 'Dépôts sauvages',
      location: 'Riviera Palmeraie, Cocody',
      description: 'Accumulation importante d\'ordures ménagères depuis 3 jours.',
      severity: ReportSeverity.critique,
      category: ReportCategory.depotsSauvages,
      distance: '250 m',
      timeAgo: 'Il y a 3j',
      imageAsset: 'assets/images/depot.jpg',
      status: ReportStatus.disponible,
      views: 23,
      comments: 5,
      shares: 12,
    ),

    // ── État 2 : En cours ──
    HomeReportModel(
      id: 'CLN-2810',
      reference: '#CLN-2810',
      title: 'Caniveaux bouchés',
      location: 'Cocody, Angré 8e tranche',
      description: 'Eaux stagnantes, odeurs nauséabondes et risque sanitaire élevé.',
      severity: ReportSeverity.eleve,
      category: ReportCategory.caniveauxBouches,
      distance: '400 m',
      timeAgo: 'Il y a 1j',
      imageAsset: 'assets/images/caniveau.jpg',
      status: ReportStatus.enCours,
      intervenant: IntervenantModel(
        id: 'eco-jeune',
        name: 'Eco Jeune',
        takenAgo: 'Il y a 2h',
        takenAt: DateTime(2025, 5, 15, 10, 30),
      ),
      views: 18,
      comments: 3,
      shares: 7,
    ),

    // ── État 3 : Traité ──
    HomeReportModel(
      id: 'CLN-3102',
      reference: '#CLN-3102',
      title: 'Eaux usées',
      location: 'Abobo, PK18',
      description: 'Risque sanitaire élevé pour les habitants du quartier.',
      severity: ReportSeverity.eleve,
      category: ReportCategory.eauxUsees,
      distance: '650 m',
      timeAgo: 'Il y a 2j',
      imageAsset: 'assets/images/depot.jpg',
      imageAfterAsset: 'assets/images/caniveau.jpg',
      status: ReportStatus.traite,
      intervenant: IntervenantModel(
        id: 'clean-riviera',
        name: 'Clean Riviera',
        takenAt: DateTime(2025, 5, 15, 10, 30),
        treatedAt: DateTime(2025, 5, 15, 14, 45), // ✅ date renseignée
      ),
      views: 15,
      comments: 2,
      shares: 6,
    ),
  ];

  static const ActionBannerModel actionBanner = ActionBannerModel(
    badgeLabel: 'Agissons ensemble',
    title: 'Rejoignez une\naction citoyenne',
    description:
        'Participez aux campagnes de nettoyage et aux actions communautaires près de chez vous.',
    buttonLabel: 'Voir les actions',
    imageAsset: 'assets/images/action.jpg',
  );

  static const List<GroupModel> groups = [
    GroupModel(
      name: 'Clean Riviera',
      location: 'Riviera 2, Cocody',
      membersCount: 23,
      actionsCount: 12,
      bannerAsset: 'assets/images/group_banner1.jpg',
      logoText: 'Clean\nRiviera',
      isActive: true,
    ),
    GroupModel(
      name: 'Green City',
      location: 'Plateau, Abidjan',
      membersCount: 18,
      actionsCount: 9,
      bannerAsset: 'assets/images/group_banner2.jpg',
      hasLeafIcon: true,
      isActive: true,
    ),
    GroupModel(
      name: 'Eco Jeunes',
      location: 'Yopougon, Abidjan',
      membersCount: 31,
      actionsCount: 15,
      bannerAsset: 'assets/images/group_banner3.jpg',
      logoText: 'ECO',
      isActive: true,
    ),
  ];

  static const List<CategoryModel> categories = [
    CategoryModel(icon: Icons.delete_outline_rounded,
        label: 'Bac/Poubelle saturée', count: 48, color: Color(0xFF4CAF50)),
    CategoryModel(icon: Icons.delete_sweep_outlined,
        label: 'Dépôts sauvages', count: 96, color: Color(0xFFFF9800)),
    CategoryModel(icon: Icons.water_damage_outlined,
        label: 'Caniveaux bouchés', count: 74, color: Color(0xFF1E88E5)),
    CategoryModel(icon: Icons.water_outlined,
        label: 'Eaux usées', count: 62, color: Color(0xFF00ACC1)),
    CategoryModel(icon: Icons.inventory_2_outlined,
        label: 'Conteneur saturé', count: 35, color: Color(0xFF8D6E63)),
    CategoryModel(icon: Icons.warning_amber_outlined,
        label: 'Zone insalubre', count: 41, color: Color(0xFFE53935)),
    CategoryModel(icon: Icons.local_fire_department_outlined,
        label: 'Brûlage des déchets', count: 22, color: Color(0xFFFF5722)),
    CategoryModel(icon: Icons.factory_outlined,
        label: 'Déchets industriels', count: 18, color: Color(0xFF546E7A)),
    CategoryModel(icon: Icons.medical_services_outlined,
        label: 'Déchets médicaux', count: 12, color: Color(0xFF9C27B0)),
  ];

  static final List<HomeReportModel> recentReports = [
    const HomeReportModel(
      id: 'CLN-9021',
      reference: '#CLN-9021',
      title: 'Dépôts sauvages',
      location: 'Yopougon, Sicogi',
      description: 'Accumulation importante d\'ordures ménagères non collectées.',
      severity: ReportSeverity.critique,
      category: ReportCategory.depotsSauvages,
      distance: '250 m',
      timeAgo: 'Il y a 45 min',
      imageAsset: 'assets/images/depot.jpg',
      status: ReportStatus.disponible,
      views: 7,
      comments: 1,
      shares: 2,
    ),
    HomeReportModel(
      id: 'CLN-3657',
      reference: '#CLN-3657',
      title: 'Eaux usées',
      location: 'Cocody, Riviera Faya',
      description: 'Eaux usées, odeurs nauséabondes et moustiques.',
      severity: ReportSeverity.eleve,
      category: ReportCategory.eauxUsees,
      distance: '400 m',
      timeAgo: 'Il y a 1h',
      imageAsset: 'assets/images/caniveau.jpg',
      status: ReportStatus.enCours,
      intervenant: IntervenantModel(
        id: 'green-city',
        name: 'Green City',
        takenAgo: 'Il y a 30 min',
        takenAt: DateTime(2025, 5, 15, 13, 00),
      ),
      views: 5,
      comments: 0,
      shares: 1,
    ),
  ];
}