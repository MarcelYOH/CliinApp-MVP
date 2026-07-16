// lib/shared/models/report_comment_model.dart

class ReportComment {
  final String initials;
  final String name;
  final String time;
  final String text;
  final DateTime createdAt;
  // Photo de profil de l'auteur AU MOMENT du commentaire (chemin local ou
  // URL) — capturée à la création plutôt que résolue dynamiquement, pour
  // que chaque commentaire garde la bonne photo même si l'auteur change
  // ensuite la sienne. Null/vide -> repli sur les initiales.
  final String? authorAvatarPath;

  const ReportComment({
    required this.initials,
    required this.name,
    required this.time,
    required this.text,
    required this.createdAt,
    this.authorAvatarPath,
  });
}
