// lib/features/home/models/action_banner_model.dart

class ActionBannerModel {
  final String badgeLabel;
  final String title;
  final String description;
  final String buttonLabel;
  final String imageAsset;

  const ActionBannerModel({
    required this.badgeLabel,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.imageAsset,
  });
}