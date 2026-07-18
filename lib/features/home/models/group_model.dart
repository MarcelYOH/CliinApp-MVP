// lib/features/home/models/group_model.dart

class GroupModel {
  final String name;
  final String location;
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