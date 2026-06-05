// lib/shared/repositories/report_repository.dart
// Contrat abstrait — implémenté par MockReportRepository (MVP)
// et FirebaseReportRepository (backend)

import '../../features/home/models/report_model.dart';

abstract class ReportRepository {
  // ── Lecture ───────────────────────────────────────────────────
  Future<List<HomeReportModel>> fetchAllReports();
  Future<HomeReportModel?> fetchReportById(String id);

  // ── Signalement ───────────────────────────────────────────────
  Future<HomeReportModel> addReport(HomeReportModel report);

  // ── Prise en charge ───────────────────────────────────────────
  Future<HomeReportModel> takeCharge({
    required String reportId,
    required IntervenantModel intervenant,
    required bool whatsAppConsent,
    required String? whatsAppNumber,
  });

  // ── Toggle WhatsApp ───────────────────────────────────────────
  Future<HomeReportModel> toggleWhatsApp({
    required String reportId,
    required bool visible,
  });

  // ── Preuve d'intervention ─────────────────────────────────────
  Future<ProofVerificationResult> submitProof({
    required String reportId,
    required String imagePath,
    required double proofLatitude,
    required double proofLongitude,
  });

  // ── Statut ────────────────────────────────────────────────────
  Future<HomeReportModel> updateStatus({
    required String reportId,
    required ReportStatus status,
  });
}

// ── Résultat de vérification de preuve ───────────────────────────
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