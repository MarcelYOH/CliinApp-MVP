// lib/shared/models/report_status.dart
// Cycle de vie MÉTIER d'un signalement sur la plateforme (disponible → enCours → traite).
// ≠ ReportWorkflowStatus (features/reports/models/report_model.dart) qui décrit
//   l'état technique du flow d'upload côté client lors de la création.

import 'package:flutter/material.dart';

enum ReportStatus {
  disponible,
  enCours,
  traite,
}

extension ReportStatusExtension on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.disponible: return 'Disponible';
      case ReportStatus.enCours:    return 'En cours';
      case ReportStatus.traite:     return 'Traité';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.disponible: return const Color(0xFF2DB84B);
      case ReportStatus.enCours:    return const Color(0xFFFF9800);
      case ReportStatus.traite:     return const Color(0xFFE53935);
    }
  }

  Color get bgColor {
    switch (this) {
      case ReportStatus.disponible: return const Color(0xFFE6F7EB);
      case ReportStatus.enCours:    return const Color(0xFFFFF3E0);
      case ReportStatus.traite:     return const Color(0xFFFFEBEE);
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.disponible: return Icons.circle;
      case ReportStatus.enCours:    return Icons.access_time_rounded;
      case ReportStatus.traite:     return Icons.check_circle_rounded;
    }
  }

  Color get bannerBgColor {
    switch (this) {
      case ReportStatus.disponible: return const Color(0xFFE6F7EB);
      case ReportStatus.enCours:    return const Color(0xFFFFF3E0);
      case ReportStatus.traite:     return const Color(0xFFE6F7EB);
    }
  }

  IconData get bannerIcon {
    switch (this) {
      case ReportStatus.disponible: return Icons.info_rounded;
      case ReportStatus.enCours:    return Icons.lock_rounded;
      case ReportStatus.traite:     return Icons.check_circle_rounded;
    }
  }

  Color get bannerIconColor {
    switch (this) {
      case ReportStatus.disponible: return const Color(0xFF2DB84B);
      case ReportStatus.enCours:    return const Color(0xFFFF9800);
      case ReportStatus.traite:     return const Color(0xFF2DB84B);
    }
  }

  String get bannerText {
    switch (this) {
      case ReportStatus.disponible:
        return "Cas d'insalubrités disponibles,\ntout utilisateur peut le prendre en charge.";
      case ReportStatus.enCours:
        return "Cas d'insalubrités indisponible,\nce cas est déjà pris en charge. Merci !";
      case ReportStatus.traite:
        return "Ce problème a été résolu.\nMerci à tous les intervenants !";
    }
  }
}