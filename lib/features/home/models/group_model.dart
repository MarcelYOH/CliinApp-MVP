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

// Aperçu "Groupes actifs" de l'accueil : priorité aux groupes qui ont
// validé les 3 badges à la fois. Si aucun n'en a 3, on retombe sur les
// groupes les plus complets, triés du plus au moins de badges validés.
List<GroupModel> selectFeaturedGroups(List<GroupModel> groups) {
  final complete = groups
      .where((g) => kGroupLevelOrder.every(g.levelBadges.contains))
      .toList();
  if (complete.isNotEmpty) return complete;

  final sorted = [...groups]
    ..sort((a, b) => b.levelBadges.length.compareTo(a.levelBadges.length));
  return sorted;
}