// lib/shared/widgets/report_stats_comments.dart
//
// Widgets partagés entre ReportDetailPage et IntervenantDetailPage :
// ligne stats (vues/commentaires/partages), section commentaires,
// et barre de commentaire fixe en bas de page.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/report_comment_model.dart';
import '../store/auth_store.dart';
import 'report_card.dart' show buildReportImage;
import 'package:cliinapp/features/auth/auth_guard.dart';

export '../models/report_comment_model.dart';

// ─────────────────────────────────────────────────────────────────
// Construit un commentaire à partir de l'utilisateur connecté —
// utilisé par ReportDetailPage / IntervenantDetailPage au moment de
// l'envoi (voir ReportCommentBar.onSubmit).
// ─────────────────────────────────────────────────────────────────
ReportComment buildCommentFromCurrentUser(String text) {
  final name = AuthStore.instance.currentUser?.username ?? 'Utilisateur';
  final parts = name.trim().split(' ');
  final initials = parts.length >= 2
      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
      : (name.isEmpty ? '?' : name[0].toUpperCase());
  return ReportComment(
    initials: initials,
    name: name,
    time: 'à l\'instant',
    text: text,
    createdAt: DateTime.now(),
    authorAvatarPath: AuthStore.instance.currentUser?.avatarPath,
  );
}

// ─────────────────────────────────────────────────────────────────
// Ligne stats — Vues | Commentaires | Partages
// ─────────────────────────────────────────────────────────────────
class ReportStatsRow extends StatelessWidget {
  final int views;
  final int comments;
  final int shares;
  const ReportStatsRow({
    super.key,
    required this.views,
    required this.comments,
    required this.shares,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border.symmetric(
            horizontal: BorderSide(color: CliinAppColors.divider)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _Stat(icon: Icons.remove_red_eye_outlined, value: views, label: 'Vues'),
        _StatDivider(),
        _Stat(
            icon: Icons.chat_bubble_outline_rounded,
            value: comments,
            label: comments > 1 ? 'Commentaires' : 'Commentaire'),
        _StatDivider(),
        _Stat(
            icon: Icons.reply_rounded,
            value: shares,
            label: 'Partages',
            mirror: true),
      ]),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: 1,
        height: 28,
        color: CliinAppColors.divider,
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final bool mirror;
  const _Stat(
      {required this.icon,
      required this.value,
      required this.label,
      this.mirror = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: mirror
                ? (Matrix4.identity()
                  ..scaleByDouble(-1.0, 1.0, 1.0, 1.0))
                : Matrix4.identity(),
            child: Icon(icon, size: 16, color: CliinAppColors.textDark),
          ),
          const SizedBox(width: 4),
          Text('$value',
              style: CliinAppTextStyles.bodySmall.copyWith(
                  color: CliinAppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(label,
              style: CliinAppTextStyles.bodySmall.copyWith(
                  color: CliinAppColors.textSecondary, fontSize: 10)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────
// Section commentaires
// ─────────────────────────────────────────────────────────────────
class ReportCommentsSection extends StatelessWidget {
  final int count;
  final List<ReportComment> comments;
  const ReportCommentsSection({
    super.key,
    required this.count,
    this.comments = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commentaires ($count)',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CliinAppColors.textDark)),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          Text(
            'Aucun commentaire pour le moment. Soyez le premier à réagir.',
            style: GoogleFonts.inter(
                color: CliinAppColors.textSecondary, fontSize: 12.5),
          )
        else
          for (final c in comments) ...[
            _CommentItem(comment: c),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final ReportComment comment;
  const _CommentItem({required this.comment});

  Widget _buildInitialsCircle() => Center(
        child: Text(comment.initials,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CliinAppColors.primary)),
      );

  @override
  Widget build(BuildContext context) {
    final hasAvatar = comment.authorAvatarPath != null &&
        comment.authorAvatarPath!.isNotEmpty;

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: CliinAppColors.primary, width: 1.5)),
            child: hasAvatar
                ? ClipOval(
                    child: buildReportImage(
                      comment.authorAvatarPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildInitialsCircle(),
                    ),
                  )
                : _buildInitialsCircle(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(comment.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: CliinAppColors.textDark,
                          fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(comment.time,
                      style: GoogleFonts.inter(
                          color: CliinAppColors.textSecondary,
                          fontSize: 9.5)),
                ]),
                const SizedBox(height: 3),
                Text(comment.text,
                    style: GoogleFonts.inter(
                        color: CliinAppColors.textDark,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      );
  }
}

// ─────────────────────────────────────────────────────────────────
// Barre de commentaire fixe en bas
// ─────────────────────────────────────────────────────────────────
class ReportCommentBar extends StatefulWidget {
  // Appelé avec le texte saisi une fois l'envoi confirmé — au parent
  // (ReportDetailPage / IntervenantDetailPage) de persister le
  // commentaire via ReportStore.addComment().
  final Future<void> Function(String text) onSubmit;
  const ReportCommentBar({super.key, required this.onSubmit});

  @override
  State<ReportCommentBar> createState() => _ReportCommentBarState();
}

class _ReportCommentBarState extends State<ReportCommentBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _composing = false;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Tout utilisateur connecté peut commenter (y compris l'auteur du cas
  // sur son propre signalement) — seul un compte authentifié est requis.
  Future<void> _startComposing() async {
    if (!await requireAuth(context)) return;
    if (!mounted) return;
    setState(() => _composing = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  Future<void> _send() async {
    if (!_composing) {
      await _startComposing();
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await widget.onSubmit(text);
      _controller.clear();
      if (mounted) setState(() => _composing = false);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: CliinAppColors.cardWhite,
          border: Border(top: BorderSide(color: CliinAppColors.divider)),
        ),
        child: Row(children: [
          Expanded(
            child: _composing
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CliinAppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: null,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: CliinAppColors.textDark),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        hintText: 'Ajouter un commentaire...',
                        hintStyle: GoogleFonts.inter(
                            color: CliinAppColors.textSecondary,
                            fontSize: 12),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _startComposing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: CliinAppColors.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text('Ajouter un commentaire...',
                          style: GoogleFonts.inter(
                              color: CliinAppColors.textSecondary,
                              fontSize: 12)),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: CliinAppColors.primary, shape: BoxShape.circle),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: CliinAppColors.textWhite, size: 16),
            ),
          ),
        ]),
      ),
    );
  }
}
