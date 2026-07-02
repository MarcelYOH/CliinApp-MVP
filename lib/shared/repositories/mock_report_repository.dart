// lib/shared/repositories/mock_report_repository.dart

import 'dart:math';
import '../../features/home/models/home_report_model.dart';
import '../../features/home/data/home_dummy_data.dart';
import '../../features/map/data/map_dummy_data.dart';
import 'report_repository.dart';

class MockReportRepository implements ReportRepository {
  MockReportRepository._();
  static final MockReportRepository instance = MockReportRepository._();

  final List<HomeReportModel> _reports = List.of([
    ...HomeDummyData.nearbyReports,
    ...HomeDummyData.recentReports,
    ...MapDummyData.reports,
  ]);

  List<HomeReportModel> get _uniqueReports {
    final seen = <String>{};
    return _reports.where((r) => seen.add(r.id)).toList();
  }

  String _generateCode() {
    final n = 1000 + Random().nextInt(8999);
    return '#CLN-$n';
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  void _updateReport(HomeReportModel updated) {
    final index = _reports.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reports[index] = updated;
    } else {
      _reports.add(updated);
    }
  }

  @override
  Future<List<HomeReportModel>> fetchAllReports() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.of(_uniqueReports);
  }

  @override
  Future<HomeReportModel?> fetchReportById(String id) async {
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HomeReportModel> addReport(HomeReportModel report) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final enriched = report.copyWith(
      id: report.id.isEmpty ? 'report_${now.millisecondsSinceEpoch}' : report.id,
      reference: report.reference.isEmpty ? _generateCode() : report.reference,
      createdAt: now,
      status: ReportStatus.disponible,
      timeAgo: 'À l\'instant',
      history: [
        ReportHistoryEntry(
          type: HistoryEventType.signalementCree,
          dateTime: now,
          actorName: report.signalePar ?? 'Vous',
          isCurrentStep: true,
        ),
      ],
    );
    _reports.insert(0, enriched);
    return enriched;
  }

  @override
  Future<HomeReportModel> takeCharge({
    required String reportId,
    required IntervenantModel intervenant,
    required bool whatsAppConsent,
    required String? whatsAppNumber,
    String? groupName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final report = await fetchReportById(reportId);
    if (report == null) throw Exception('Signalement introuvable : $reportId');

    final now = DateTime.now();
    final updatedIntervenant = IntervenantModel(
      id: intervenant.id,
      name: intervenant.name,      // toujours le nom du user
      logoAsset: intervenant.logoAsset,
      takenAgo: 'À l\'instant',
      takenAt: now,
      groupName: groupName,        // null si individuel, nom du groupe sinon
      whatsAppNumber: whatsAppConsent ? whatsAppNumber : null,
      whatsAppVisible: whatsAppConsent,
    );

    final newHistory = List<ReportHistoryEntry>.of(report.history)
      ..add(ReportHistoryEntry(
        type: HistoryEventType.prisEnCharge,
        dateTime: now,
        actorName: intervenant.name,
        isCurrentStep: true,
      ));

    final updated = report.copyWith(
      status: ReportStatus.enCours,
      intervenant: updatedIntervenant,
      history: newHistory,
    );
    _updateReport(updated);
    return updated;
  }

  @override
  Future<HomeReportModel> toggleWhatsApp({
    required String reportId,
    required bool visible,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final report = await fetchReportById(reportId);
    if (report == null) throw Exception('Signalement introuvable');
    if (report.intervenant == null) throw Exception('Aucun intervenant');

    final updated = report.copyWith(
      intervenant: IntervenantModel(
        id: report.intervenant!.id,
        name: report.intervenant!.name,
        logoAsset: report.intervenant!.logoAsset,
        takenAgo: report.intervenant!.takenAgo,
        takenAt: report.intervenant!.takenAt,
        treatedAt: report.intervenant!.treatedAt,
        whatsAppNumber: report.intervenant!.whatsAppNumber,
        whatsAppVisible: visible, // allowContact
      ),
    );
    _updateReport(updated);
    return updated;
  }

  // ── Nouvelle méthode : ajouter/modifier le numéro WhatsApp ────
  @override
  Future<HomeReportModel> updateWhatsAppNumber({
    required String reportId,
    required String number,
    required bool visible,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final report = await fetchReportById(reportId);
    if (report == null) throw Exception('Signalement introuvable');
    if (report.intervenant == null) throw Exception('Aucun intervenant');

    final updated = report.copyWith(
      intervenant: IntervenantModel(
        id: report.intervenant!.id,
        name: report.intervenant!.name,
        logoAsset: report.intervenant!.logoAsset,
        takenAgo: report.intervenant!.takenAgo,
        takenAt: report.intervenant!.takenAt,
        treatedAt: report.intervenant!.treatedAt,
        whatsAppNumber: number,
        whatsAppVisible: visible,
      ),
    );
    _updateReport(updated);
    return updated;
  }

  @override
  Future<ProofVerificationResult> submitProof({
    required String reportId,
    required String imagePath,
    required double proofLatitude,
    required double proofLongitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final report = await fetchReportById(reportId);
    if (report == null) {
      return const ProofVerificationResult(
        isValid: false,
        distanceMeters: 0,
        errorMessage: 'Signalement introuvable',
      );
    }

    final reportLat = report.latitude;
    final reportLon = report.longitude;
    double distance = 0;
    bool isValid = false;

    if (reportLat != null && reportLon != null) {
      distance = _distanceMeters(reportLat, reportLon, proofLatitude, proofLongitude);
      isValid = distance <= 50.0;
    } else {
      isValid = true;
    }

    if (!isValid) {
      return ProofVerificationResult(
        isValid: false,
        distanceMeters: distance,
        errorMessage: 'La photo a été prise à ${distance.toStringAsFixed(0)} m '
            'du signalement. Maximum autorisé : 50 m.',
      );
    }

    final now = DateTime.now();
    final updatedIntervenant = report.intervenant != null
        ? IntervenantModel(
            id: report.intervenant!.id,
            name: report.intervenant!.name,
            logoAsset: report.intervenant!.logoAsset,
            takenAgo: report.intervenant!.takenAgo,
            takenAt: report.intervenant!.takenAt,
            treatedAt: now,
            whatsAppNumber: report.intervenant!.whatsAppNumber,
            whatsAppVisible: report.intervenant!.whatsAppVisible,
          )
        : null;

    final newHistory = List<ReportHistoryEntry>.of(report.history)
      ..add(ReportHistoryEntry(
        type: HistoryEventType.enCoursDeTraitement,
        dateTime: now,
        isCurrentStep: false,
      ))
      ..add(ReportHistoryEntry(
        type: HistoryEventType.traite,
        dateTime: now,
        actorName: report.intervenant?.name,
        isCurrentStep: true,
      ));

    final updated = report.copyWith(
      status: ReportStatus.traite,
      imageAfterAsset: imagePath,
      intervenant: updatedIntervenant,
      history: newHistory,
    );
    _updateReport(updated);

    return ProofVerificationResult(
      isValid: true,
      distanceMeters: distance,
      updatedReport: updated,
    );
  }

  @override
  Future<HomeReportModel> updateStatus({
    required String reportId,
    required ReportStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final report = await fetchReportById(reportId);
    if (report == null) throw Exception('Signalement introuvable');
    final updated = report.copyWith(status: status);
    _updateReport(updated);
    return updated;
  }

  @override
  Future<HomeReportModel> updateReport(HomeReportModel report) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _updateReport(report);
    return report;
  }

  @override
  Future<void> deleteReport(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _reports.removeWhere((r) => r.id == reportId);
  }
}