// lib/shared/repositories/notification_repository.dart

import '../../features/notifications/models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchAll();

  Future<NotificationModel> markAsRead(String notificationId);

  Future<void> markAllAsRead(String userId);

  Future<NotificationModel> addNotification(NotificationModel notification);
}
