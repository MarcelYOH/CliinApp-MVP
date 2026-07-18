// lib/features/home/data/home_dummy_data.dart

import 'package:flutter/material.dart';
import '../models/position_model.dart';
import '../models/quick_report_model.dart';
import '../models/alert_banner_model.dart';
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

  static const List<GroupModel> groups = [
    GroupModel(
      name: 'Clean Riviera',
      location: 'Riviera 2, Cocody',
      description:
          'Nettoyage hebdomadaire des rues et sensibilisation au tri sélectif dans le quartier.',
      membersCount: 23,
      actionsCount: 12,
      bannerAsset: 'assets/images/group_banner1.jpg',
      logoText: 'Clean\nRiviera',
      isActive: true,
      levelBadges: ['Officiel', 'Engagé', 'Impact'],
      leaderAvatarAssets: [
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
      ],
    ),
    GroupModel(
      name: 'Green City',
      location: 'Plateau, Abidjan',
      description:
          'Collectif pour un cadre de vie plus vert : reboisement urbain et compostage communautaire.',
      membersCount: 18,
      actionsCount: 9,
      bannerAsset: 'assets/images/group_banner2.jpg',
      hasLeafIcon: true,
      isActive: true,
      levelBadges: ['Impact', 'Engagé', 'Officiel'],
      leaderAvatarAssets: [
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
      ],
    ),
    GroupModel(
      name: 'Eco Jeunes',
      location: 'Yopougon, Abidjan',
      description:
          'Mobilisation des jeunes autour des enjeux environnementaux locaux, ateliers et actions terrain.',
      membersCount: 31,
      actionsCount: 15,
      bannerAsset: 'assets/images/group_banner3.jpg',
      logoText: 'ECO',
      isActive: true,
      levelBadges: ['Engagé', 'Impact', 'Officiel'],
      leaderAvatarAssets: [
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
        'assets/images/profile.jpg',
      ],
    ),
  ];

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
}