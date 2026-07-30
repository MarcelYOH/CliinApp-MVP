// lib/features/actions/models/action_model.dart
// Module Actions Terrain — Lot 1/3 : structure de données.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/report_comment_model.dart';

enum ActionType {
  nettoyage,
  collecte,
  curage,
  depotsSauvages,
  sensibilisationProximite,
  sensibilisationPublique,
  quartierPropre,
  ruePropre,
  marchePropre,
  ecolePropre,
  garePropre,
  plagePropre,
  operationSignalement,
}

extension ActionTypeExt on ActionType {
  String get label {
    switch (this) {
      case ActionType.nettoyage:                return 'Nettoyage communautaire';
      case ActionType.collecte:                 return 'Collecte des déchets';
      case ActionType.curage:                   return 'Curage des caniveaux';
      case ActionType.depotsSauvages:            return 'Élimination des dépôts sauvages';
      case ActionType.sensibilisationProximite:  return 'Sensibilisation de proximité';
      case ActionType.sensibilisationPublique:   return 'Sensibilisation publique';
      case ActionType.quartierPropre:            return 'Opération Quartier propre';
      case ActionType.ruePropre:                 return 'Opération Rue propre';
      case ActionType.marchePropre:              return 'Opération Marché propre';
      case ActionType.ecolePropre:               return 'Opération École propre';
      case ActionType.garePropre:                return 'Opération Gare propre';
      case ActionType.plagePropre:               return 'Opération Plage propre';
      case ActionType.operationSignalement:      return 'Opération de signalement';
    }
  }

  IconData get icon {
    switch (this) {
      case ActionType.nettoyage:                return Icons.cleaning_services_rounded;
      case ActionType.collecte:                 return Icons.recycling_rounded;
      case ActionType.curage:                    return Icons.water_damage_rounded;
      case ActionType.depotsSauvages:            return Icons.delete_forever_rounded;
      case ActionType.sensibilisationProximite:  return Icons.campaign_rounded;
      case ActionType.sensibilisationPublique:   return Icons.record_voice_over_rounded;
      case ActionType.quartierPropre:            return Icons.location_city_rounded;
      case ActionType.ruePropre:                 return Icons.signpost_rounded;
      case ActionType.marchePropre:              return Icons.storefront_rounded;
      case ActionType.ecolePropre:               return Icons.school_rounded;
      case ActionType.garePropre:                return Icons.train_rounded;
      case ActionType.plagePropre:               return Icons.beach_access_rounded;
      case ActionType.operationSignalement:      return Icons.flag_rounded;
    }
  }

  // Couleurs exclusivement issues de CliinAppColors (aucune valeur hex
  // inventée) — levelEngage (violet) et levelOfficiel (bleu) existent déjà
  // (badges de niveau groupe) et sont réutilisées ici comme teintes
  // "distincte"/"informative", conformément à la règle : ne proposer une
  // nouvelle constante que si aucune couleur adéquate n'existe déjà.
  Color get color {
    switch (this) {
      case ActionType.nettoyage:                return CliinAppColors.primary;
      case ActionType.collecte:                 return CliinAppColors.levelOfficiel;
      case ActionType.curage:                    return CliinAppColors.alertOrange;
      case ActionType.depotsSauvages:            return CliinAppColors.alertRed;
      case ActionType.sensibilisationProximite:  return CliinAppColors.levelEngage;
      case ActionType.sensibilisationPublique:   return CliinAppColors.levelEngage;
      case ActionType.quartierPropre:            return CliinAppColors.primary;
      case ActionType.ruePropre:                 return CliinAppColors.primary;
      case ActionType.marchePropre:              return CliinAppColors.alertOrange;
      case ActionType.ecolePropre:               return CliinAppColors.levelOfficiel;
      case ActionType.garePropre:                return CliinAppColors.levelOfficiel;
      case ActionType.plagePropre:               return CliinAppColors.levelOfficiel;
      case ActionType.operationSignalement:      return CliinAppColors.alertRed;
    }
  }
}

enum ActionStatus { aVenir, enCours, terminee }

extension ActionStatusExt on ActionStatus {
  String get label {
    switch (this) {
      case ActionStatus.aVenir:   return 'À venir';
      case ActionStatus.enCours:  return 'En cours';
      case ActionStatus.terminee: return 'Terminée';
    }
  }

  // Fond plein et vif (couleur solide, pas de teinte pâle) pour rester
  // lisible en plein soleil — le texte du badge (color) est donc blanc.
  Color get bgColor {
    switch (this) {
      case ActionStatus.aVenir:   return CliinAppColors.primary;
      case ActionStatus.enCours:  return CliinAppColors.primary;
      case ActionStatus.terminee: return CliinAppColors.textSecondary;
    }
  }

  Color get color {
    switch (this) {
      case ActionStatus.aVenir:   return CliinAppColors.textWhite;
      case ActionStatus.enCours:  return CliinAppColors.textWhite;
      case ActionStatus.terminee: return CliinAppColors.textWhite;
    }
  }
}

/// Une action terrain (nettoyage, collecte, sensibilisation...) organisée
/// par un individu ou un groupe — module Actions Terrain.
class ActionModel {
  final String id;
  final ActionType type;
  final DateTime date;
  final String lieu;
  final double? latitude;
  final double? longitude;
  final String? description;
  // Photo miniature affichée sur ActionCard (voir Partie 3) — absente de la
  // liste de champs du Lot 1 mais nécessaire à la carte demandée dans ce
  // même lot ; null tant qu'aucune photo n'a été prise (formulaire de
  // création, Lot 3) — un dégradé de repli teinté selon le type est utilisé
  // dans ce cas, jamais une image inventée.
  final String? photoPath;
  final int participantsCount;
  final ActionStatus statut;
  final String organisateurNom;
  final String organisateurId;
  final bool organisateurEstGroupe;
  final bool isAnonyme;
  final List<String> casPrisEnChargeIds;
  final DateTime createdAt;
  final int viewsCount;
  final int commentsCount;
  final int sharesCount;
  // Anti-abus "vues" — un utilisateur (autre que l'organisateur) ne compte
  // qu'une seule fois dans viewsCount, quel que soit le nombre d'ouvertures
  // de la page de détail (même logique que HomeReportModel.viewedByUserIds).
  final List<String> viewedByUserIds;
  final List<ReportComment> commentsList;
  // Besoins ponctuels de cette action — mêmes 4 champs et mêmes noms que
  // GroupModel.besoinXxx (Nos besoins, module Groupes), saisis à la
  // création (Lot 3). Section "Besoins pour cette action" (Lot 2)
  // entièrement absente si les 4 sont null/vides.
  final String? besoinCommunication;
  final String? besoinBenevoles;
  final String? besoinFinancement;
  final String? besoinMateriel;

  const ActionModel({
    required this.id,
    required this.type,
    required this.date,
    required this.lieu,
    this.latitude,
    this.longitude,
    this.description,
    this.photoPath,
    this.participantsCount = 0,
    this.statut = ActionStatus.aVenir,
    required this.organisateurNom,
    required this.organisateurId,
    this.organisateurEstGroupe = false,
    this.isAnonyme = false,
    this.casPrisEnChargeIds = const [],
    required this.createdAt,
    this.viewsCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewedByUserIds = const [],
    this.commentsList = const [],
    this.besoinCommunication,
    this.besoinBenevoles,
    this.besoinFinancement,
    this.besoinMateriel,
  });

  ActionModel copyWith({
    String? id,
    ActionType? type,
    DateTime? date,
    String? lieu,
    double? latitude,
    double? longitude,
    String? description,
    String? photoPath,
    int? participantsCount,
    ActionStatus? statut,
    String? organisateurNom,
    String? organisateurId,
    bool? organisateurEstGroupe,
    bool? isAnonyme,
    List<String>? casPrisEnChargeIds,
    DateTime? createdAt,
    int? viewsCount,
    int? commentsCount,
    int? sharesCount,
    List<String>? viewedByUserIds,
    List<ReportComment>? commentsList,
    String? besoinCommunication,
    String? besoinBenevoles,
    String? besoinFinancement,
    String? besoinMateriel,
  }) {
    return ActionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      lieu: lieu ?? this.lieu,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      participantsCount: participantsCount ?? this.participantsCount,
      statut: statut ?? this.statut,
      organisateurNom: organisateurNom ?? this.organisateurNom,
      organisateurId: organisateurId ?? this.organisateurId,
      organisateurEstGroupe: organisateurEstGroupe ?? this.organisateurEstGroupe,
      isAnonyme: isAnonyme ?? this.isAnonyme,
      casPrisEnChargeIds: casPrisEnChargeIds ?? this.casPrisEnChargeIds,
      createdAt: createdAt ?? this.createdAt,
      viewsCount: viewsCount ?? this.viewsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewedByUserIds: viewedByUserIds ?? this.viewedByUserIds,
      commentsList: commentsList ?? this.commentsList,
      besoinCommunication: besoinCommunication ?? this.besoinCommunication,
      besoinBenevoles: besoinBenevoles ?? this.besoinBenevoles,
      besoinFinancement: besoinFinancement ?? this.besoinFinancement,
      besoinMateriel: besoinMateriel ?? this.besoinMateriel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'date': date.toIso8601String(),
    'lieu': lieu,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'photoPath': photoPath,
    'participantsCount': participantsCount,
    'statut': statut.name,
    'organisateurNom': organisateurNom,
    'organisateurId': organisateurId,
    'organisateurEstGroupe': organisateurEstGroupe,
    'isAnonyme': isAnonyme,
    'casPrisEnChargeIds': casPrisEnChargeIds,
    'createdAt': createdAt.toIso8601String(),
    'viewsCount': viewsCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'viewedByUserIds': viewedByUserIds,
    // commentsList non sérialisé : ReportComment n'a pas encore de
    // toJson/fromJson (idem HomeReportModel.commentsList) — pas de backend
    // persistant pour l'instant, uniquement l'état en mémoire du repository.
    'besoinCommunication': besoinCommunication,
    'besoinBenevoles': besoinBenevoles,
    'besoinFinancement': besoinFinancement,
    'besoinMateriel': besoinMateriel,
  };

  factory ActionModel.fromJson(Map<String, dynamic> json) => ActionModel(
    id: json['id'],
    type: ActionType.values.firstWhere((e) => e.name == json['type']),
    date: DateTime.parse(json['date']),
    lieu: json['lieu'],
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    description: json['description'],
    photoPath: json['photoPath'],
    participantsCount: json['participantsCount'] ?? 0,
    statut: json['statut'] != null
        ? ActionStatus.values.firstWhere((e) => e.name == json['statut'])
        : ActionStatus.aVenir,
    organisateurNom: json['organisateurNom'],
    organisateurId: json['organisateurId'],
    organisateurEstGroupe: json['organisateurEstGroupe'] ?? false,
    isAnonyme: json['isAnonyme'] ?? false,
    casPrisEnChargeIds: (json['casPrisEnChargeIds'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    createdAt: DateTime.parse(json['createdAt']),
    viewsCount: json['viewsCount'] ?? 0,
    commentsCount: json['commentsCount'] ?? 0,
    sharesCount: json['sharesCount'] ?? 0,
    viewedByUserIds: (json['viewedByUserIds'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    besoinCommunication: json['besoinCommunication'],
    besoinBenevoles: json['besoinBenevoles'],
    besoinFinancement: json['besoinFinancement'],
    besoinMateriel: json['besoinMateriel'],
  );
}
