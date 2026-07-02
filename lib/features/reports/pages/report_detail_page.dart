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
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/report_stats_comments.dart';
import 'intervenant_detail_page.dart';
import 'report_form_page.dart';
import 'package:cliinapp/features/auth/auth_guard.dart';
import '../widgets/take_charge_flow.dart';

// ─────────────────────────────────────────────────────────────────
// Page principale
// ─────────────────────────────────────────────────────────────────
class ReportDetailPage extends StatefulWidget {
  final HomeReportModel data;
  final bool isAuthor;

  const ReportDetailPage({super.key, required this.data, this.isAuthor = false});

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

  void _onEdit() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => ReportFormPage(existingReport: widget.data)),
    );
  }

  Future<void> _onDelete() async {
    await ReportStore.instance.deleteReport(widget.data.id);
    if (mounted) Navigator.pop(context);
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
                        _buildInformationsSection(),
                        const SizedBox(height: 16),
                        _buildLocationSection(),
                        const SizedBox(height: 16),
                        ReportActionZone(
                          key: ValueKey(
                              '${widget.data.id}-$_demoShowContact'),
                          data: _effectiveData,
                          compact: false,
                          isAuthor: widget.isAuthor,
                          onTakeCharge: _onTakeCharge,
                          onContact: _onContact,
                          onIntervenantTap: _onIntervenantTap,
                          onEdit: _onEdit,
                          onDelete: _onDelete,
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
                        ReportStatsRow(
                            views: widget.data.views,
                            comments: widget.data.comments,
                            shares: widget.data.shares),
                        const SizedBox(height: 16),
                        ReportCommentsSection(count: widget.data.comments),
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
      bottomNavigationBar: const ReportCommentBar(),
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
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded,
                color: CliinAppColors.primary, size: 20),
          ),
        ),
        Expanded(
          child: Text('Détails du cas',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        GestureDetector(
          onTap: _onShare,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.ios_share_rounded,
                color: CliinAppColors.primary, size: 18),
          ),
        ),
      ]),
    );
  }

  // ── Titre + badge statut ─────────────────────────────────────
  Widget _buildTitleRow() {
    final status = widget.data.status;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(widget.data.title,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CliinAppColors.textDark,
                  height: 1.25)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: status.bgColor,
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusSmall)),
          child: Text(status.label,
              style: CliinAppTextStyles.badge.copyWith(
                  color: status.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ── Localisation ─────────────────────────────────────────────
  Widget _buildLocationRow() {
    return Row(children: [
      const Icon(Icons.location_on_rounded,
          color: CliinAppColors.primary, size: 13),
      const SizedBox(width: 4),
      Expanded(
        child: Text(widget.data.location,
            style: CliinAppTextStyles.bodySmall.copyWith(
                color: CliinAppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 12.5),
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
      padding: const EdgeInsets.all(12),
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
                  height: 1.6)),
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

  // ── Informations — grille 2 colonnes, 4 tuiles ────────────────
  Widget _buildInformationsSection() {
    final status = widget.data.status;
    final signalePar = widget.isAuthor
        ? 'Vous'
        : (widget.data.signalePar ?? 'Citoyen');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius:
            BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _InfoGridTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: CliinAppColors.primary,
                    iconBg: CliinAppColors.primaryLight,
                    label: 'Catégorie',
                    value: widget.data.category.label)),
            const SizedBox(width: 10),
            Expanded(
                child: _InfoGridTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: CliinAppColors.primary,
                    iconBg: CliinAppColors.primaryLight,
                    label: 'Signalé par',
                    value: signalePar)),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _InfoGridTile(
                    icon: Icons.description_outlined,
                    iconColor: CliinAppColors.primary,
                    iconBg: CliinAppColors.primaryLight,
                    label: 'Référence',
                    value: widget.data.reference)),
            const SizedBox(width: 10),
            Expanded(
                child: _InfoGridTile(
                    icon: Icons.check_rounded,
                    iconColor: status.color,
                    iconBg: status.bgColor,
                    label: 'Statut',
                    value: status.label)),
          ]),
        ],
      ),
    );
  }

  // ── Localisation — miniature carte + adresse ──────────────────
  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius:
            BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Localisation',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 90,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E8EC),
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: CliinAppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.location,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: CliinAppColors.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.navigation_rounded,
                        color: CliinAppColors.primary, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          '${widget.data.distance} de votre position',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: CliinAppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ],
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
      height: isTraite ? 200 : 220,
      child: Stack(fit: StackFit.expand, children: [
        isTraite
            ? _BeforeAfterDetail(data: data, onOpenPhoto: _openPhoto)
            : buildReportImage(data.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: const Color(0xFFCFD3D8))),
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
// Tuile info — section Informations
// ─────────────────────────────────────────────────────────────────
class _InfoGridTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  const _InfoGridTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: CliinAppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CliinAppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}

