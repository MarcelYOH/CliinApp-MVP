// lib/shared/models/content_report_model.dart
// Signalement d'un contenu publié (action terrain, et futurs autres types)
// par un utilisateur — collecte MVP simple (Correction 12), pas de système
// de modération/traitement à ce stade, juste une structure consultable
// plus tard.

class ContentReportModel {
  final String id;
  final String actionId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;

  const ContentReportModel({
    required this.id,
    required this.actionId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
  });
}
