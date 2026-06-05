// lib/features/map/models/map_filter_model.dart
// Modèles de filtres — Page Carte — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/report_category.dart';
import '../../../shared/models/report_status.dart';

export '../../../shared/models/report_category.dart' show ReportCategory;
export '../../../shared/models/report_status.dart' show ReportStatus;

// ─────────────────────────────────────────────────────────────────────────────
// 1. ÉTAT DU SIGNALEMENT
// ─────────────────────────────────────────────────────────────────────────────
// Réutilise ReportStatus de shared — source de vérité unique
// disponible / enCours / traite

// ─────────────────────────────────────────────────────────────────────────────
// 2. PRIORITÉ D'ACTION
// ─────────────────────────────────────────────────────────────────────────────
enum MapPriorityFilter { urgents, proches, recents }

extension MapPriorityFilterExt on MapPriorityFilter {
  String get label {
    switch (this) {
      case MapPriorityFilter.urgents: return 'Urgents';
      case MapPriorityFilter.proches: return 'Proches (0–2 km)';
      case MapPriorityFilter.recents: return 'Récents (–72h)';
    }
  }

  String get chipLabel {
    switch (this) {
      case MapPriorityFilter.urgents: return 'Urgents';
      case MapPriorityFilter.proches: return 'Proches';
      case MapPriorityFilter.recents: return 'Récents';
    }
  }

  IconData get icon {
    switch (this) {
      case MapPriorityFilter.urgents: return Icons.warning_amber_rounded;
      case MapPriorityFilter.proches: return Icons.location_on_rounded;
      case MapPriorityFilter.recents: return Icons.access_time_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MapPriorityFilter.urgents: return const Color(0xFFE53935);
      case MapPriorityFilter.proches: return CliinAppColors.primary;
      case MapPriorityFilter.recents: return const Color(0xFF1E88E5);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CATÉGORIES → ReportCategory (shared/models/report_category.dart)
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// 4. NIVEAU DE GRAVITÉ
// ─────────────────────────────────────────────────────────────────────────────
enum MapGravityFilter { critique, eleve, moyen, faible }

extension MapGravityFilterExt on MapGravityFilter {
  String get label {
    switch (this) {
      case MapGravityFilter.critique: return 'Critique';
      case MapGravityFilter.eleve:    return 'Élevé';
      case MapGravityFilter.moyen:    return 'Moyen';
      case MapGravityFilter.faible:   return 'Faible';
    }
  }

  IconData get icon {
    switch (this) {
      case MapGravityFilter.critique:
        return Icons.notification_important_outlined;
      case MapGravityFilter.eleve:   return Icons.warning_amber_outlined;
      case MapGravityFilter.moyen:   return Icons.error_outline;
      case MapGravityFilter.faible:  return Icons.shield_outlined;
    }
  }

  Color get color {
    switch (this) {
      case MapGravityFilter.critique: return const Color(0xFFE53935);
      case MapGravityFilter.eleve:    return const Color(0xFFFF5722);
      case MapGravityFilter.moyen:    return const Color(0xFFFF9800);
      case MapGravityFilter.faible:   return const Color(0xFF2DB84B);
    }
  }

  Color get bgColor {
    switch (this) {
      case MapGravityFilter.critique: return const Color(0xFFFFEBEE);
      case MapGravityFilter.eleve:    return const Color(0xFFFBE9E7);
      case MapGravityFilter.moyen:    return const Color(0xFFFFF3E0);
      case MapGravityFilter.faible:   return const Color(0xFFE6F7EB);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENEUR GLOBAL DES FILTRES ACTIFS
// ─────────────────────────────────────────────────────────────────────────────
class MapFilterState {
  final Set<ReportStatus> statuses;
  final Set<MapPriorityFilter> priorities;
  final Set<ReportCategory> categories;
  final Set<MapGravityFilter> gravities;

  const MapFilterState({
    this.statuses = const {},
    this.priorities = const {},
    this.categories = const {},
    this.gravities = const {},
  });

  MapFilterState copyWith({
    Set<ReportStatus>? statuses,
    Set<MapPriorityFilter>? priorities,
    Set<ReportCategory>? categories,
    Set<MapGravityFilter>? gravities,
  }) {
    return MapFilterState(
      statuses:   statuses   ?? this.statuses,
      priorities: priorities ?? this.priorities,
      categories: categories ?? this.categories,
      gravities:  gravities  ?? this.gravities,
    );
  }

  /// Nombre total de filtres actifs
  int get totalActive =>
      statuses.length + priorities.length +
      categories.length + gravities.length;

  bool get isEmpty => totalActive == 0;

  MapFilterState get empty => const MapFilterState();
}