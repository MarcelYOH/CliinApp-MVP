// lib/shared/store/action_store.dart
// Store central — ChangeNotifier
// Consomme ActionRepository (mock aujourd'hui, Firebase demain)
// Pour brancher Firebase : remplacer MockActionRepository par FirebaseActionRepository
// sans toucher aux widgets ni aux pages

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/actions/models/action_model.dart';
import '../models/report_comment_model.dart';
import '../repositories/action_repository.dart';
import '../repositories/mock_action_repository.dart';

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
    return added;
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

  Future<void> joinAction(String actionId, String userId) async {
    final participants = _participantIds.putIfAbsent(actionId, () => {});
    if (!participants.add(userId)) return;
    final updated =
        await _repository.joinAction(actionId: actionId, userId: userId);
    _replaceAction(updated);
    notifyListeners();
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
}
