// lib/shared/models/report_history_entry.dart

import 'package:flutter/material.dart';

enum HistoryEventType {
  signalementCree,
  prisEnCharge,
  enCoursDeTraitement,
  traite,
}

extension HistoryEventTypeExtension on HistoryEventType {
  String get label {
    switch (this) {
      case HistoryEventType.signalementCree:     return 'Signalement créé';
      case HistoryEventType.prisEnCharge:        return 'Pris en charge';
      case HistoryEventType.enCoursDeTraitement: return 'En cours de traitement';
      case HistoryEventType.traite:              return 'Traité';
    }
  }

  String get description {
    switch (this) {
      case HistoryEventType.signalementCree:     return 'Signalement publié sur la plateforme';
      case HistoryEventType.prisEnCharge:        return 'Un intervenant a accepté le cas';
      case HistoryEventType.enCoursDeTraitement: return 'En attente de preuve de résolution';
      case HistoryEventType.traite:              return 'Preuve APRÈS validée et publiée';
    }
  }

  Color get color {
    switch (this) {
      case HistoryEventType.signalementCree:     return const Color(0xFF2DB84B);
      case HistoryEventType.prisEnCharge:        return const Color(0xFFFF9800);
      case HistoryEventType.enCoursDeTraitement: return const Color(0xFF9E9E9E);
      case HistoryEventType.traite:              return const Color(0xFF2DB84B);
    }
  }

  IconData get icon {
    switch (this) {
      case HistoryEventType.signalementCree:     return Icons.flag_rounded;
      case HistoryEventType.prisEnCharge:        return Icons.person_rounded;
      case HistoryEventType.enCoursDeTraitement: return Icons.hourglass_top_rounded;
      case HistoryEventType.traite:              return Icons.check_circle_rounded;
    }
  }
}

class ReportHistoryEntry {
  final HistoryEventType type;
  final DateTime dateTime;
  final String? actorName;
  final bool isCurrentStep;

  const ReportHistoryEntry({
    required this.type,
    required this.dateTime,
    this.actorName,
    this.isCurrentStep = false,
  });
}