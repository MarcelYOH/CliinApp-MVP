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