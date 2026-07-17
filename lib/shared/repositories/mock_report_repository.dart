// lib/shared/repositories/mock_report_repository.dart

import 'dart:math';
import '../../core/utils/user_location_service.dart';
import '../../features/home/models/home_report_model.dart';
import 'report_repository.dart';

class MockReportRepository implements ReportRepository {
  MockReportRepository._();
  static final MockReportRepository instance = MockReportRepository._();

  // Tolérance anti-fraude preuve vs signalement — cf. correction distance
  // (même principe : une décision automatique n'a de sens que sur une
  // position dont la précision GPS est connue et acceptable).
  static const double _proofToleranceMeters = 50.0;

  // Aucune donnée de départ fictive — uniquement les signalements
  // réellement publiés par les utilisateurs pendant la session.
  final List<HomeReportModel> _reports = <HomeReportModel>[];

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
  Future<HomeReportModel> addComment({
    required String reportId,
    required ReportComment comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final report = await fetchReportById(reportId);
    if (report == null) throw Exception('Signalement introuvable');

    final updated = report.copyWith(
      commentsList: [...report.commentsList, comment],
      comments: report.comments + 1,
    );
    _updateReport(updated);
    return updated;
  }

  @override
  Future<HomeReportModel> editComment({
    required String reportId,
    required String commentId,
    required String newText,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final report = await fetchReportById(reportId);
    if (report == null) throw Exception('Signalement introuvable');

    final updated = report.copyWith(
      commentsList: [
        for (final c in report.commentsList)
          if (c.id == commentId)
            c.copyWith(text: newText, edited: true)
          else
            c,
      ],
    );
    _updateReport(updated);
    return updated;
  }

  @override
  Future<HomeReportModel> deleteComment({
    required String reportId,
    required String commentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final report = await fetchReportById(reportId);
    if (report == null) throw Exception('Signalement introuvable');

    final updated = report.copyWith(
      commentsList:
          report.commentsList.where((c) => c.id != commentId).toList(),
      comments: report.comments > 0 ? report.comments - 1 : 0,
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
    double? proofAccuracy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final report = await fetchReportById(reportId);
    if (report == null) {
      return const ProofVerificationResult(
        status: ProofVerificationStatus.rejectedDistance,
        distanceMeters: 0,
        errorMessage: 'Signalement introuvable',
      );
    }

    // Position de preuve encore imprécise (> 100m, même seuil que la
    // création de signalement) : ni validation ni rejet — une décision
    // anti-fraude prise sur une position à ±100m ou plus n'a aucune
    // valeur probante, quel que soit le résultat du calcul de distance.
    if (proofAccuracy != null &&
        proofAccuracy > UserLocationService.approximateAccuracyMeters) {
      return ProofVerificationResult(
        status: ProofVerificationStatus.pendingAccuracy,
        distanceMeters: 0,
        accuracyMeters: proofAccuracy,
        errorMessage:
            'Position GPS encore imprécise (~${proofAccuracy.round()} m). '
            'Réessayez dans quelques secondes, le temps que le signal s\'améliore.',
      );
    }

    final reportLat = report.latitude;
    final reportLon = report.longitude;
    double distance = 0;
    bool isValid = false;

    if (reportLat != null && reportLon != null) {
      distance = _distanceMeters(reportLat, reportLon, proofLatitude, proofLongitude);
      isValid = distance <= _proofToleranceMeters;
    } else {
      isValid = true;
    }

    if (!isValid) {
      // Preuve hors tolérance : l'intervention n'est pas validée. Le cas
      // redevient Disponible pour que n'importe qui (y compris le même
      // intervenant) puisse le reprendre depuis zéro — MAIS l'intervenant
      // est conservé avec outcome=rejected (pas mis à null) : c'est ce qui
      // alimente le résidu privé consultable par l'auteur et l'ancien
      // intervenant (Mes cas signalés / Mes prises en charge, filtres
      // "Rejetés"). Il sera naturellement écrasé si quelqu'un reprend le
      // cas ensuite.
      final rejectedNow = DateTime.now();
      final reverted = report.copyWith(
        status: ReportStatus.disponible,
        intervenant: report.intervenant?.copyWith(
          outcome: InterventionOutcome.rejected,
        ),
        history: List<ReportHistoryEntry>.of(report.history)
          ..add(ReportHistoryEntry(
            type: HistoryEventType.rejete,
            dateTime: rejectedNow,
            actorName: report.intervenant?.name,
          )),
      );
      _updateReport(reverted);
      return ProofVerificationResult(
        status: ProofVerificationStatus.rejectedDistance,
        distanceMeters: distance,
        updatedReport: reverted,
        errorMessage: 'La photo a été prise à ${distance.toStringAsFixed(0)} m '
            'du signalement. Maximum autorisé : ${_proofToleranceMeters.round()} m.',
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
      ))
      ..add(ReportHistoryEntry(
        type: HistoryEventType.traite,
        dateTime: now,
        actorName: report.intervenant?.name,
      ));

    final updated = report.copyWith(
      status: ReportStatus.traite,
      imageAfterAsset: imagePath,
      intervenant: updatedIntervenant,
      history: newHistory,
    );
    _updateReport(updated);

    return ProofVerificationResult(
      status: ProofVerificationStatus.valid,
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

  @override
  Future<List<HomeReportModel>> expireOverdueTakeovers() async {
    final now = DateTime.now();
    final expired = <HomeReportModel>[];
    for (var i = 0; i < _reports.length; i++) {
      final r = _reports[i];
      if (r.status != ReportStatus.enCours) continue;
      final takenAt = r.intervenant?.takenAt;
      if (takenAt == null) continue;
      if (now.difference(takenAt) <= const Duration(hours: 72)) continue;

      final updated = r.copyWith(
        status: ReportStatus.disponible,
        intervenant: r.intervenant?.copyWith(
          outcome: InterventionOutcome.abandoned,
        ),
        history: List<ReportHistoryEntry>.of(r.history)
          ..add(ReportHistoryEntry(
            type: HistoryEventType.abandonne,
            dateTime: now,
            actorName: r.intervenant?.name,
          )),
      );
      _reports[i] = updated;
      expired.add(updated);
    }
    return expired;
  }
}