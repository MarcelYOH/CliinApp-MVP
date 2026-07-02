// lib/shared/widgets/report_stats_comments.dart
//
// Widgets partagés entre ReportDetailPage et IntervenantDetailPage :
// ligne stats (vues/commentaires/partages), section commentaires,
// et barre de commentaire fixe en bas de page.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:cliinapp/features/auth/auth_guard.dart';

// ─────────────────────────────────────────────────────────────────
// Mock commentaires pour la démo
// ─────────────────────────────────────────────────────────────────
class ReportComment {
  final String initials;
  final String name;
  final String time;
  final String text;
  const ReportComment(
      {required this.initials,
      required this.name,
      required this.time,
      required this.text});
}

const List<ReportComment> kMockReportComments = [
  ReportComment(
      initials: 'AK',
      name: 'Awa K.',
      time: 'il y a 2h',
      text: 'C\'est vraiment urgent, ça pue jusqu\'à chez moi. '
          'Merci à celui qui prendra ça en charge !'),
  ReportComment(
      initials: 'BT',
      name: 'Bakary T.',
      time: 'il y a 5h',
      text: 'Même problème dans ma rue, j\'espère qu\'on aura '
          'une vraie solution durable.'),
  ReportComment(
      initials: 'MY',
      name: 'Marcel Y.',
      time: 'il y a 1j',
      text: 'J\'ai signalé ça plusieurs fois. '
          'Content que quelqu\'un prenne enfin ça en main.'),
];

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
    this.comments = kMockReportComments,
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

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: CliinAppColors.primary, width: 1.5)),
            child: Center(
              child: Text(comment.initials,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CliinAppColors.primary)),
            ),
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

// ─────────────────────────────────────────────────────────────────
// Barre de commentaire fixe en bas
// ─────────────────────────────────────────────────────────────────
class ReportCommentBar extends StatelessWidget {
  const ReportCommentBar({super.key});

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
            child: GestureDetector(
              onTap: () async {
                await requireAuth(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: CliinAppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('Ajouter un commentaire...',
                    style: GoogleFonts.inter(
                        color: CliinAppColors.textSecondary, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              await requireAuth(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: CliinAppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded,
                  color: CliinAppColors.textWhite, size: 16),
            ),
          ),
        ]),
      ),
    );
  }
}
