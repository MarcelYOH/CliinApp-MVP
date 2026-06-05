// lib/shared/models/report_category.dart
// Catégories officielles MVP — centralisées et réutilisables — CliinApp

import 'package:flutter/material.dart';

enum ReportCategory {
  depotsSauvages,
  caniveauxBouches,
  eauxStagnantes,
  bacDechetsSature,
  conteneurSature,
  zoneInsalubre,
  dechetsIndustriels,
  dechetsMedicaux,
  brulageDesDechets,
}

extension ReportCategoryExt on ReportCategory {
  String get label {
    switch (this) {
      case ReportCategory.depotsSauvages:      return 'Dépôts sauvages';
      case ReportCategory.caniveauxBouches:    return 'Caniveaux bouchés';
      case ReportCategory.eauxStagnantes:      return 'Eaux stagnantes';
      case ReportCategory.bacDechetsSature:    return 'Bac à déchets saturé';
      case ReportCategory.conteneurSature:     return 'Conteneur saturé';
      case ReportCategory.zoneInsalubre:       return 'Zone insalubre';
      case ReportCategory.dechetsIndustriels:  return 'Déchets industriels';
      case ReportCategory.dechetsMedicaux:     return 'Déchets médicaux';
      case ReportCategory.brulageDesDechets:   return 'Brûlage des déchets';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.depotsSauvages:      return Icons.delete_sweep_outlined;
      case ReportCategory.caniveauxBouches:    return Icons.water_damage_outlined;
      case ReportCategory.eauxStagnantes:      return Icons.water_outlined;
      case ReportCategory.bacDechetsSature:    return Icons.delete_outline_rounded;
      case ReportCategory.conteneurSature:     return Icons.inventory_2_outlined;
      case ReportCategory.zoneInsalubre:       return Icons.warning_amber_outlined;
      case ReportCategory.dechetsIndustriels:  return Icons.factory_outlined;
      case ReportCategory.dechetsMedicaux:     return Icons.medical_services_outlined;
      case ReportCategory.brulageDesDechets:   return Icons.local_fire_department_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ReportCategory.depotsSauvages:      return const Color(0xFFFF9800);
      case ReportCategory.caniveauxBouches:    return const Color(0xFF1E88E5);
      case ReportCategory.eauxStagnantes:      return const Color(0xFF00ACC1);
      case ReportCategory.bacDechetsSature:    return const Color(0xFF4CAF50);
      case ReportCategory.conteneurSature:     return const Color(0xFF8D6E63);
      case ReportCategory.zoneInsalubre:       return const Color(0xFFE53935);
      case ReportCategory.dechetsIndustriels:  return const Color(0xFF546E7A);
      case ReportCategory.dechetsMedicaux:     return const Color(0xFF9C27B0);
      case ReportCategory.brulageDesDechets:   return const Color(0xFFFF5722);
    }
  }

  String get imageAsset {
    switch (this) {
      case ReportCategory.caniveauxBouches:
      case ReportCategory.eauxStagnantes:
        return 'assets/images/caniveau.jpg';
      default:
        return 'assets/images/depot.jpg';
    }
  }
}