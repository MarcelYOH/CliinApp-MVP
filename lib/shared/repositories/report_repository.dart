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
  });

  Future<HomeReportModel> updateStatus({
    required String reportId,
    required ReportStatus status,
  });
}

class ProofVerificationResult {
  final bool isValid;
  final double distanceMeters;
  final HomeReportModel? updatedReport;
  final String? errorMessage;

  const ProofVerificationResult({
    required this.isValid,
    required this.distanceMeters,
    this.updatedReport,
    this.errorMessage,
  });
}