// lib/shared/store/report_store.dart
// Store central — ChangeNotifier
// Consomme ReportRepository (mock aujourd'hui, Firebase demain)
// Pour brancher Firebase : remplacer MockReportRepository par FirebaseReportRepository
// sans toucher aux widgets ni aux pages

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/report_repository.dart';
import '../repositories/mock_report_repository.dart';
import '../../core/utils/user_location_service.dart';
import '../../features/home/models/home_report_model.dart';
import '../../features/notifications/models/notification_model.dart';
import 'notification_store.dart';

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
  // Même source de vérité que [nearbyReports] (statut Disponible
  // UNIQUEMENT, rayon 2km) — seule différence : sans le plafond de 2
  // cartes, puisque c'est un compte total et non une liste d'aperçu. Un
  // cas En cours/Traité/Abandonné/Rejeté ne doit jamais y être inclus.
  int get nearbyDisponibleCount {
    if (UserLocationService.instance.lastKnownPosition == null) return 0;

    return _reports.where((r) {
      if (r.status != ReportStatus.disponible) return false;
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
  // Correction 1 — un cas publié au nom d'un groupe (groupId != null) ne
  // compte jamais dans les statistiques personnelles, comme
  // prisEnChargeCount/casTraitesCount ci-dessous.
  int casPubliesCount(String userId) => _reports
      .where((r) => r.signaleParId == userId && r.groupId == null)
      .length;

  // Nombre de cas ACTUELLEMENT en cours parmi ceux pris en charge par
  // l'utilisateur EN SON NOM PERSONNEL — pas un cumul historique : un cas
  // qui quitte le statut "en cours" (traité, abandonné, rejeté) ne compte
  // plus ici. Un cas pris en charge (ou rebasculé, voir changeAttribution)
  // au nom d'un groupe (intervenant.groupName != null) ne compte JAMAIS
  // dans les statistiques personnelles — il bascule entièrement vers celles
  // du groupe (voir casPrisEnChargeCountForGroup).
  int prisEnChargeCount(String userId) => _reports
      .where((r) =>
          r.intervenant?.id == userId &&
          r.intervenant?.groupName == null &&
          r.status == ReportStatus.enCours)
      .length;

  int casTraitesCount(String userId) => _reports
      .where((r) =>
          r.intervenant?.id == userId &&
          r.intervenant?.groupName == null &&
          r.status == ReportStatus.traite)
      .length;

  // ── Statistique groupe — "Pris en charge" ────────────────────────
  // Miroir de prisEnChargeCount, mais côté groupe : compte les cas
  // ACTUELLEMENT en cours pris en charge au nom de ce groupe (peu importe
  // quel administrateur a effectué la prise en charge ou le rebasculement
  // d'attribution). Appariement par nom de groupe — même convention que
  // intervenant.groupName / take_charge_flow.
  int casPrisEnChargeCountForGroup(String groupName) => _reports
      .where((r) =>
          r.intervenant?.groupName == groupName &&
          r.status == ReportStatus.enCours)
      .length;

  // ── Statistiques groupe — "Notre impact" (À propos) ──────────────
  // Totaux réels, cumulés sur toute la durée de vie du cas (pas seulement
  // les cas actuellement actifs) — cohérents avec les totaux affichés dans
  // "Nos cas signalés" / "Nos prises en charge" (Espace gestion).
  int casSignalesCountForGroup(String groupId) =>
      _reports.where((r) => r.groupId == groupId).length;

  int casTraitesCountForGroup(String groupId) => _reports
      .where((r) => r.groupId == groupId && r.status == ReportStatus.traite)
      .length;

  int prisEnChargeTotalCountForGroup(String groupName) =>
      _reports.where((r) => r.intervenant?.groupName == groupName).length;

  // ── Statistiques "Mes contributions" — par groupe ET tous groupes ────
  // Un cas signalé/pris en charge au nom d'un groupe (jamais les
  // signalements/prises en charge personnels, cf. Correction 1) — total
  // cumulé sur toute la durée de vie du cas, peu importe l'appartenance
  // actuelle de l'utilisateur au groupe.
  int casSignalesCountForUserInGroup(String groupId, String userId) =>
      _reports
          .where((r) => r.groupId == groupId && r.signaleParId == userId)
          .length;

  int prisEnChargeCountForUserInGroup(String groupName, String userId) =>
      _reports
          .where((r) =>
              r.intervenant?.groupName == groupName &&
              r.intervenant?.id == userId)
          .length;

  int casSignalesTotalForUserAllGroups(String userId) => _reports
      .where((r) => r.groupId != null && r.signaleParId == userId)
      .length;

  int prisEnChargeTotalForUserAllGroups(String userId) => _reports
      .where((r) =>
          r.intervenant?.groupName != null && r.intervenant?.id == userId)
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
    await _checkExpiredTakeovers();
    _startExpiryWatcher();
  }

  // ── Abandon automatique (délai 72h dépassé sans preuve) ─────────
  // Pas de backend pour porter un job planifié dans ce MVP : on simule le
  // même effet côté client via un ticker périodique, qui fait passer les
  // cas "en cours" dépassés en Disponible + résidu privé (outcome
  // abandoned), exactement comme le fait submitProof() pour un rejet.
  Timer? _expiryTimer;

  void _startExpiryWatcher() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkExpiredTakeovers(),
    );
  }

  Future<void> _checkExpiredTakeovers() async {
    final expired = await _repository.expireOverdueTakeovers();
    if (expired.isNotEmpty) {
      for (final report in expired) {
        _replaceReport(report);
        // Déclencheur 5 (abandon automatique — délai 72h dépassé).
        _notifyAbandonOrReject(report, report.intervenant, isAbandon: true);
        _delaiExpireNotified.remove(report.id);
      }
      notifyListeners();
    }
    _checkUpcomingExpiries();
  }

  // Déclencheur 6 — rappel avant expiration (délai 72h). Pas de job
  // planifié possible sans backend : réutilise le même ticker périodique
  // (1 min) que l'abandon automatique ci-dessus, alerte l'intervenant une
  // seule fois par prise en charge quand il reste ≤ 6h (fenêtre alignée
  // sur l'exemple déjà validé dans page_notifications.jsx : "Il vous reste
  // 6h"). _delaiExpireNotified évite les rappels répétés à chaque tick ;
  // remise à zéro dès qu'une nouvelle prise en charge démarre sur ce cas
  // (voir takeCharge) ou qu'il expire (ci-dessus), pour permettre un
  // nouveau rappel sur une future prise en charge du même cas.
  static const _delaiRappelWindow = Duration(hours: 6);
  final Set<String> _delaiExpireNotified = {};

  void _checkUpcomingExpiries() {
    final now = DateTime.now();
    for (final r in _reports) {
      if (r.status != ReportStatus.enCours) continue;
      final intervenant = r.intervenant;
      final takenAt = intervenant?.takenAt;
      if (intervenant == null || takenAt == null) continue;
      if (_delaiExpireNotified.contains(r.id)) continue;
      final remaining = const Duration(hours: 72) - now.difference(takenAt);
      if (remaining <= Duration.zero || remaining > _delaiRappelWindow) continue;
      _delaiExpireNotified.add(r.id);
      NotificationStore.instance.ajouterNotification(NotificationModel(
        id: generateNotificationId(),
        type: NotificationType.delaiExpire,
        titre: 'Délai bientôt expiré',
        texte: 'Il vous reste ${remaining.inHours}h pour soumettre une '
            'preuve sur "${r.title}".',
        destinataireUserId: intervenant.id,
        dateCreation: now,
        referenceId: r.id,
        referenceType: 'signalement',
      ));
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
      // Nouvelle prise en charge sur ce cas — un futur rappel de délai
      // (Déclencheur 6) doit pouvoir se déclencher à nouveau pour elle.
      _delaiExpireNotified.remove(reportId);
      // Déclencheur 1 — l'auteur est notifié, sauf s'il a pris en charge
      // son propre cas (n'a normalement pas de sens, garde-fou quand même).
      if (updated.signaleParId != null && updated.signaleParId != intervenant.id) {
        final intervenantLabel = groupName ?? intervenant.name;
        NotificationStore.instance.ajouterNotification(NotificationModel(
          id: generateNotificationId(),
          type: NotificationType.prisEnCharge,
          titre: 'Votre cas a été pris en charge',
          texte: '$intervenantLabel a pris en charge votre signalement '
              '"${updated.title}".',
          destinataireUserId: updated.signaleParId!,
          dateCreation: DateTime.now(),
          referenceId: updated.id,
          referenceType: 'signalement',
        ));
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Modifier l'attribution d'une prise en charge active ──────────
  Future<HomeReportModel> changeAttribution({
    required String reportId,
    required String? groupName,
  }) async {
    try {
      final updated = await _repository.changeAttribution(
        reportId: reportId,
        groupName: groupName,
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

  // ── Abandon volontaire — avant la fin du délai de 72h ────────────
  Future<HomeReportModel> abandonTakeoverVoluntarily({
    required String reportId,
  }) async {
    try {
      final updated = await _repository.abandonTakeoverVoluntarily(
        reportId: reportId,
      );
      _replaceReport(updated);
      _error = null;
      notifyListeners();
      // Déclencheur 5 (abandon volontaire) — updated.intervenant garde le
      // même id/nom/groupName que l'intervenant d'origine (seul outcome
      // change), pas besoin d'un snapshot "avant".
      _notifyAbandonOrReject(updated, updated.intervenant, isAbandon: true);
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Déclencheur 5 — factorisé, utilisé par abandon volontaire, abandon
  // automatique (délai dépassé) et rejet de preuve : même texte EXACT
  // demandé, même garde-fou (jamais notifié s'il est lui-même
  // l'intervenant concerné).
  void _notifyAbandonOrReject(
    HomeReportModel updated,
    IntervenantModel? intervenant, {
    required bool isAbandon,
  }) {
    final authorId = updated.signaleParId;
    if (authorId == null) return;
    if (authorId == intervenant?.id) return;
    final intervenantLabel = intervenant?.groupName ?? intervenant?.name ?? 'un intervenant';
    final verbe = isAbandon ? 'abandonné' : 'rejeté';
    NotificationStore.instance.ajouterNotification(NotificationModel(
      id: generateNotificationId(),
      type: isAbandon ? NotificationType.abandonne : NotificationType.rejete,
      titre: 'Cas à nouveau disponible',
      texte: 'Votre cas signalé, pris en charge par $intervenantLabel, a été '
          '$verbe et est à nouveau disponible.',
      destinataireUserId: authorId,
      dateCreation: DateTime.now(),
      referenceId: updated.id,
      referenceType: 'signalement',
    ));
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
        final r = result.updatedReport!;
        _replaceReport(r);
        notifyListeners();
        if (result.status == ProofVerificationStatus.valid) {
          // Déclencheur 2 — preuve validée, cas traité. Destinataire :
          // l'auteur du signalement.
          if (r.signaleParId != null) {
            NotificationStore.instance.ajouterNotification(NotificationModel(
              id: generateNotificationId(),
              type: NotificationType.traite,
              titre: 'Cas traité avec succès',
              texte: 'Votre cas "${r.title}" a été marqué comme traité.',
              destinataireUserId: r.signaleParId!,
              dateCreation: DateTime.now(),
              referenceId: r.id,
              referenceType: 'signalement',
            ));
          }
        } else if (result.status == ProofVerificationStatus.rejectedDistance) {
          // Déclencheur 5 (rejet — preuve hors tolérance) pour l'auteur +
          // Déclencheur 7 pour l'intervenant dont la preuve est rejetée.
          _notifyAbandonOrReject(r, r.intervenant, isAbandon: false);
          final intervenant = r.intervenant;
          if (intervenant != null) {
            NotificationStore.instance.ajouterNotification(NotificationModel(
              id: generateNotificationId(),
              type: NotificationType.preuveRejetee,
              titre: 'Preuve refusée',
              texte: 'Votre preuve pour "${r.title}" n\'est pas conforme '
                  '(écart GPS).',
              destinataireUserId: intervenant.id,
              dateCreation: DateTime.now(),
              referenceId: r.id,
              referenceType: 'signalement',
            ));
          }
        }
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
      // Déclencheur 4 — auteur du signalement notifié, sauf s'il commente
      // lui-même son propre cas.
      if (updated.signaleParId != null && updated.signaleParId != comment.authorId) {
        NotificationStore.instance.ajouterNotification(NotificationModel(
          id: generateNotificationId(),
          type: NotificationType.commentaire,
          titre: 'Nouveau commentaire',
          texte: '${comment.name} a commenté votre cas "${updated.title}".',
          destinataireUserId: updated.signaleParId!,
          dateCreation: DateTime.now(),
          referenceId: updated.id,
          referenceType: 'signalement',
        ));
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // ── Modifier un commentaire ───────────────────────────────────
  Future<HomeReportModel> editComment({
    required String reportId,
    required String commentId,
    required String newText,
  }) async {
    try {
      final updated = await _repository.editComment(
        reportId: reportId,
        commentId: commentId,
        newText: newText,
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

  // ── Supprimer un commentaire ──────────────────────────────────
  Future<HomeReportModel> deleteComment({
    required String reportId,
    required String commentId,
  }) async {
    try {
      final updated = await _repository.deleteComment(
        reportId: reportId,
        commentId: commentId,
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

  // ── Vues / partages (Correction 7) ───────────────────────────────
  Future<HomeReportModel> recordView({
    required String reportId,
    required String userId,
  }) async {
    try {
      final updated =
          await _repository.recordView(reportId: reportId, userId: userId);
      _replaceReport(updated);
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<HomeReportModel> recordShare({required String reportId}) async {
    try {
      final updated = await _repository.recordShare(reportId: reportId);
      _replaceReport(updated);
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}