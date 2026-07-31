// lib/shared/repositories/mock_notification_repository.dart

import '../../features/notifications/models/notification_model.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository._() {
    _seed();
  }
  static final MockNotificationRepository instance = MockNotificationRepository._();

  final List<NotificationModel> _notifications = [];

  // Démo — une par grande catégorie demandée (prise en charge, commentaire,
  // abandon, nouveau membre, action organisée) + une 6e pour démontrer une
  // référence "action" qui résout réellement (Lot 1, avant branchement des
  // vrais déclencheurs au Lot 2). destinataireUserId = sentinel démo (voir
  // notification_model.dart) — NotificationStore le fait correspondre à
  // l'utilisateur réellement connecté au moment de la lecture, jamais un id
  // inventé figé au chargement.
  //
  // referenceId : certains types n'ont aucune donnée de signalement réelle
  // à référencer avant qu'un vrai cas ne soit créé (MockReportRepository ne
  // seed aucun cas au démarrage) — laissé à null plutôt qu'un id inventé ;
  // le tap gère ce cas proprement (message "Élément introuvable").
  void _seed() {
    final now = DateTime.now();
    _notifications.addAll([
      NotificationModel(
        id: 'demo_notif_1',
        type: NotificationType.prisEnCharge,
        titre: 'Votre cas a été pris en charge',
        texte: 'Clean Riviera a pris en charge votre signalement '
            '"Caniveaux bouchés".',
        destinataireUserId: kDemoCurrentUserSentinel,
        lu: false,
        dateCreation: now.subtract(const Duration(minutes: 5)),
        referenceType: 'signalement',
      ),
      NotificationModel(
        id: 'demo_notif_2',
        type: NotificationType.commentaire,
        titre: 'Nouveau commentaire',
        texte: 'Awa K. a commenté votre cas "Bac/Poubelle saturée".',
        destinataireUserId: kDemoCurrentUserSentinel,
        lu: false,
        dateCreation: now.subtract(const Duration(hours: 1)),
        referenceType: 'signalement',
      ),
      NotificationModel(
        id: 'demo_notif_3',
        type: NotificationType.abandonne,
        titre: 'Cas à nouveau disponible',
        texte: 'Votre cas signalé, pris en charge par Bakary T., a été '
            'abandonné et est à nouveau disponible.',
        destinataireUserId: kDemoCurrentUserSentinel,
        lu: true,
        dateCreation: now.subtract(const Duration(days: 1)),
        referenceType: 'signalement',
      ),
      NotificationModel(
        id: 'demo_notif_4',
        type: NotificationType.nouveauMembre,
        titre: 'Nouveau membre',
        texte: 'Bakary T. a rejoint votre groupe Clean Riviera.',
        destinataireUserId: kDemoCurrentUserSentinel,
        lu: true,
        dateCreation: now.subtract(const Duration(days: 2)),
        referenceId: 'grp_clean_riviera',
        referenceType: 'groupe',
      ),
      NotificationModel(
        id: 'demo_notif_5',
        type: NotificationType.actionOrganisee,
        titre: 'Nouvelle publication du groupe',
        texte: 'Un membre a organisé "Nettoyage communautaire" au nom de '
            'Clean Riviera.',
        destinataireUserId: kDemoCurrentUserSentinel,
        lu: true,
        dateCreation: now.subtract(const Duration(days: 2, hours: 3)),
        referenceId: 'grp_clean_riviera',
        referenceType: 'groupe',
      ),
      NotificationModel(
        id: 'demo_notif_6',
        type: NotificationType.actionRappel,
        titre: 'Action demain',
        texte: '"Nettoyage communautaire" commence bientôt.',
        destinataireUserId: kDemoCurrentUserSentinel,
        lu: true,
        dateCreation: now.subtract(const Duration(days: 3)),
        referenceId: 'seed_action_1',
        referenceType: 'action',
      ),
    ]);
  }

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
