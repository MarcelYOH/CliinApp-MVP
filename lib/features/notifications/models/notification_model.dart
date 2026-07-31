// lib/features/notifications/models/notification_model.dart
// Module Notifications — canal IN-APP uniquement pour ce MVP (la cloche 🔔
// déjà présente sur plusieurs écrans). Les push natives (Firebase Cloud
// Messaging) viendront plus tard avec le backend, sans changer ce modèle.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// Générateur d'id unique — même convention que les autres stores
// (ActionStore._generateActionId) — réutilisé par tous les déclencheurs
// (Lot 2) plutôt que dupliqué à chaque site d'appel.
String generateNotificationId() {
  final rand = Random();
  return 'notif_${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(9999)}';
}

// 15 types validés — reproduits fidèlement depuis page_notifications.jsx
// (TYPES_NOTIF), icône/couleur cohérentes avec ce qui est déjà utilisé
// ailleurs dans l'app pour ce même événement (ex: HandHeart -> même icône
// que "Prises en charge" sur les cartes de signalement).
enum NotificationType {
  prisEnCharge,
  traite,
  conteste,
  commentaire,
  delaiExpire,
  preuveRejetee,
  abandonne,
  rejete,
  nouveauMembre,
  actionOrganisee,
  actionRappel,
  nouveauBadge,
  nouvelleAction,
  commentaireAction,
  nouveauParticipant,
  // Correction 3 (Lot 3) — envoyée à chaque utilisateur qui suit un cas
  // (bouton "Suivre", indépendant du rôle auteur/intervenant) quand son
  // statut change, en plus des notifications déjà dédiées à l'auteur et à
  // l'intervenant (jamais à la place).
  casSuiviMisAJour,
}

extension NotificationTypeExt on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.prisEnCharge:      return Icons.volunteer_activism_rounded;
      case NotificationType.traite:            return Icons.check_circle_rounded;
      case NotificationType.conteste:          return Icons.error_outline_rounded;
      case NotificationType.commentaire:       return Icons.chat_bubble_outline_rounded;
      case NotificationType.delaiExpire:       return Icons.timer_outlined;
      case NotificationType.preuveRejetee:     return Icons.gpp_bad_rounded;
      case NotificationType.abandonne:         return Icons.replay_rounded;
      case NotificationType.rejete:            return Icons.replay_rounded;
      case NotificationType.nouveauMembre:     return Icons.person_add_alt_rounded;
      case NotificationType.actionOrganisee:   return Icons.campaign_rounded;
      case NotificationType.actionRappel:      return Icons.calendar_today_rounded;
      case NotificationType.nouveauBadge:      return Icons.military_tech_rounded;
      case NotificationType.nouvelleAction:    return Icons.bolt_rounded;
      case NotificationType.commentaireAction: return Icons.chat_bubble_outline_rounded;
      case NotificationType.nouveauParticipant: return Icons.person_add_alt_rounded;
      case NotificationType.casSuiviMisAJour: return Icons.notifications_active_rounded;
    }
  }

  // Couleurs exclusivement issues de CliinAppColors — infoBlue/accentPurple
  // ajoutées à la palette (absentes jusqu'ici), le reste réutilise des
  // couleurs déjà définies (alertOrange, primary).
  Color get color {
    switch (this) {
      case NotificationType.prisEnCharge:      return CliinAppColors.alertOrange;
      case NotificationType.traite:            return CliinAppColors.primary;
      case NotificationType.conteste:          return CliinAppColors.alertOrange;
      case NotificationType.commentaire:       return CliinAppColors.infoBlue;
      case NotificationType.delaiExpire:       return CliinAppColors.alertOrange;
      case NotificationType.preuveRejetee:     return CliinAppColors.accentPurple;
      case NotificationType.abandonne:         return CliinAppColors.alertOrange;
      case NotificationType.rejete:            return CliinAppColors.alertOrange;
      case NotificationType.nouveauMembre:     return CliinAppColors.primary;
      case NotificationType.actionOrganisee:   return CliinAppColors.accentPurple;
      case NotificationType.actionRappel:      return CliinAppColors.infoBlue;
      case NotificationType.nouveauBadge:      return CliinAppColors.infoBlue;
      case NotificationType.nouvelleAction:    return CliinAppColors.primary;
      case NotificationType.commentaireAction: return CliinAppColors.infoBlue;
      case NotificationType.nouveauParticipant: return CliinAppColors.primary;
      case NotificationType.casSuiviMisAJour: return CliinAppColors.primary;
    }
  }
}

// Sentinel réservé aux données de démonstration du mock (Lot 1) — permet
// de seeder les notifications de démo indépendamment de l'état de
// connexion au moment du chargement (main() appelle les Store.init() une
// seule fois, potentiellement avant toute connexion) ; NotificationStore
// les fait correspondre à l'utilisateur RÉELLEMENT connecté au moment de
// la lecture, jamais à un id inventé. Jamais utilisé par une vraie
// notification (Lot 2), qui porte toujours un vrai destinataireUserId dès
// sa création.
const String kDemoCurrentUserSentinel = '__demo_current_user__';

class NotificationModel {
  final String id;
  final NotificationType type;
  final String titre;
  final String texte;
  final String destinataireUserId;
  final bool lu;
  final DateTime dateCreation;
  // Id de l'élément concerné (cas/action/groupe) — permet la navigation au
  // clic (voir referenceType pour savoir quel écran cible).
  final String? referenceId;
  // "signalement" | "action" | "groupe".
  final String? referenceType;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.texte,
    required this.destinataireUserId,
    this.lu = false,
    required this.dateCreation,
    this.referenceId,
    this.referenceType,
  });

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? titre,
    String? texte,
    String? destinataireUserId,
    bool? lu,
    DateTime? dateCreation,
    String? referenceId,
    String? referenceType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      titre: titre ?? this.titre,
      texte: texte ?? this.texte,
      destinataireUserId: destinataireUserId ?? this.destinataireUserId,
      lu: lu ?? this.lu,
      dateCreation: dateCreation ?? this.dateCreation,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
    );
  }
}
