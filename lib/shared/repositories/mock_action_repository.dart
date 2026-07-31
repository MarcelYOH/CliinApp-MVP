// lib/shared/repositories/mock_action_repository.dart

import 'dart:math';
import '../../features/actions/models/action_model.dart';
import '../models/report_comment_model.dart';
import 'action_repository.dart';

class MockActionRepository implements ActionRepository {
  MockActionRepository._() {
    _seed();
  }
  static final MockActionRepository instance = MockActionRepository._();

  final List<ActionModel> _actions = <ActionModel>[];

  String _generateActionId() {
    final rand = Random();
    return 'act_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(9999)}';
  }

  void _seed() {
    final now = DateTime.now();
    _actions.addAll([
      ActionModel(
        id: 'seed_action_1',
        type: ActionType.nettoyage,
        date: now.add(const Duration(days: 3)),
        lieu: 'Riviera 2, Cocody',
        latitude: 5.3599,
        longitude: -3.9877,
        description:
            'Grand nettoyage communautaire des abords du marché de Riviera 2, '
            'ouvert à tous les riverains.',
        participantsCount: 12,
        statut: ActionStatus.aVenir,
        organisateurNom: 'Clean Riviera',
        // Correspond au vrai groupe seedé par MockGroupRepository (Lot 2 —
        // "Organisé par" résout la fiche groupe réelle via cet id).
        organisateurId: 'grp_clean_riviera',
        organisateurEstGroupe: true,
        creeParId: 'seed_admin_clean_riviera',
        createdAt: now.subtract(const Duration(days: 2)),
        viewsCount: 34,
        commentsCount: 2,
        sharesCount: 3,
        besoinBenevoles: 'Nous cherchons 10 bénévoles supplémentaires pour '
            'couvrir toute la zone du marché.',
        besoinMateriel: 'Gants, sacs poubelle et brouettes bienvenus.',
        commentsList: [
          ReportComment(
            id: 'seed_comment_1',
            initials: 'AK',
            name: 'Aya Kouassi',
            text: 'Super initiative, je serai là avec 2 amis !',
            createdAt: now.subtract(const Duration(hours: 5)),
          ),
          ReportComment(
            id: 'seed_comment_2',
            initials: 'CR',
            name: 'Clean Riviera',
            text: 'Merci à tous les inscrits, rendez-vous à 8h devant le marché.',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      ActionModel(
        id: 'seed_action_2',
        type: ActionType.collecte,
        date: now.subtract(const Duration(hours: 2)),
        lieu: 'Plateau, Abidjan',
        latitude: 5.3247,
        longitude: -4.0163,
        description: 'Collecte des déchets plastiques le long de l\'avenue principale.',
        participantsCount: 8,
        statut: ActionStatus.enCours,
        organisateurNom: 'Green City',
        // Correspond au vrai groupe seedé par MockGroupRepository.
        organisateurId: 'grp_green_city',
        organisateurEstGroupe: true,
        creeParId: 'seed_admin_green_city',
        createdAt: now.subtract(const Duration(days: 1)),
        viewsCount: 51,
        commentsCount: 0,
        sharesCount: 6,
      ),
      ActionModel(
        id: 'seed_action_3',
        type: ActionType.curage,
        date: now.add(const Duration(days: 7)),
        lieu: 'Yopougon, Abidjan',
        latitude: 5.3453,
        longitude: -4.0868,
        description: 'Curage des caniveaux avant la saison des pluies.',
        participantsCount: 20,
        statut: ActionStatus.aVenir,
        organisateurNom: 'Eco Jeunes',
        // Correspond au vrai groupe seedé par MockGroupRepository.
        organisateurId: 'grp_eco_jeunes',
        organisateurEstGroupe: true,
        creeParId: 'seed_admin_eco_jeunes',
        createdAt: now.subtract(const Duration(hours: 6)),
        viewsCount: 22,
        commentsCount: 0,
        sharesCount: 1,
        besoinCommunication: 'Aidez-nous à relayer l\'information dans vos '
            'quartiers avant le jour J.',
      ),
      ActionModel(
        id: 'seed_action_4',
        type: ActionType.sensibilisationProximite,
        date: now.subtract(const Duration(days: 10)),
        lieu: 'Marcory, Abidjan',
        latitude: 5.2938,
        longitude: -3.9847,
        description:
            'Sensibilisation de proximité au tri des déchets auprès des ménages.',
        participantsCount: 6,
        statut: ActionStatus.terminee,
        organisateurNom: 'Anonyme',
        organisateurId: 'seed_user_anonyme_1',
        creeParId: 'seed_user_anonyme_1',
        isAnonyme: true,
        createdAt: now.subtract(const Duration(days: 11)),
        viewsCount: 15,
        commentsCount: 0,
        sharesCount: 0,
      ),
      ActionModel(
        id: 'seed_action_5',
        type: ActionType.ecolePropre,
        date: now.add(const Duration(days: 1)),
        lieu: 'Treichville, Abidjan',
        latitude: 5.2914,
        longitude: -4.0086,
        description: 'Opération École propre à l\'école primaire de Treichville.',
        participantsCount: 15,
        statut: ActionStatus.aVenir,
        organisateurNom: 'Kouassi Aya',
        organisateurId: 'seed_user_kouassi',
        creeParId: 'seed_user_kouassi',
        createdAt: now.subtract(const Duration(hours: 20)),
        viewsCount: 9,
        commentsCount: 0,
        sharesCount: 2,
      ),
    ]);
  }

  @override
  Future<List<ActionModel>> fetchAllActions() async => List.of(_actions);

  @override
  Future<ActionModel?> fetchActionById(String id) async {
    try {
      return _actions.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ActionModel> addAction(ActionModel action) async {
    final withId = action.id.isEmpty
        ? action.copyWith(id: _generateActionId())
        : action;
    _actions.add(withId);
    return withId;
  }

  @override
  Future<ActionModel> updateAction(ActionModel action) async {
    final index = _actions.indexWhere((a) => a.id == action.id);
    if (index == -1) {
      throw StateError('Action introuvable: ${action.id}');
    }
    _actions[index] = action;
    return action;
  }

  @override
  Future<void> deleteAction(String actionId) async {
    _actions.removeWhere((a) => a.id == actionId);
  }

  @override
  Future<ActionModel> joinAction({
    required String actionId,
    required String userId,
  }) async {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index == -1) throw StateError('Action introuvable: $actionId');
    final updated = _actions[index]
        .copyWith(participantsCount: _actions[index].participantsCount + 1);
    _actions[index] = updated;
    return updated;
  }

  @override
  Future<ActionModel> leaveAction({
    required String actionId,
    required String userId,
  }) async {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index == -1) throw StateError('Action introuvable: $actionId');
    final current = _actions[index];
    final next = current.participantsCount > 0
        ? current.participantsCount - 1
        : 0;
    final updated = current.copyWith(participantsCount: next);
    _actions[index] = updated;
    return updated;
  }

  @override
  Future<ActionModel> recordView({
    required String actionId,
    required String userId,
  }) async {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index == -1) throw StateError('Action introuvable: $actionId');
    final current = _actions[index];
    if (current.viewedByUserIds.contains(userId)) return current;
    final updated = current.copyWith(
      viewsCount: current.viewsCount + 1,
      viewedByUserIds: [...current.viewedByUserIds, userId],
    );
    _actions[index] = updated;
    return updated;
  }

  @override
  Future<ActionModel> recordShare({required String actionId}) async {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index == -1) throw StateError('Action introuvable: $actionId');
    final updated =
        _actions[index].copyWith(sharesCount: _actions[index].sharesCount + 1);
    _actions[index] = updated;
    return updated;
  }

  @override
  Future<ActionModel> addComment({
    required String actionId,
    required ReportComment comment,
  }) async {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index == -1) throw StateError('Action introuvable: $actionId');
    final current = _actions[index];
    final updated = current.copyWith(
      commentsList: [...current.commentsList, comment],
      commentsCount: current.commentsCount + 1,
    );
    _actions[index] = updated;
    return updated;
  }

  @override
  Future<ActionModel> editComment({
    required String actionId,
    required String commentId,
    required String newText,
  }) async {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index == -1) throw StateError('Action introuvable: $actionId');
    final current = _actions[index];
    final updatedComments = current.commentsList
        .map((c) =>
            c.id == commentId ? c.copyWith(text: newText, edited: true) : c)
        .toList();
    final updated = current.copyWith(commentsList: updatedComments);
    _actions[index] = updated;
    return updated;
  }

  @override
  Future<ActionModel> deleteComment({
    required String actionId,
    required String commentId,
  }) async {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index == -1) throw StateError('Action introuvable: $actionId');
    final current = _actions[index];
    final updatedComments =
        current.commentsList.where((c) => c.id != commentId).toList();
    final updated = current.copyWith(
      commentsList: updatedComments,
      commentsCount: current.commentsCount > 0 ? current.commentsCount - 1 : 0,
    );
    _actions[index] = updated;
    return updated;
  }
}
