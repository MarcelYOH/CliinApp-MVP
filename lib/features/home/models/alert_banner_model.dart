// lib/features/home/models/alert_banner_model.dart

class AlertBannerModel {
  final String badgeLabel;
  final String textLine1;
  final String textLine2Prefix;
  final String textLine2Highlight;
  final String buttonLabel;

  const AlertBannerModel({
    required this.badgeLabel,
    required this.textLine1,
    required this.textLine2Prefix,
    required this.textLine2Highlight,
    required this.buttonLabel,
  });
}