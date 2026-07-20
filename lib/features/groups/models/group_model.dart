// lib/features/groups/models/group_model.dart

enum GroupType { ong, association, benevoles, autre }

extension GroupTypeLabel on GroupType {
  String get label => switch (this) {
        GroupType.ong => 'ONG',
        GroupType.association => 'Association',
        GroupType.benevoles => 'Groupe de bénévoles',
        GroupType.autre => 'Autre',
      };
}

// ─────────────────────────────────────────────────────────────────
// Seuils des badges de niveau — validés, ne PAS considérer comme
// provisoires. Un groupe obtient un badge dès qu'il remplit LES 3
// conditions du palier correspondant (pas une moyenne, pas un cumul
// global unique) ; plusieurs badges peuvent être actifs simultanément
// (ex: 250 signalés / 120 traités / 25 actions => Engagé + Impact +
// Officiel en même temps).
//
//                    casSignalesCount   casTraitesCount   actionsCount
//   Engagé   (1er)          ≥ 10              ≥ 5             ≥ 1
//   Impact   (2e)           ≥ 50              ≥ 30             ≥ 5
//   Officiel (3e)           ≥ 200             ≥ 100            ≥ 20
// ─────────────────────────────────────────────────────────────────
List<String> calculateGroupBadges({
  required int casSignalesCount,
  required int casTraitesCount,
  required int actionsCount,
}) {
  final badges = <String>[];
  if (casSignalesCount >= 10 && casTraitesCount >= 5 && actionsCount >= 1) {
    badges.add('engage');
  }
  if (casSignalesCount >= 50 && casTraitesCount >= 30 && actionsCount >= 5) {
    badges.add('impact');
  }
  if (casSignalesCount >= 200 && casTraitesCount >= 100 && actionsCount >= 20) {
    badges.add('officiel');
  }
  return badges;
}

/// Groupe (ONG, association, collectif de bénévoles...) — module Groupes.
///
/// [description] alimente directement la section "Qui sommes-nous" du
/// profil du groupe : c'est le texte saisi à la création, jamais dupliqué
/// ailleurs. [missionTexte] est un champ totalement distinct ("Notre
/// mission"), rempli séparément depuis le profil (voir Lot 3).
class GroupModel {
  final String id;
  final String nom;
  final String? photoPath;
  // Photo de bannière/couverture (rectangulaire) — distincte de [photoPath]
  // (logo, cercle). Affichée en arrière-plan partout où le groupe apparaît
  // (GroupCard, GroupProfilePage) ; null = dégradé de repli habituel.
  final String? bannerPath;
  // Ajustement vertical choisi par l'utilisateur après upload (recadrage
  // simple) — -1.0 (haut de la photo) à 1.0 (bas), 0.0 = centre. Appliqué
  // comme Alignment partout où la photo correspondante est affichée en
  // BoxFit.cover, pour éviter qu'un cadrage par défaut mal choisi reste
  // figé sans possibilité de correction.
  final double photoAlignY;
  final double bannerAlignY;
  final String description;
  final GroupType type;
  final String zone;
  // Coordonnées GPS réelles capturées au moment où [zone] a été détectée
  // automatiquement (création ou nouvelle détection en modification) —
  // jamais devinées à partir du texte. Restent null tant qu'aucune
  // détection GPS n'a eu lieu (ex: groupes créés avant l'ajout de ce
  // champ) ; alimentent le tri "Plus proches" (Lot 5), jamais de distance
  // inventée pour un groupe sans coordonnées.
  final double? latitude;
  final double? longitude;
  // Sous-ensemble de ["engage", "impact", "officiel"] — calculé
  // automatiquement par GroupStore.recalculerBadges(), jamais saisi.
  final List<String> badges;
  final bool estActif;
  final DateTime createdAt;
  final String createurId;

  // ── "À propos" — éditable uniquement depuis le profil (Lot 3) ──────
  final String? missionTexte;
  final String? activitesClesTexte;
  final String? besoinCommunication;
  final String? besoinBenevoles;
  final String? besoinFinancement;
  final String? besoinMateriel;

  // ── "Notre impact" — mis à jour automatiquement par les événements
  // réels de l'application, jamais saisi manuellement ──────────────
  final int casSignalesCount;
  final int casTraitesCount;
  final int casPrisEnChargeCount;
  final int actionsCount;

  // Le créateur compte comme premier membre dès la création.
  final int sympathisantsCount;

  const GroupModel({
    required this.id,
    required this.nom,
    this.photoPath,
    this.bannerPath,
    this.photoAlignY = 0.0,
    this.bannerAlignY = 0.0,
    required this.description,
    required this.type,
    required this.zone,
    this.latitude,
    this.longitude,
    this.badges = const [],
    this.estActif = false,
    required this.createdAt,
    required this.createurId,
    this.missionTexte,
    this.activitesClesTexte,
    this.besoinCommunication,
    this.besoinBenevoles,
    this.besoinFinancement,
    this.besoinMateriel,
    this.casSignalesCount = 0,
    this.casTraitesCount = 0,
    this.casPrisEnChargeCount = 0,
    this.actionsCount = 0,
    this.sympathisantsCount = 1,
  });

  GroupModel copyWith({
    String? id,
    String? nom,
    String? photoPath,
    String? bannerPath,
    double? photoAlignY,
    double? bannerAlignY,
    String? description,
    GroupType? type,
    String? zone,
    double? latitude,
    double? longitude,
    List<String>? badges,
    bool? estActif,
    DateTime? createdAt,
    String? createurId,
    String? missionTexte,
    String? activitesClesTexte,
    String? besoinCommunication,
    String? besoinBenevoles,
    String? besoinFinancement,
    String? besoinMateriel,
    int? casSignalesCount,
    int? casTraitesCount,
    int? casPrisEnChargeCount,
    int? actionsCount,
    int? sympathisantsCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      photoPath: photoPath ?? this.photoPath,
      bannerPath: bannerPath ?? this.bannerPath,
      photoAlignY: photoAlignY ?? this.photoAlignY,
      bannerAlignY: bannerAlignY ?? this.bannerAlignY,
      description: description ?? this.description,
      type: type ?? this.type,
      zone: zone ?? this.zone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      badges: badges ?? this.badges,
      estActif: estActif ?? this.estActif,
      createdAt: createdAt ?? this.createdAt,
      createurId: createurId ?? this.createurId,
      missionTexte: missionTexte ?? this.missionTexte,
      activitesClesTexte: activitesClesTexte ?? this.activitesClesTexte,
      besoinCommunication: besoinCommunication ?? this.besoinCommunication,
      besoinBenevoles: besoinBenevoles ?? this.besoinBenevoles,
      besoinFinancement: besoinFinancement ?? this.besoinFinancement,
      besoinMateriel: besoinMateriel ?? this.besoinMateriel,
      casSignalesCount: casSignalesCount ?? this.casSignalesCount,
      casTraitesCount: casTraitesCount ?? this.casTraitesCount,
      casPrisEnChargeCount: casPrisEnChargeCount ?? this.casPrisEnChargeCount,
      actionsCount: actionsCount ?? this.actionsCount,
      sympathisantsCount: sympathisantsCount ?? this.sympathisantsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'photoPath': photoPath,
        'bannerPath': bannerPath,
        'photoAlignY': photoAlignY,
        'bannerAlignY': bannerAlignY,
        'description': description,
        'type': type.name,
        'zone': zone,
        'latitude': latitude,
        'longitude': longitude,
        'badges': badges,
        'estActif': estActif,
        'createdAt': createdAt.toIso8601String(),
        'createurId': createurId,
        'missionTexte': missionTexte,
        'activitesClesTexte': activitesClesTexte,
        'besoinCommunication': besoinCommunication,
        'besoinBenevoles': besoinBenevoles,
        'besoinFinancement': besoinFinancement,
        'besoinMateriel': besoinMateriel,
        'casSignalesCount': casSignalesCount,
        'casTraitesCount': casTraitesCount,
        'casPrisEnChargeCount': casPrisEnChargeCount,
        'actionsCount': actionsCount,
        'sympathisantsCount': sympathisantsCount,
      };

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        nom: json['nom'] as String,
        photoPath: json['photoPath'] as String?,
        bannerPath: json['bannerPath'] as String?,
        photoAlignY: (json['photoAlignY'] as num?)?.toDouble() ?? 0.0,
        bannerAlignY: (json['bannerAlignY'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String,
        type: GroupType.values.byName(json['type'] as String),
        zone: json['zone'] as String,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        badges: (json['badges'] as List).cast<String>(),
        estActif: json['estActif'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createurId: json['createurId'] as String,
        missionTexte: json['missionTexte'] as String?,
        activitesClesTexte: json['activitesClesTexte'] as String?,
        besoinCommunication: json['besoinCommunication'] as String?,
        besoinBenevoles: json['besoinBenevoles'] as String?,
        besoinFinancement: json['besoinFinancement'] as String?,
        besoinMateriel: json['besoinMateriel'] as String?,
        casSignalesCount: json['casSignalesCount'] as int,
        casTraitesCount: json['casTraitesCount'] as int,
        casPrisEnChargeCount: json['casPrisEnChargeCount'] as int,
        actionsCount: json['actionsCount'] as int,
        sympathisantsCount: json['sympathisantsCount'] as int,
      );
}

/// Membre du groupe — TOUJOURS un administrateur (estAdmin == true pour
/// tout élément de cette liste). Rappel logique métier : tout
/// administrateur peut gérer TOUS les cas rattachés au groupe, peu importe
/// qui les a signalés/pris en charge — pas de cloisonnement par créateur
/// individuel.
///
/// [estBureauExecutif] true = poste officiel ([role] renseigné), apparaît
/// dans "Notre équipe" du profil. false = administrateur délégué, visible
/// uniquement dans l'Espace gestion, absent de "Notre équipe".
class GroupMemberModel {
  final String id;
  final String nom;
  final String? avatarPath;
  final String? role;
  final bool estAdmin;
  final bool estBureauExecutif;

  const GroupMemberModel({
    required this.id,
    required this.nom,
    this.avatarPath,
    this.role,
    this.estAdmin = true,
    this.estBureauExecutif = false,
  });

  GroupMemberModel copyWith({
    String? id,
    String? nom,
    String? avatarPath,
    String? role,
    bool? estAdmin,
    bool? estBureauExecutif,
  }) {
    return GroupMemberModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      avatarPath: avatarPath ?? this.avatarPath,
      role: role ?? this.role,
      estAdmin: estAdmin ?? this.estAdmin,
      estBureauExecutif: estBureauExecutif ?? this.estBureauExecutif,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'avatarPath': avatarPath,
        'role': role,
        'estAdmin': estAdmin,
        'estBureauExecutif': estBureauExecutif,
      };

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      GroupMemberModel(
        id: json['id'] as String,
        nom: json['nom'] as String,
        avatarPath: json['avatarPath'] as String?,
        role: json['role'] as String?,
        estAdmin: json['estAdmin'] as bool,
        estBureauExecutif: json['estBureauExecutif'] as bool,
      );
}
