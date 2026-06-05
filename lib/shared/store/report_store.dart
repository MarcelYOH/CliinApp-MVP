// lib/shared/store/report_store.dart
// Store central — ChangeNotifier
// Consomme ReportRepository (mock aujourd'hui, Firebase demain)
// Pour brancher Firebase : remplacer MockReportRepository par FirebaseReportRepository
// sans toucher aux widgets ni aux pages

import 'package:flutter/foundation.dart';
import '../repositories/report_repository.dart';
import '../repositories/mock_report_repository.dart';
import '../../features/home/models/report_model.dart';

class ReportStore extends ChangeNotifier {
  // ── Singleton ─────────────────────────────────────────────────
  ReportStore._();
  static final ReportStore instance = ReportStore._();

  // ── Repository — swap ici pour Firebase ──────────────────────
  // ignore: prefer_final_fields
  ReportRepository _repository = MockReportRepository.instance;

  // ignore: use_setters_to_change_properties
  void setRepository(ReportRepository repo) {
    _repository = repo;
  }

  // ── État ──────────────────────────────────────────────────────
  List<HomeReportModel> _reports = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters publics ───────────────────────────────────────────
  List<HomeReportModel> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<HomeReportModel> get nearbyReports =>
      _reports.where((r) => r.status != ReportStatus.traite).take(5).toList();

  List<HomeReportModel> get recentReports {
    final sorted = [..._reports]
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    return sorted.take(5).toList();
  }

  List<HomeReportModel> get mapReports => List.unmodifiable(_reports);

  HomeReportModel? reportById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Initialisation ────────────────────────────────────────────
  Future<void> init() async {
    _setLoading(true);
    try {
      _reports = await _repository.fetchAllReports();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Signalement — publication ─────────────────────────────────
  Future<HomeReportModel> addReport(HomeReportModel report) async {
    _setLoading(true);
    try {
      final added = await _repository.addReport(report);
      _reports.insert(0, added);
      _error = null;
      notifyListeners();
      return added;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Prise en charge ───────────────────────────────────────────
  Future<HomeReportModel> takeCharge({
    required String reportId,
    required IntervenantModel intervenant,
    required bool whatsAppConsent,
    required String? whatsAppNumber,
  }) async {
    _setLoading(true);
    try {
      final updated = await _repository.takeCharge(
        reportId: reportId,
        intervenant: intervenant,
        whatsAppConsent: whatsAppConsent,
        whatsAppNumber: whatsAppNumber,
      );
      _replaceReport(updated);
      _error = null;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Toggle WhatsApp ───────────────────────────────────────────
  Future<HomeReportModel> toggleWhatsApp({
    required String reportId,
    required bool visible,
  }) async {
    try {
      final updated = await _repository.toggleWhatsApp(
        reportId: reportId,
        visible: visible,
      );
      _replaceReport(updated);
      _error = null;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // ── Preuve d'intervention ─────────────────────────────────────
  Future<ProofVerificationResult> submitProof({
    required String reportId,
    required String imagePath,
    required double proofLatitude,
    required double proofLongitude,
  }) async {
    _setLoading(true);
    try {
      final result = await _repository.submitProof(
        reportId: reportId,
        imagePath: imagePath,
        proofLatitude: proofLatitude,
        proofLongitude: proofLongitude,
      );
      if (result.isValid && result.updatedReport != null) {
        _replaceReport(result.updatedReport!);
        notifyListeners();
      }
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers internes ──────────────────────────────────────────
  void _replaceReport(HomeReportModel updated) {
    final index = _reports.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reports[index] = updated;
    } else {
      _reports.insert(0, updated);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}