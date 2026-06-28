// lib/shared/models/report_origin.dart
// Provenance d'un signalement — centralisée et réutilisable — CliinApp

import 'package:flutter/material.dart';

enum ReportOrigin {
  domicile,
  commerce,
  espacePublic,
  etablissementScolaire,
  industrie,
  etablissementSante,
}

extension ReportOriginExt on ReportOrigin {
  String get label {
    switch (this) {
      case ReportOrigin.domicile:              return 'Domicile / Ménage';
      case ReportOrigin.commerce:              return 'Commerce';
      case ReportOrigin.espacePublic:          return 'Espace public';
      case ReportOrigin.etablissementScolaire: return 'Établissement scolaire';
      case ReportOrigin.industrie:             return 'Industrie';
      case ReportOrigin.etablissementSante:    return 'Établissement de santé';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportOrigin.domicile:              return Icons.home_outlined;
      case ReportOrigin.commerce:              return Icons.store_outlined;
      case ReportOrigin.espacePublic:          return Icons.park_outlined;
      case ReportOrigin.etablissementScolaire: return Icons.school_outlined;
      case ReportOrigin.industrie:             return Icons.factory_outlined;
      case ReportOrigin.etablissementSante:    return Icons.local_hospital_outlined;
    }
  }
}
