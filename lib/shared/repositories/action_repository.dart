// lib/shared/repositories/action_repository.dart

import '../../features/actions/models/action_model.dart';
import '../models/report_comment_model.dart';

abstract class ActionRepository {
  Future<List<ActionModel>> fetchAllActions();
  Future<ActionModel?> fetchActionById(String id);

  Future<ActionModel> addAction(ActionModel action);
  Future<ActionModel> updateAction(ActionModel action);
  Future<void> deleteAction(String actionId);

  Future<ActionModel> joinAction({
    required String actionId,
    required String userId,
  });

  Future<ActionModel> leaveAction({
    required String actionId,
    required String userId,
  });

  // Anti-abus : n'incrémente viewsCount que si userId n'est pas déjà dans
  // viewedByUserIds (jamais l'organisateur — filtré par l'appelant avant
  // même d'appeler cette méthode), même logique que ReportRepository.recordView.
  Future<ActionModel> recordView({
    required String actionId,
    required String userId,
  });

  // Pas d'anti-abus — le compteur s'incrémente à chaque partage, même
  // répété par le même utilisateur (même logique que ReportRepository.recordShare).
  Future<ActionModel> recordShare({required String actionId});

  Future<ActionModel> addComment({
    required String actionId,
    required ReportComment comment,
  });

  Future<ActionModel> editComment({
    required String actionId,
    required String commentId,
    required String newText,
  });

  Future<ActionModel> deleteComment({
    required String actionId,
    required String commentId,
  });
}
