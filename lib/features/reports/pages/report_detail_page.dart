// lib/features/reports/pages/report_detail_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../../features/home/models/home_report_model.dart';
import '../../../shared/widgets/report_card.dart'
    show buildReportImage, reportTimeAgoLabel, copyReportCode;
import '../../../shared/widgets/report_action_zone.dart';
import 'intervenant_detail_page.dart';
import '../../auth/auth_guard.dart';
import '../widgets/take_charge_flow.dart';

// ─────────────────────────────────────────────────────────────────
// Mock commentaires pour la démo
// ─────────────────────────────────────────────────────────────────
const List<_MockComment> _kMockComments = [
  _MockComment(
      initials: 'AK',
      name: 'Awa K.',
      time: 'il y a 2h',
      text: 'C\'est vraiment urgent, ça pue jusqu\'à chez moi. '
          'Merci à celui qui prendra ça en charge !'),
  _MockComment(
      initials: 'BT',
      name: 'Bakary T.',
      time: 'il y a 5h',
      text: 'Même problème dans ma rue, j\'espère qu\'on aura '
          'une vraie solution durable.'),
  _MockComment(
      initials: 'MY',
      name: 'Marcel Y.',
      time: 'il y a 1j',
      text: 'J\'ai signalé ça plusieurs fois. '
          'Content que quelqu\'un prenne enfin ça en main.'),
];

class _MockComment {
  final String initials;
  final String name;
  final String time;
  final String text;
  const _MockComment(
      {required this.initials,
      required this.name,
      required this.time,
      required this.text});
}

// ─────────────────────────────────────────────────────────────────
// Page principale
// ─────────────────────────────────────────────────────────────────
class ReportDetailPage extends StatefulWidget {
  final HomeReportModel data;

  const ReportDetailPage({super.key, required this.data});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  // Toggle démo pour afficher/masquer le bouton Contacter (en cours)
  bool _demoShowContact = false;

  HomeReportModel get _effectiveData {
    if (widget.data.status != ReportStatus.enCours ||
        widget.data.intervenant == null) {
      return widget.data;
    }
    return widget.data.copyWith(
      intervenant: widget.data.intervenant!.copyWith(
        whatsAppVisible: _demoShowContact,
        whatsAppNumber:
            _demoShowContact ? '+2250700000000' : null,
      ),
    );
  }

  void _onTakeCharge() async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      showTakeChargeFlow(
        context: context,
        report: widget.data,
        onSuccess: (updated) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => IntervenantDetailPage(report: updated),
              ),
            );
          }
        },
      );
    }
  }

  void _onContact() {
    openWhatsApp(
      context: context,
      intervenant: _effectiveData.intervenant,
    );
  }

  void _onIntervenantTap() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) =>
              IntervenantDetailPage(report: widget.data)),
    );
  }

  void _onShare() {
    copyReportCode(context, widget.data.reference);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailPhotoSection(data: widget.data),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        CliinAppConstants.pagePadding,
                        CliinAppConstants.pagePadding,
                        CliinAppConstants.pagePadding,
                        0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleRow(),
                        const SizedBox(height: 4),
                        _buildLocationRow(),
                        const SizedBox(height: 16),
                        _buildDescriptionCard(),
                        const SizedBox(height: 16),
                        ReportActionZone(
                          key: ValueKey(
                              '${widget.data.id}-${_demoShowContact}'),
                          data: _effectiveData,
                          compact: false,
                          onTakeCharge: _onTakeCharge,
                          onContact: _onContact,
                          onIntervenantTap: _onIntervenantTap,
                        ),
                        // Lien démo bascule contact (en cours uniquement)
                        if (widget.data.status == ReportStatus.enCours &&
                            widget.data.intervenant != null) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _demoShowContact = !_demoShowContact),
                              child: Text(
                                _demoShowContact
                                    ? '(démo) masquer le contact'
                                    : '(démo) basculer : contact renseigné',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: CliinAppColors.textSecondary,
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      CliinAppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: CliinAppColors.divider),
                        const SizedBox(height: 16),
                        _buildStatsRow(),
                        const SizedBox(height: 16),
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: CliinAppColors.divider),
                        const SizedBox(height: 16),
                        _buildCommentsSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _buildCommentBar(context),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: CliinAppColors.cardWhite,
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: CliinAppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded,
                color: CliinAppColors.textWhite, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Détails du signalement',
              style: CliinAppTextStyles.headingSmall
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        GestureDetector(
          onTap: _onShare,
          child: const Icon(Icons.share_rounded,
              color: CliinAppColors.textDark, size: 22),
        ),
      ]),
    );
  }

  // ── Titre + badge statut ─────────────────────────────────────
  Widget _buildTitleRow() {
    final status = widget.data.status;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(widget.data.title,
              style: CliinAppTextStyles.headingSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A))),
        ),
        const SizedBox(width: 8),
        Text(status.label,
            style: CliinAppTextStyles.badge.copyWith(
                color: status.color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Localisation ─────────────────────────────────────────────
  Widget _buildLocationRow() {
    return Row(children: [
      const Icon(Icons.location_on_rounded,
          color: CliinAppColors.primary, size: 14),
      const SizedBox(width: 4),
      Expanded(
        child: Text(widget.data.location,
            style: CliinAppTextStyles.bodySmall.copyWith(
                color: CliinAppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  // ── Description card ─────────────────────────────────────────
  Widget _buildDescriptionCard() {
    final createdAt = widget.data.createdAt;
    final pubDate = createdAt != null ? _formatPubDate(createdAt) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius:
            BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.data.description,
              style: CliinAppTextStyles.bodySmall.copyWith(
                  color: CliinAppColors.textDark,
                  fontSize: 13,
                  height: 1.5)),
          if (pubDate != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: CliinAppColors.divider),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: CliinAppColors.textSecondary),
              const SizedBox(width: 5),
              Text(pubDate,
                  style: CliinAppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: CliinAppColors.textSecondary)),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final d = widget.data;
    return Row(children: [
      _Stat(icon: Icons.remove_red_eye_outlined, value: d.views, label: 'Vues'),
      const SizedBox(width: 24),
      _Stat(
          icon: Icons.chat_bubble_outline_rounded,
          value: d.comments,
          label: d.comments > 1 ? 'Commentaires' : 'Commentaire'),
      const SizedBox(width: 24),
      _Stat(
          icon: Icons.reply_rounded,
          value: d.shares,
          label: 'Partages',
          mirror: true),
    ]);
  }

  // ── Commentaires ─────────────────────────────────────────────
  Widget _buildCommentsSection() {
    final count = widget.data.comments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commentaires ($count)',
            style: CliinAppTextStyles.headingSmall
                .copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (final c in _kMockComments) ...[
          _CommentItem(comment: c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ── Barre de commentaire fixe ─────────────────────────────────
  Widget _buildCommentBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: CliinAppColors.cardWhite,
          border: Border(top: BorderSide(color: CliinAppColors.divider)),
        ),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (await requireAuth(context)) {
                  // Commentaire non encore implémenté — le guard est posé
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: CliinAppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('Ajouter un commentaire…',
                    style: CliinAppTextStyles.bodySmall.copyWith(
                        color: CliinAppColors.textSecondary, fontSize: 13)),
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
                  color: CliinAppColors.textWhite, size: 18),
            ),
          ),
        ]),
      ),
    );
  }

  String _formatPubDate(DateTime dt) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'Publié le ${dt.day} ${months[dt.month - 1]} ${dt.year} à $h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────
// Section photo de la page détail (220px, zoom interactif)
// ─────────────────────────────────────────────────────────────────
class _DetailPhotoSection extends StatelessWidget {
  final HomeReportModel data;
  const _DetailPhotoSection({required this.data});

  void _openPhoto(BuildContext context, String path) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _PhotoFullScreen(imagePath: path),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isTraite = data.status == ReportStatus.traite;
    return SizedBox(
      height: 220,
      child: Stack(fit: StackFit.expand, children: [
        isTraite
            ? _BeforeAfterDetail(data: data, onOpenPhoto: _openPhoto)
            : buildReportImage(data.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: CliinAppColors.background)),
        // Badges
        if (!isTraite)
          Positioned(
              top: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _SeverityBadgeDetail(severity: data.severity)),
        if (isTraite)
          Positioned(
              top: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _TraiteChipDetail()),
        Positioned(
            top: CliinAppConstants.spacingS,
            right: CliinAppConstants.spacingS,
            child: _IdChipDetail(reference: data.reference)),
        if (!isTraite)
          Positioned(
              bottom: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _DistanceBadgeDetail(data: data)),
        // Zoom sur photo simple
        if (!isTraite)
          Positioned(
              bottom: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _ZoomBtn(
                  onTap: () => _openPhoto(context, data.imageAsset))),
      ]),
    );
  }
}

class _BeforeAfterDetail extends StatelessWidget {
  final HomeReportModel data;
  final void Function(BuildContext, String) onOpenPhoto;
  const _BeforeAfterDetail(
      {required this.data, required this.onOpenPhoto});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Stack(fit: StackFit.expand, children: [
          buildReportImage(data.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: CliinAppColors.background)),
          Positioned(
              bottom: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _PhotoLabelDetail(label: 'AVANT', dark: true)),
          Positioned(
              top: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _ZoomBtn(
                  onTap: () => onOpenPhoto(context, data.imageAsset))),
        ]),
      ),
      Container(width: 2, color: CliinAppColors.background),
      Expanded(
        child: Stack(fit: StackFit.expand, children: [
          data.imageAfterAsset != null
              ? buildReportImage(data.imageAfterAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: CliinAppColors.background))
              : Container(color: CliinAppColors.background),
          Positioned(
              bottom: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _PhotoLabelDetail(label: 'APRÈS', dark: false)),
          if (data.imageAfterAsset != null)
            Positioned(
                top: CliinAppConstants.spacingS,
                left: CliinAppConstants.spacingS,
                child: _ZoomBtn(
                    onTap: () =>
                        onOpenPhoto(context, data.imageAfterAsset!))),
        ]),
      ),
    ]);
  }
}

class _PhotoFullScreen extends StatelessWidget {
  final String imagePath;
  const _PhotoFullScreen({required this.imagePath});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(children: [
            Center(
              child: buildReportImage(imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white38,
                      size: 64)),
            ),
            Positioned(
              top: 12, right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// Widgets helper photo — page détail
// ─────────────────────────────────────────────────────────────────
class _ZoomBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _ZoomBtn({this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle),
          child: const Icon(Icons.zoom_in_rounded,
              color: Colors.white, size: 15),
        ),
      );
}

class _PhotoLabelDetail extends StatelessWidget {
  final String label;
  final bool dark;
  const _PhotoLabelDetail({required this.label, required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: dark
              ? Colors.black.withValues(alpha: 0.75)
              : CliinAppColors.primary,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusSmall),
        ),
        child: Text(label,
            style: CliinAppTextStyles.badge.copyWith(
                color: CliinAppColors.textWhite,
                fontWeight: FontWeight.w700)),
      );
}

class _SeverityBadgeDetail extends StatelessWidget {
  final ReportSeverity severity;
  const _SeverityBadgeDetail({required this.severity});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: severity.color,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(severity.icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(severity.label.toUpperCase(),
              style: CliinAppTextStyles.badge.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _TraiteChipDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: CliinAppColors.alertRed,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text('TRAITÉ',
              style: CliinAppTextStyles.badge.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _IdChipDetail extends StatelessWidget {
  final String reference;
  const _IdChipDetail({required this.reference});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => copyReportCode(context, reference),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusSmall)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(reference,
                style: CliinAppTextStyles.badge.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(width: 5),
            const Icon(Icons.copy_rounded, color: Colors.white, size: 12),
          ]),
        ),
      );
}

class _DistanceBadgeDetail extends StatelessWidget {
  final HomeReportModel data;
  const _DistanceBadgeDetail({required this.data});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_rounded,
              color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(data.distance,
              style: CliinAppTextStyles.badge
                  .copyWith(color: Colors.white)),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1, height: 10,
              color: Colors.white38),
          const Icon(Icons.access_time_rounded,
              color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(reportTimeAgoLabel(data.createdAt, data.timeAgo),
              style: CliinAppTextStyles.badge
                  .copyWith(color: Colors.white)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────
// Stat widget
// ─────────────────────────────────────────────────────────────────
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
            child:
                Icon(icon, size: 16, color: CliinAppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          Text('$value',
              style: CliinAppTextStyles.bodySmall.copyWith(
                  color: CliinAppColors.textDark,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(label,
              style: CliinAppTextStyles.bodySmall
                  .copyWith(color: CliinAppColors.textSecondary)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────
// Commentaire item
// ─────────────────────────────────────────────────────────────────
class _CommentItem extends StatelessWidget {
  final _MockComment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle),
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
                      style: CliinAppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: CliinAppColors.textDark,
                          fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(comment.time,
                      style: CliinAppTextStyles.bodySmall.copyWith(
                          color: CliinAppColors.textSecondary,
                          fontSize: 11)),
                ]),
                const SizedBox(height: 3),
                Text(comment.text,
                    style: CliinAppTextStyles.bodySmall.copyWith(
                        color: CliinAppColors.textDark,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      );
}
