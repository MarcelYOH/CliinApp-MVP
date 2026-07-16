// lib/shared/store/report_store.dart
// Store central — ChangeNotifier
// Consomme ReportRepository (mock aujourd'hui, Firebase demain)
// Pour brancher Firebase : remplacer MockReportRepository par FirebaseReportRepository
// sans toucher aux widgets ni aux pages

import 'package:flutter/foundation.dart';
import '../repositories/report_repository.dart';
import '../repositories/mock_report_repository.dart';
import '../../core/utils/user_location_service.dart';
import '../../features/home/models/home_report_model.dart';

class ReportStore extends ChangeNotifier {
  // ── Singleton ─────────────────────────────────────────────────
  ReportStore._() {
    UserLocationService.instance.addListener(notifyListeners);
  }
  static final ReportStore instance = ReportStore._();

  // ── Repository — swap ici pour Firebase ──────────────────────
  // ignore: prefer_final_fields
  ReportRepository _repository = MockReportRepository.instance;

  // ignore: use_setters_to_change_properties
  void setRepository(ReportRepository repo) {
    _repository = repo;
  }

  // ── Rayon de recherche "À proximité" ─────────────────────────
  // MVP : fixé à 2km. Extensible plus tard (UI pour élargir le rayon,
  // ou explorer d'autres villes) — non développé pour le moment.
  static const double _defaultRadiusMeters = 2000.0;
  static const int _maxNearbyReports = 2;

  // ── Fenêtre de fraîcheur "Signalements récents" ───────────────
  // Indépendant du délai d'intervention (72h dans IntervenantDetailPage) :
  // celui-ci est une règle d'affichage, pas une règle d'intervention.
  static const int _recentReportsWindowHours = 72;

  // ── État ──────────────────────────────────────────────────────
  List<HomeReportModel> _reports = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters publics ───────────────────────────────────────────
  List<HomeReportModel> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── "À proximité" — statut disponible UNIQUEMENT, rayon 2km, triés
  // par distance croissante (le plus proche en premier, comme Uber /
  // Google Maps), plafonné à 2 cartes en aperçu. Aucune donnée de repli :
  // sans position GPS connue, on ne peut affirmer qu'un cas est "à
  // proximité" — la liste reste vide plutôt que d'inventer un résultat.
  List<HomeReportModel> get nearbyReports {
    if (UserLocationService.instance.lastKnownPosition == null) return const [];

    final candidates = _reports
        .where((r) => r.status == ReportStatus.disponible)
        .map((r) => (
              report: r,
              meters: UserLocationService.instance
                  .distanceMetersTo(r.latitude, r.longitude),
            ))
        .where((e) => e.meters != null && e.meters! <= _defaultRadiusMeters)
        .toList()
      ..sort((a, b) => a.meters!.compareTo(b.meters!));

    return candidates.map((e) => e.report).take(_maxNearbyReports).toList();
  }

  // ── Compteur "À proximité" pour le message de bienvenue ──────────
  // INDÉPENDANT de [nearbyReports] : tous statuts confondus (Disponible +
  // En cours + Traité), dans le rayon de 2km, sans plafond d'affichage.
  // Reflète l'activité réelle de la zone, pas seulement les 2 cartes
  // visibles en aperçu.
  int get nearbyAllStatusesCount {
    if (UserLocationService.instance.lastKnownPosition == null) return 0;

    return _reports.where((r) {
      final meters = UserLocationService.instance
          .distanceMetersTo(r.latitude, r.longitude);
      return meters != null && meters <= _defaultRadiusMeters;
    }).length;
  }

  List<HomeReportModel> get recentReports {
    final cutoff = DateTime.now()
        .subtract(const Duration(hours: _recentReportsWindowHours));
    final sorted = _reports
        .where((r) =>
            r.status == ReportStatus.disponible &&
            (r.createdAt != null && r.createdAt!.isAfter(cutoff)))
        .toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return sorted.take(1).toList();
  }

  // ── Carte — exploration complète, PAS de filtrage par rayon ─────
  // Conformément à la logique produit : la page Carte sert à explorer
  // TOUS les signalements, contrairement à "À proximité" sur l'accueil.
  List<HomeReportModel> get mapReports => List.unmodifiable(_reports);

  HomeReportModel? reportById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Statistiques profil — source unique pour "Cas publiés" /
  // "Pris en charge" / "Cas traités" (profile_page.dart, public_profile_page.dart) ──
  int casPubliesCount(String userId) =>
      _reports.where((r) => r.signaleParId == userId).length;

  int prisEnChargeCount(String userId) =>
      _reports.where((r) => r.intervenant?.id == userId).length;

  int casTraitesCount(String userId) => _reports
      .where((r) => r.intervenant?.id == userId && r.status == ReportStatus.traite)
      .length;

  // ── Compteur par catégorie — section "Catégories" (accueil) ──────
  // Tous statuts confondus, zéro donnée de repli : si aucun cas n'existe
  // encore pour cette catégorie, retourne 0 (jamais une valeur inventée).
  int categoryCount(ReportCategory category) =>
      _reports.where((r) => r.category == category).length;

  // ── Initialisation ────────────────────────────────────────────
  Future<void> init() async {
    _setLoading(true);
    try {
      _reports = await _repository.fetchAllReports();
      _error = null;
      await UserLocationService.instance.getCurrentPosition();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Rafraîchir manuellement la position (ex: pull-to-refresh) ──
  Future<void> refreshUserPosition() async {
    await UserLocationService.instance.getCurrentPosition(forceRefresh: true);
    notifyListeners();
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
    String? groupName,
  }) async {
    _setLoading(true);
    try {
      final updated = await _repository.takeCharge(
        reportId: reportId,
        intervenant: intervenant,
        whatsAppConsent: whatsAppConsent,
        whatsAppNumber: whatsAppNumber,
        groupName: groupName,
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
    double? proofAccuracy,
  }) async {
    _setLoading(true);
    try {
      final result = await _repository.submitProof(
        reportId: reportId,
        imagePath: imagePath,
        proofLatitude: proofLatitude,
        proofLongitude: proofLongitude,
        proofAccuracy: proofAccuracy,
      );
      // updatedReport peut être renseigné aussi bien pour une preuve
      // validée (statut -> traité) que rejetée (statut -> disponible) —
      // dans les deux cas le store doit refléter le nouveau statut.
      if (result.updatedReport != null) {
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

  // ── Modification d'un signalement (auteur) ────────────────────
  Future<HomeReportModel> updateReport(HomeReportModel report) async {
    _setLoading(true);
    try {
      final updated = await _repository.updateReport(report);
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

  // ── Suppression d'un signalement (auteur) ──────────────────────
  Future<void> deleteReport(String reportId) async {
    _setLoading(true);
    try {
      await _repository.deleteReport(reportId);
      _reports.removeWhere((r) => r.id == reportId);
      _error = null;
      notifyListeners();
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

  // ── Ajouter/modifier numéro WhatsApp ─────────────────────────
  Future<HomeReportModel> updateWhatsAppNumber({
    required String reportId,
    required String number,
    required bool visible,
  }) async {
    try {
      final updated = await _repository.updateWhatsAppNumber(
        reportId: reportId,
        number: number,
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

  // ── Ajouter un commentaire ────────────────────────────────────
  Future<HomeReportModel> addComment({
    required String reportId,
    required ReportComment comment,
  }) async {
    try {
      final updated = await _repository.addComment(
        reportId: reportId,
        comment: comment,
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
}