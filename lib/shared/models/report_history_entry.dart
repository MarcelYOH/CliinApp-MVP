// lib/shared/models/report_history_entry.dart

import 'package:flutter/material.dart';

enum HistoryEventType {
  signalementCree,
  prisEnCharge,
  enCoursDeTraitement,
  traite,
  abandonne,
  rejete,
}

extension HistoryEventTypeExtension on HistoryEventType {
  String get label {
    switch (this) {
      case HistoryEventType.signalementCree:     return 'Signalement créé';
      case HistoryEventType.prisEnCharge:        return 'Pris en charge';
      case HistoryEventType.enCoursDeTraitement: return 'En cours de traitement';
      case HistoryEventType.traite:              return 'Preuve validée — Traité';
      case HistoryEventType.abandonne:           return 'Délai expiré — Abandonné';
      case HistoryEventType.rejete:              return 'Preuve refusée — Rejeté';
    }
  }

  String get description {
    switch (this) {
      case HistoryEventType.signalementCree:     return 'Signalement publié sur la plateforme';
      case HistoryEventType.prisEnCharge:        return 'Un intervenant a accepté le cas';
      case HistoryEventType.enCoursDeTraitement: return 'En attente de preuve de résolution';
      case HistoryEventType.traite:              return 'Preuve APRÈS validée et publiée';
      case HistoryEventType.abandonne:           return 'Aucune preuve soumise dans le délai imparti';
      case HistoryEventType.rejete:               return 'La position GPS de la preuve ne correspondait pas';
    }
  }

  Color get color {
    switch (this) {
      case HistoryEventType.signalementCree:     return const Color(0xFF2DB84B);
      case HistoryEventType.prisEnCharge:        return const Color(0xFFFF9800);
      case HistoryEventType.enCoursDeTraitement: return const Color(0xFF9E9E9E);
      case HistoryEventType.traite:              return const Color(0xFFE53935);
      case HistoryEventType.abandonne:           return const Color(0xFF6B7280);
      case HistoryEventType.rejete:              return const Color(0xFF8E24AA);
    }
  }

  IconData get icon {
    switch (this) {
      case HistoryEventType.signalementCree:     return Icons.flag_rounded;
      case HistoryEventType.prisEnCharge:        return Icons.person_rounded;
      case HistoryEventType.enCoursDeTraitement: return Icons.hourglass_top_rounded;
      case HistoryEventType.traite:              return Icons.check_circle_rounded;
      case HistoryEventType.abandonne:           return Icons.cancel_rounded;
      case HistoryEventType.rejete:              return Icons.error_rounded;
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