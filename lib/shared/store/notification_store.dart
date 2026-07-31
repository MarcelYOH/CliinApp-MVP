// lib/shared/store/notification_store.dart
// Store central — ChangeNotifier. Consomme NotificationRepository (mock
// aujourd'hui, Firebase demain). Pour brancher un vrai backend : remplacer
// MockNotificationRepository par une implémentation Firebase sans toucher
// aux widgets ni aux pages.

import 'package:flutter/foundation.dart';
import '../../features/notifications/models/notification_model.dart';
import '../repositories/mock_notification_repository.dart';
import '../repositories/notification_repository.dart';
import 'auth_store.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  // ignore: prefer_final_fields
  NotificationRepository _repository = MockNotificationRepository.instance;

  // ignore: use_setters_to_change_properties
  void setRepository(NotificationRepository repo) {
    _repository = repo;
  }

  List<NotificationModel> _all = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Notifications de l'utilisateur CONNECTÉ uniquement, plus récentes en
  // premier — jamais mises en cache filtrées (recalculé à chaque accès pour
  // toujours refléter l'utilisateur courant).
  List<NotificationModel> get notifications {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return const [];
    final mine = _all
        .where((n) =>
            n.destinataireUserId == userId ||
            n.destinataireUserId == kDemoCurrentUserSentinel)
        .toList()
      ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return mine;
  }

  int get nombreNonLues => notifications.where((n) => !n.lu).length;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _all = await _repository.fetchAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marquerCommeLue(String notificationId) async {
    final index = _all.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _all[index].lu) return;
    _all[index] = _all[index].copyWith(lu: true);
    notifyListeners();
    await _repository.markAsRead(notificationId);
  }

  Future<void> marquerToutCommeLu() async {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return;
    _all = _all
        .map((n) => (n.destinataireUserId == userId ||
                n.destinataireUserId == kDemoCurrentUserSentinel)
            ? n.copyWith(lu: true)
            : n)
        .toList();
    notifyListeners();
    await _repository.markAllAsRead(userId);
  }

  // Appelée depuis les autres Stores dès qu'un événement notifiable se
  // produit (Lot 2) — pas encore utilisée dans ce Lot 1.
  Future<void> ajouterNotification(NotificationModel notif) async {
    final added = await _repository.addNotification(notif);
    _all = [added, ..._all];
    notifyListeners();
  }
}
