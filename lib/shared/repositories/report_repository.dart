// lib/shared/repositories/report_repository.dart

import '../../features/home/models/home_report_model.dart';

abstract class ReportRepository {
  Future<List<HomeReportModel>> fetchAllReports();
  Future<HomeReportModel?> fetchReportById(String id);
  Future<HomeReportModel> addReport(HomeReportModel report);

  Future<HomeReportModel> takeCharge({
    required String reportId,
    required IntervenantModel intervenant,
    required bool whatsAppConsent,
    required String? whatsAppNumber,
    String? groupName, // nom du groupe si intervention au nom d'un groupe
  });

  Future<HomeReportModel> toggleWhatsApp({
    required String reportId,
    required bool visible,
  });

  // ── Modifier l'attribution d'une prise en charge active (En cours) ──
  // groupName == null -> "en mon nom" ; groupName renseigné -> "au nom de
  // ce groupe". Aucune autre donnée du signalement ne change.
  Future<HomeReportModel> changeAttribution({
    required String reportId,
    required String? groupName,
  });

  // ── Abandon volontaire — avant la fin du délai de 72h ────────────
  // Motif distinct de expireOverdueTakeovers() (délai dépassé) : cas
  // entièrement libéré (statut Disponible, intervenant conservé avec
  // outcome=abandonedVoluntary pour le résidu privé).
  Future<HomeReportModel> abandonTakeoverVoluntarily({
    required String reportId,
  });

  // ── Nouvelle méthode : ajouter/modifier le numéro WhatsApp ──
  Future<HomeReportModel> updateWhatsAppNumber({
    required String reportId,
    required String number,
    required bool visible,
  });

  Future<ProofVerificationResult> submitProof({
    required String reportId,
    required String imagePath,
    required double proofLatitude,
    required double proofLongitude,
    double? proofAccuracy,
  });

  Future<HomeReportModel> updateStatus({
    required String reportId,
    required ReportStatus status,
  });

  Future<HomeReportModel> updateReport(HomeReportModel report);

  Future<void> deleteReport(String reportId);

  Future<HomeReportModel> addComment({
    required String reportId,
    required ReportComment comment,
  });

  Future<HomeReportModel> editComment({
    required String reportId,
    required String commentId,
    required String newText,
  });

  Future<HomeReportModel> deleteComment({
    required String reportId,
    required String commentId,
  });

  // Fait passer en Abandonné (statut Disponible, intervenant conservé avec
  // outcome=abandoned pour le résidu privé) tout cas "en cours" dont le
  // délai de 72h sans preuve est dépassé. Simule côté client ce qu'un vrai
  // backend ferait via un job planifié — ReportStore l'appelle
  // périodiquement. Retourne les cas effectivement expirés.
  Future<List<HomeReportModel>> expireOverdueTakeovers();
}

enum ProofVerificationStatus { valid, rejectedDistance, pendingAccuracy }

class ProofVerificationResult {
  final ProofVerificationStatus status;
  final double distanceMeters;
  // Accuracy de la position de preuve quand status == pendingAccuracy —
  // permet à l'UI d'afficher la précision actuelle en attendant mieux.
  final double? accuracyMeters;
  final HomeReportModel? updatedReport;
  final String? errorMessage;

  const ProofVerificationResult({
    required this.status,
    required this.distanceMeters,
    this.accuracyMeters,
    this.updatedReport,
    this.errorMessage,
  });

  bool get isValid => status == ProofVerificationStatus.valid;
}