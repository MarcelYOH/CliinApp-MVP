// lib/shared/store/action_store.dart
// Store central — ChangeNotifier
// Consomme ActionRepository (mock aujourd'hui, Firebase demain)
// Pour brancher Firebase : remplacer MockActionRepository par FirebaseActionRepository
// sans toucher aux widgets ni aux pages

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/user_location_service.dart';
import '../../features/actions/models/action_model.dart';
import '../../features/notifications/models/notification_model.dart';
import '../models/report_comment_model.dart';
import '../repositories/action_repository.dart';
import '../repositories/mock_action_repository.dart';
import 'auth_store.dart';
import 'group_store.dart';
import 'notification_store.dart';

class ActionStore extends ChangeNotifier {
  ActionStore._();
  static final ActionStore instance = ActionStore._();

  // ignore: prefer_final_fields
  ActionRepository _repository = MockActionRepository.instance;

  // ignore: use_setters_to_change_properties
  void setRepository(ActionRepository repo) {
    _repository = repo;
  }

  List<ActionModel> _actions = [];
  bool _isLoading = false;
  String? _error;

  // Participants par action — bookkeeping interne au store (le modèle ne
  // conserve que participantsCount, un compteur agrégé), même logique que
  // GroupStore._followerIds pour les groupes suivis.
  final Map<String, Set<String>> _participantIds = {};

  List<ActionModel> get allActions => List.unmodifiable(_actions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _setLoading(true);
    try {
      _actions = await _repository.fetchAllActions();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    _startReminderWatcher();
  }

  // Déclencheur 11 — rappel avant une action à laquelle l'utilisateur
  // participe. Pas de job planifié possible sans backend : même principe
  // que ReportStore._checkUpcomingExpiries (ticker périodique 1 min),
  // alerte chaque participant une seule fois par action quand il reste
  // ≤ 24h (J-1, alternative simple proposée pour ce MVP faute de vrai
  // système de notification programmée).
  static const _rappelWindow = Duration(hours: 24);
  final Set<String> _reminderNotified = {};
  Timer? _reminderTimer;

  void _startReminderWatcher() {
    _reminderTimer?.cancel();
    _checkUpcomingActionReminders();
    _reminderTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkUpcomingActionReminders(),
    );
  }

  void _checkUpcomingActionReminders() {
    final now = DateTime.now();
    for (final action in _actions) {
      if (action.statut != ActionStatus.aVenir) continue;
      if (_reminderNotified.contains(action.id)) continue;
      final remaining = action.date.difference(now);
      if (remaining <= Duration.zero || remaining > _rappelWindow) continue;
      _reminderNotified.add(action.id);
      final participants = _participantIds[action.id] ?? const {};
      for (final participantId in participants) {
        NotificationStore.instance.ajouterNotification(NotificationModel(
          id: generateNotificationId(),
          type: NotificationType.actionRappel,
          titre: 'Action demain',
          texte: '"${action.type.label}" commence bientôt.',
          destinataireUserId: participantId,
          dateCreation: now,
          referenceId: action.id,
          referenceType: 'action',
        ));
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  ActionModel? actionById(String id) {
    try {
      return _actions.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void _replaceAction(ActionModel action) {
    final index = _actions.indexWhere((a) => a.id == action.id);
    if (index != -1) {
      _actions[index] = action;
    }
  }

  Future<ActionModel> createAction(ActionModel action) async {
    final added = await _repository.addAction(action);
    _actions = [..._actions, added];
    notifyListeners();
    if (added.organisateurEstGroupe) {
      _notifyActionOrganisee(added);
      // Correction 2 — actionsCount du groupe vient de varier, vérifie si
      // un nouveau palier de badge est franchi.
      GroupStore.instance.recalculerBadges(added.organisateurId);
    }
    _notifyNouvelleActionIfRelevant(added);
    return added;
  }

  // Déclencheur 9 — tous les membres qui suivent le groupe organisateur,
  // sauf l'organisateur (creeParId) lui-même.
  void _notifyActionOrganisee(ActionModel action) {
    final followerIds = GroupStore.instance.followerIdsOf(action.organisateurId)
        .where((id) => id != action.creeParId);
    for (final followerId in followerIds) {
      NotificationStore.instance.ajouterNotification(NotificationModel(
        id: generateNotificationId(),
        type: NotificationType.actionOrganisee,
        titre: 'Nouvelle publication du groupe',
        texte: '${action.organisateurNom} a organisé "${action.type.label}" '
            'au nom de ${action.organisateurNom}.',
        destinataireUserId: followerId,
        dateCreation: DateTime.now(),
        referenceId: action.organisateurId,
        referenceType: 'groupe',
      ));
    }
  }

  // Déclencheur 12 — "les utilisateurs concernés" (rayon 2km OU groupe
  // suivi). ⚠️ Cette app mock ne connaît qu'un seul utilisateur réellement
  // authentifiable (pas d'annuaire multi-utilisateurs, cf. Correction 1
  // "Nos contributeurs" du lot précédent) : seul l'utilisateur COURANT peut
  // donc être honnêtement évalué contre ces critères et notifié — jamais un
  // id inventé pour simuler un "voisinage" qui n'existe pas dans ce mock.
  void _notifyNouvelleActionIfRelevant(ActionModel action) {
    final currentUser = AuthStore.instance.currentUser;
    if (currentUser == null || currentUser.id == action.creeParId) return;

    var concerned = false;
    if (action.latitude != null && action.longitude != null) {
      final meters = UserLocationService.instance
          .distanceMetersTo(action.latitude, action.longitude);
      if (meters != null && meters <= 2000) concerned = true;
    }
    if (!concerned && action.organisateurEstGroupe) {
      concerned =
          GroupStore.instance.isFollowing(action.organisateurId, currentUser.id);
    }
    if (!concerned) return;

    NotificationStore.instance.ajouterNotification(NotificationModel(
      id: generateNotificationId(),
      type: NotificationType.nouvelleAction,
      titre: 'Nouvelle action à proximité',
      texte: '${action.organisateurNom} organise "${action.type.label}" '
          'près de vous.',
      destinataireUserId: currentUser.id,
      dateCreation: DateTime.now(),
      referenceId: action.id,
      referenceType: 'action',
    ));
  }

  Future<void> updateAction(ActionModel action) async {
    final updated = await _repository.updateAction(action);
    _replaceAction(updated);
    notifyListeners();
  }

  Future<void> deleteAction(String actionId) async {
    await _repository.deleteAction(actionId);
    _actions = _actions.where((a) => a.id != actionId).toList();
    _participantIds.remove(actionId);
    notifyListeners();
  }

  bool isParticipant(String actionId, String userId) =>
      _participantIds[actionId]?.contains(userId) ?? false;

  // Expose (lecture seule) le bookkeeping interne des participants — même
  // donnée déjà produite par joinAction/leaveAction, jamais recalculée
  // (Correction 1 "Nos contributeurs" — agrège les participations réelles).
  Set<String> participantIdsFor(String actionId) =>
      Set.unmodifiable(_participantIds[actionId] ?? const {});

  Future<void> joinAction(String actionId, String userId) async {
    final participants = _participantIds.putIfAbsent(actionId, () => {});
    if (!participants.add(userId)) return;
    final updated =
        await _repository.joinAction(actionId: actionId, userId: userId);
    _replaceAction(updated);
    notifyListeners();
    // Déclencheur 14 — organisateur notifié, sauf s'il participe lui-même
    // à sa propre action.
    if (updated.creeParId != userId) {
      final participantName = AuthStore.instance.currentUser?.username ?? 'Un membre';
      NotificationStore.instance.ajouterNotification(NotificationModel(
        id: generateNotificationId(),
        type: NotificationType.nouveauParticipant,
        titre: 'Nouveau participant',
        texte: '$participantName participe à votre action '
            '"${updated.type.label}".',
        destinataireUserId: updated.creeParId,
        dateCreation: DateTime.now(),
        referenceId: updated.id,
        referenceType: 'action',
      ));
    }
  }

  Future<void> leaveAction(String actionId, String userId) async {
    final participants = _participantIds[actionId];
    if (participants == null || !participants.remove(userId)) return;
    final updated =
        await _repository.leaveAction(actionId: actionId, userId: userId);
    _replaceAction(updated);
    notifyListeners();
  }

  Future<void> recordView({
    required String actionId,
    required String userId,
  }) async {
    final updated =
        await _repository.recordView(actionId: actionId, userId: userId);
    _replaceAction(updated);
    notifyListeners();
  }

  Future<void> recordShare(String actionId) async {
    final updated = await _repository.recordShare(actionId: actionId);
    _replaceAction(updated);
    notifyListeners();
  }

  Future<void> addComment({
    required String actionId,
    required ReportComment comment,
  }) async {
    final updated =
        await _repository.addComment(actionId: actionId, comment: comment);
    _replaceAction(updated);
    notifyListeners();
    // Déclencheur 13 — organisateur notifié, sauf s'il commente lui-même
    // son action.
    if (updated.creeParId != comment.authorId) {
      NotificationStore.instance.ajouterNotification(NotificationModel(
        id: generateNotificationId(),
        type: NotificationType.commentaireAction,
        titre: 'Nouveau commentaire',
        texte: '${comment.name} a commenté votre action '
            '"${updated.type.label}".',
        destinataireUserId: updated.creeParId,
        dateCreation: DateTime.now(),
        referenceId: updated.id,
        referenceType: 'action',
      ));
    }
  }

  Future<void> editComment({
    required String actionId,
    required String commentId,
    required String newText,
  }) async {
    final updated = await _repository.editComment(
        actionId: actionId, commentId: commentId, newText: newText);
    _replaceAction(updated);
    notifyListeners();
  }

  Future<void> deleteComment({
    required String actionId,
    required String commentId,
  }) async {
    final updated = await _repository.deleteComment(
        actionId: actionId, commentId: commentId);
    _replaceAction(updated);
    notifyListeners();
  }

  // ── Tri par proximité — même logique que ReportStore.nearbyReports :
  // filtre les actions sans coordonnées, calcule la distance réelle via
  // Geolocator (aucun Haversine réécrit à la main), trie du plus proche au
  // plus éloigné, tous statuts confondus (à venir/en cours/terminée).
  List<ActionModel> getActionsAProximite(
    double userLat,
    double userLng, {
    double rayonKm = 2.0,
  }) {
    final candidates = _actions
        .where((a) => a.latitude != null && a.longitude != null)
        .map((a) => (
              action: a,
              meters: Geolocator.distanceBetween(
                  userLat, userLng, a.latitude!, a.longitude!),
            ))
        .where((e) => e.meters <= rayonKm * 1000)
        .toList()
      ..sort((a, b) => a.meters.compareTo(b.meters));

    return candidates.map((e) => e.action).toList();
  }

  // ── Statistiques personnelles — Profil individuel (Correction 3) ────
  // Actions organisées EN NOM PERSONNEL uniquement (jamais au nom d'un
  // groupe, qui relève de la contribution groupe ci-dessous) — même
  // convention que ReportStore.casPubliesCount (groupId == null).
  int myActionsOrganiseesCount(String userId) => _actions
      .where((a) => !a.organisateurEstGroupe && a.creeParId == userId)
      .length;

  // ── Statistiques groupe — "Notre impact" (À propos), Correction 4/5 ──
  int actionsCountForGroup(String groupId) => _actions
      .where((a) => a.organisateurEstGroupe && a.organisateurId == groupId)
      .length;

  // Participants cumulés ÷ nombre d'actions du groupe — null si aucune
  // action (évite une division par zéro / un "0" trompeur affiché comme
  // une vraie moyenne).
  double? mobilisationMoyenneForGroup(String groupId) {
    final groupActions = _actions
        .where((a) => a.organisateurEstGroupe && a.organisateurId == groupId)
        .toList();
    if (groupActions.isEmpty) return null;
    final totalParticipants =
        groupActions.fold<int>(0, (sum, a) => sum + a.participantsCount);
    return totalParticipants / groupActions.length;
  }

  // ── Statistiques "Mes contributions" — actions organisées au nom d'un
  // groupe, par groupe ET tous groupes (Correction 2 — même structure que
  // ReportStore.casSignalesCountForUserInGroup / TotalForUserAllGroups,
  // jamais dupliquée sous une forme différente).
  int actionsOrganiseesCountForUserInGroup(String groupId, String userId) =>
      _actions
          .where((a) =>
              a.organisateurEstGroupe &&
              a.organisateurId == groupId &&
              a.creeParId == userId)
          .length;

  int actionsOrganiseesTotalForUserAllGroups(String userId) => _actions
      .where((a) => a.organisateurEstGroupe && a.creeParId == userId)
      .length;
}
