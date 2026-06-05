// lib/features/home/models/group_model.dart

class GroupModel {
  final String name;
  final String location;
  final int membersCount;
  final int actionsCount;
  final String bannerAsset;
  final String? logoText;      // texte dans le cercle (ex: "Clean\nRivera")
  final bool hasLeafIcon;      // true = icône feuille au lieu du texte
  final bool isActive;

  const GroupModel({
    required this.name,
    required this.location,
    required this.membersCount,
    required this.actionsCount,
    required this.bannerAsset,
    this.logoText,
    this.hasLeafIcon = false,
    this.isActive = true,
  });
}