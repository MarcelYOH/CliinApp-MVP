// lib/features/home/models/group_model.dart

// Ordre d'affichage fixe des badges de niveau, quel que soit l'ordre
// dans lequel ils sont fournis par GroupModel.levelBadges.
const List<String> kGroupLevelOrder = ['Engagé', 'Impact', 'Officiel'];

class GroupModel {
  final String name;
  final String location;
  final String? description;
  final int membersCount;
  final int actionsCount;
  final String bannerAsset;
  final String? avatarAsset;   // photo réelle de l'avatar rond (optionnel)
  final String? logoText;      // texte dans le cercle si pas de photo (ex: "Clean\nRivera")
  final bool hasLeafIcon;      // true = icône feuille au lieu du texte
  final bool isActive;
  final List<String> levelBadges;       // ex: ['Engagé'], ['Impact', 'Officiel']
  final List<String> leaderAvatarAssets; // avatars de l'équipe dirigeante (jusqu'à 4 affichés)

  const GroupModel({
    required this.name,
    required this.location,
    this.description,
    required this.membersCount,
    required this.actionsCount,
    required this.bannerAsset,
    this.avatarAsset,
    this.logoText,
    this.hasLeafIcon = false,
    this.isActive = true,
    this.levelBadges = const [],
    this.leaderAvatarAssets = const [],
  });
}

// ─────────────────────────────────────────────────────────────────
// LOGIQUE MÉTIER — sélection des groupes selon leur niveau de badges
// (Engagé / Impact / Officiel). Basée sur des données factices pour
// l'instant, mais la règle ci-dessous est la règle métier validée à
// appliquer telle quelle une fois le calcul réel des badges par
// groupe branché sur de vraies données.
// ─────────────────────────────────────────────────────────────────

// Aperçu "Groupes actifs" de la page d'accueil : section très
// sélective, réservée aux groupes ayant validé les 3 badges à la fois
// (Engagé + Impact + Officiel) — preuve d'un impact terrain complet.
// Si moins de 3 groupes remplissent cette condition, on affiche
// uniquement ceux-là : jamais de groupe à 1 ou 2 badges en remplacement.
List<GroupModel> selectFeaturedGroups(List<GroupModel> groups) {
  return groups
      .where((g) => kGroupLevelOrder.every(g.levelBadges.contains))
      .toList();
}

// Page dédiée "Groupes actifs" (module Groupes — page principale et
// recherche, pas encore construites) : logique plus large que
// l'aperçu accueil — d'abord les groupes à 3 badges, puis les groupes
// à 2 badges (peu importe lesquels), triés du plus au moins complet.
// Les groupes à 1 seul badge n'apparaissent jamais dans cette section :
// ils ne sont pas encore considérés comme suffisamment actifs.
List<GroupModel> selectActiveGroupsForGroupsPage(List<GroupModel> groups) {
  final eligible = groups.where((g) => g.levelBadges.length >= 2).toList()
    ..sort((a, b) => b.levelBadges.length.compareTo(a.levelBadges.length));
  return eligible;
}