// lib/shared/models/report_comment_model.dart

class ReportComment {
  final String id;
  final String initials;
  final String name;
  final String text;
  final DateTime createdAt;
  // Identifiant de l'auteur — permet de résoudre sa photo de profil
  // ACTUELLE à chaque affichage (voir _CommentItem dans
  // report_stats_comments.dart) plutôt que de figer une valeur au moment
  // de la publication : si l'auteur change sa photo plus tard, ses
  // anciens commentaires doivent la refléter.
  final String? authorId;
  // Repli utilisé quand l'auteur n'est pas (ou plus) l'utilisateur
  // courant de la session — l'app ne conservant qu'un seul profil
  // utilisateur local, il n'existe pas d'autre source pour retrouver la
  // photo actuelle d'un tiers. Null/vide -> repli sur les initiales.
  final String? authorAvatarPath;
  final bool edited;

  const ReportComment({
    required this.id,
    required this.initials,
    required this.name,
    required this.text,
    required this.createdAt,
    this.authorId,
    this.authorAvatarPath,
    this.edited = false,
  });

  ReportComment copyWith({String? text, bool? edited}) => ReportComment(
        id: id,
        initials: initials,
        name: name,
        text: text ?? this.text,
        createdAt: createdAt,
        authorId: authorId,
        authorAvatarPath: authorAvatarPath,
        edited: edited ?? this.edited,
      );
}
