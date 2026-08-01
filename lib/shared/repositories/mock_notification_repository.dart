// lib/shared/repositories/mock_notification_repository.dart

import '../../features/notifications/models/notification_model.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository._();
  static final MockNotificationRepository instance = MockNotificationRepository._();

  // Aucune notification factice au démarrage — seuls les vrais événements
  // de l'application (déjà branchés dans ReportStore/GroupStore/
  // ActionStore) alimentent cette liste via addNotification(). Tant
  // qu'aucun événement réel ne s'est produit, NotificationsPage affiche
  // son état vide prévu à cet effet.
  final List<NotificationModel> _notifications = [];

  @override
  Future<List<NotificationModel>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 60));
    return List.of(_notifications);
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) throw Exception('Notification introuvable');
    final updated = _notifications[index].copyWith(lu: true);
    _notifications[index] = updated;
    return updated;
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (var i = 0; i < _notifications.length; i++) {
      final destinataire = _notifications[i].destinataireUserId;
      if (destinataire == userId || destinataire == kDemoCurrentUserSentinel) {
        _notifications[i] = _notifications[i].copyWith(lu: true);
      }
    }
  }

  @override
  Future<NotificationModel> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    return notification;
  }
}
