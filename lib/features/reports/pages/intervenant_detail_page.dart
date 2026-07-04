// lib/features/reports/pages/intervenant_detail_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/store/report_store.dart';
import '../../../../shared/widgets/report_action_zone.dart';
import '../../../../shared/widgets/report_stats_comments.dart';
import '../../../../shared/widgets/public_view_link_button.dart';
import '../../../../features/home/models/home_report_model.dart';
import 'proof_camera_page.dart';
import 'report_detail_page.dart';

class IntervenantDetailPage extends StatefulWidget {
  final HomeReportModel report;
  const IntervenantDetailPage({super.key, required this.report});

  @override
  State<IntervenantDetailPage> createState() => _IntervenantDetailPageState();
}

class _IntervenantDetailPageState extends State<IntervenantDetailPage> {
  late HomeReportModel _report;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _whatsAppVisible = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _whatsAppVisible = _report.intervenant?.whatsAppVisible ?? false;
    _startCountdown();
    ReportStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    ReportStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    final updated = ReportStore.instance.reportById(_report.id);
    if (updated != null && mounted) {
      setState(() {
        _report = updated;
        _whatsAppVisible = updated.intervenant?.whatsAppVisible ?? false;
      });
    }
  }

  void _startCountdown() {
    if (_report.status != ReportStatus.enCours) return;
    final takenAt = _report.intervenant?.takenAt;
    if (takenAt == null) return;
    final deadline = takenAt.add(const Duration(hours: 72));
    _updateRemaining(deadline);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining(deadline);
    });
  }

  void _updateRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  String get _countdownText {
    if (_remaining == Duration.zero) return 'Délai expiré';
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${s}s';
  }

  Future<void> _toggleWhatsApp(bool value) async {
    try {
      final updated = await ReportStore.instance.toggleWhatsApp(
        reportId: _report.id,
        visible: value,
      );
      if (mounted) {
        setState(() {
          _report = updated;
          _whatsAppVisible = value;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: CliinAppColors.alertRed,
        ));
      }
    }
  }

  // ── Bouton Contacter — ouvre WhatsApp ─────────────────────────
  // ── Ajouter un numéro WhatsApp (sheet) ──────────────────────
  void _openAddNumberSheet() {
    final phoneController = TextEditingController();
    bool visible = true;
    // Indicatif par défaut : +225
    String indicatif = '+225';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(CliinAppConstants.radiusLarge),
              topRight: Radius.circular(CliinAppConstants.radiusLarge),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            CliinAppConstants.pagePadding,
            0,
            CliinAppConstants.pagePadding,
            MediaQuery.of(ctx).viewInsets.bottom + CliinAppConstants.spacingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: CliinAppConstants.spacingM),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: CliinAppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: CliinAppConstants.spacingL),
              Text('Ajouter un numéro WhatsApp',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: CliinAppColors.textDark)),
              const SizedBox(height: CliinAppConstants.spacingL),

              // Champ numéro
              Container(
                decoration: BoxDecoration(
                  color: CliinAppColors.background,
                  borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                  border: Border.all(color: CliinAppColors.divider),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(indicatif,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: CliinAppColors.textDark)),
                  ),
                  Container(width: 1, height: 24, color: CliinAppColors.divider),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      style: GoogleFonts.inter(fontSize: 14, color: CliinAppColors.textDark),
                      decoration: InputDecoration(
                        hintText: '07 XX XX XX XX',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14, color: CliinAppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: CliinAppConstants.spacingM),

              // Toggle visible au public
              Row(children: [
                Expanded(
                  child: Text('Visible au public',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: CliinAppColors.textDark)),
                ),
                Switch(
                  value: visible,
                  onChanged: (v) => setModal(() => visible = v),
                  activeThumbColor: CliinAppColors.primary,
                ),
              ]),

              const SizedBox(height: CliinAppConstants.spacingL),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final local = phoneController.text.trim();
                    if (local.isEmpty) return;
                    // Même règle trunk prefix que take_charge_flow
                    const removeTrunkZero = {'+33', '+32', '+44', '+31', '+39', '+34'};
                    final shouldRemove = local.startsWith('0') &&
                        removeTrunkZero.contains(indicatif);
                    final cleaned = shouldRemove ? local.substring(1) : local;
                    final fullNumber = '$indicatif$cleaned';
                    Navigator.pop(ctx);
                    try {
                      final updated = await ReportStore.instance.updateWhatsAppNumber(
                        reportId: _report.id,
                        number: fullNumber,
                        visible: visible,
                      );
                      if (mounted) {
                        setState(() {
                          _report = updated;
                          _whatsAppVisible = visible;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erreur : ${e.toString()}'),
                          backgroundColor: CliinAppColors.alertRed,
                        ));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CliinAppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text('Enregistrer',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _showPublicViewLink {
    final outcome = _report.intervenant?.outcome;
    return outcome != InterventionOutcome.abandoned &&
        outcome != InterventionOutcome.rejected;
  }

  bool get _isTerminalOutcome {
    final outcome = _report.intervenant?.outcome;
    return outcome == InterventionOutcome.abandoned ||
        outcome == InterventionOutcome.rejected;
  }

  void _onViewPublic() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ReportDetailPage(data: _report, isAuthor: false)),
    );
  }

  void _openProofCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProofCameraPage(report: _report)),
    ).then((updatedReport) {
      if (updatedReport is HomeReportModel && mounted) {
        setState(() => _report = updatedReport);
      }
    });
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin',
        'Juil','Août','Sep','Oct','Nov','Déc'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding,
                  CliinAppConstants.spacingM,
                  CliinAppConstants.pagePadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBar(),
                    const SizedBox(height: CliinAppConstants.spacingM),
                    _buildReportSummary(),
                    if (_report.status == ReportStatus.enCours) ...[
                      const SizedBox(height: CliinAppConstants.spacingM),
                      _buildIntervenantWhatsAppBlock(),
                    ],
                    if (_report.status == ReportStatus.traite) ...[
                      const SizedBox(height: CliinAppConstants.spacingM),
                      ReportActionZone(data: _report, compact: false),
                    ] else if (_report.intervenant?.outcome ==
                        InterventionOutcome.abandoned) ...[
                      const SizedBox(height: CliinAppConstants.spacingM),
                      _buildAbandonedCard(),
                    ] else if (_report.intervenant?.outcome ==
                        InterventionOutcome.rejected) ...[
                      const SizedBox(height: CliinAppConstants.spacingM),
                      _buildRejectedCard(),
                    ] else ...[
                      const SizedBox(height: CliinAppConstants.spacingM),
                      _buildProofBlock(),
                    ],
                    if (_showPublicViewLink) ...[
                      const SizedBox(height: CliinAppConstants.spacingM),
                      PublicViewLinkButton(onTap: _onViewPublic),
                    ],
                    const SizedBox(height: CliinAppConstants.spacingM),
                    _buildInfoAndHistory(),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                    ReportStatsRow(
                        views: _report.views,
                        comments: _report.comments,
                        shares: _report.shares),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    ReportCommentsSection(count: _report.comments),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ReportCommentBar(),
    );
  }

  // ── Carte "Abandonné" — délai 72h expiré sans preuve ───────────
  Widget _buildAbandonedCard() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.hourglass_bottom_rounded,
            color: Color(0xFF6B7280), size: 22),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Délai de 72h expiré',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: CliinAppColors.textDark)),
            const SizedBox(height: 3),
            Text(
                'Aucune preuve n\'a été soumise dans le délai. Ce cas est '
                'redevenu Disponible — un autre intervenant peut désormais le '
                'prendre en charge.',
                style: GoogleFonts.inter(
                    fontSize: 11, color: CliinAppColors.textSecondary,
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  // ── Carte "Rejeté" — preuve refusée (GPS hors marge) ────────────
  Widget _buildRejectedCard() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: const Color(0xFF8E24AA)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFF8E24AA), size: 22),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Preuve refusée',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: CliinAppColors.textDark)),
            const SizedBox(height: 3),
            Text(
                'La position GPS de votre photo \'après\' ne correspondait '
                'pas à celle du cas signalé (écart supérieur à la marge '
                'tolérée). Ce cas est redevenu Disponible. Assurez-vous '
                'd\'être bien sur place au moment de la photo la prochaine '
                'fois.',
                style: GoogleFonts.inter(
                    fontSize: 11, color: CliinAppColors.textSecondary,
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding,
          vertical: CliinAppConstants.spacingM),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: CliinAppColors.primaryLight,
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
            ),
            child: const Icon(Icons.arrow_back,
                color: CliinAppColors.primary, size: 20),
          ),
        ),
        Expanded(
          child: Text('Ma prise en charge',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark)),
        ),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: CliinAppColors.background, shape: BoxShape.circle),
          child: const Icon(Icons.more_vert_rounded,
              color: CliinAppColors.textDark, size: 20),
        ),
      ]),
    );
  }

  // ── Statut réel (jamais hardcodé) ──────────────────────────────
  ({String label, Color color, Color bg, IconData icon}) get _statusDisplay {
    if (_report.status == ReportStatus.traite) {
      return (
        label: 'Traité',
        color: CliinAppColors.alertRed,
        bg: CliinAppColors.alertRedBg,
        icon: Icons.check_circle_rounded,
      );
    }
    final outcome = _report.intervenant?.outcome;
    if (outcome == InterventionOutcome.abandoned) {
      return (
        label: 'Abandonné',
        color: const Color(0xFF6B7280),
        bg: const Color(0xFFF0F0F0),
        icon: Icons.cancel_rounded,
      );
    }
    if (outcome == InterventionOutcome.rejected) {
      return (
        label: 'Rejeté',
        color: const Color(0xFF8E24AA),
        bg: const Color(0xFFF3E5F5),
        icon: Icons.error_rounded,
      );
    }
    return (
      label: 'En cours',
      color: CliinAppColors.alertOrange,
      bg: const Color(0xFFFFF3E0),
      icon: Icons.access_time_rounded,
    );
  }

  // ── Colonne de droite — dépend du statut réel ──────────────────
  ({String label, String value, Color color, Color bg, IconData icon})
      get _secondaryDisplay {
    if (_report.status == ReportStatus.traite) {
      final treatedAt = _report.intervenant?.treatedAt;
      return (
        label: 'Traité le',
        value: treatedAt != null ? _formatDate(treatedAt) : '—',
        color: CliinAppColors.alertRed,
        bg: CliinAppColors.alertRedBg,
        icon: Icons.event_available_rounded,
      );
    }
    final outcome = _report.intervenant?.outcome;
    if (outcome == InterventionOutcome.abandoned) {
      return (
        label: 'Délai',
        value: 'Expiré',
        color: const Color(0xFF6B7280),
        bg: const Color(0xFFF0F0F0),
        icon: Icons.hourglass_disabled_rounded,
      );
    }
    if (outcome == InterventionOutcome.rejected) {
      return (
        label: 'Preuve',
        value: 'Refusée',
        color: const Color(0xFF8E24AA),
        bg: const Color(0xFFF3E5F5),
        icon: Icons.gpp_bad_rounded,
      );
    }
    return (
      label: 'Temps restant',
      value: _countdownText,
      color: CliinAppColors.primary,
      bg: CliinAppColors.primaryLight,
      icon: Icons.timer_outlined,
    );
  }

  // ── Statut + info secondaire — 2 colonnes, pas d'overflow ─────
  Widget _buildStatusBar() {
    final status = _statusDisplay;
    final secondary = _secondaryDisplay;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.spacingL,
          vertical: CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: status.bg,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: Icon(status.icon, color: status.color, size: 18),
            ),
            const SizedBox(width: CliinAppConstants.spacingS),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Statut', style: GoogleFonts.inter(
                    fontSize: 10, color: CliinAppColors.textSecondary)),
                Text(status.label, style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: status.color),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
        Container(width: 1, height: 32, color: CliinAppColors.divider),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: secondary.bg,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: Icon(secondary.icon, color: secondary.color, size: 18),
            ),
            const SizedBox(width: CliinAppConstants.spacingS),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(secondary.label, style: GoogleFonts.inter(
                    fontSize: 10, color: CliinAppColors.textSecondary)),
                Text(secondary.value,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: secondary.color),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildReportSummary() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
          child: Stack(children: [
            Image.asset(
              _report.imageAsset,
              width: 96, height: 88, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                  width: 96, height: 88, color: CliinAppColors.background),
            ),
            Positioned(
              top: 5, left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: _report.severity.color,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(_report.severity.label.toUpperCase(),
                    style: CliinAppTextStyles.badge.copyWith(
                        color: Colors.white, fontSize: 8)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_report.title,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: CliinAppColors.textDark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  color: CliinAppColors.primary, size: 12),
              const SizedBox(width: 2),
              Expanded(
                child: Text(_report.location,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: CliinAppColors.primary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 4),
            Text(_report.description,
                style: GoogleFonts.inter(
                    fontSize: 11, color: CliinAppColors.textSecondary,
                    height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              _MiniChip(label: _report.reference, icon: Icons.tag_rounded),
              const SizedBox(width: 6),
              _MiniChip(label: _report.distance, icon: Icons.near_me_outlined),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Intervenant + WhatsApp — CORRECTION overflow + "Pour le compte de" ──
  Widget _buildIntervenantWhatsAppBlock() {
    final intervenant = _report.intervenant;
    if (intervenant == null) return const SizedBox.shrink();

    final number = intervenant.whatsAppNumber;

    // "Pour le compte de" : groupName si groupe, sinon "Moi-même"
    final accountLabel = intervenant.groupName ?? 'Moi-même';

    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Ligne 1 : Avatar + nom (colonne) ─────────────────────
        // CORRECTION overflow : on ne met plus tout dans une Row
        // Le bouton Contacter passe en bas
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CliinAppColors.primaryLight,
              border: Border.all(color: CliinAppColors.primary, width: 1.5),
            ),
            child: Center(
              child: Text(
                intervenant.name.isNotEmpty
                    ? intervenant.name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: CliinAppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          // Nom + "Pris en charge par"
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pris en charge par',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: CliinAppColors.textSecondary)),
              Text(intervenant.name,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: CliinAppColors.primary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),

        const SizedBox(height: CliinAppConstants.spacingS),

        // ── "Pour le compte de" — ligne séparée ──────────────────
        Row(children: [
          const SizedBox(width: 56), // aligne avec le texte après l'avatar
          Text('Pour le compte de : ',
              style: GoogleFonts.inter(
                  fontSize: 12, color: CliinAppColors.textSecondary)),
          Flexible(
            child: Text(accountLabel,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),

        // ── Date prise en charge ──────────────────────────────────
        if (intervenant.takenAt != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const SizedBox(width: 56),
            const Icon(Icons.calendar_today_outlined,
                size: 11, color: CliinAppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text('Pris en charge le ${_formatDate(intervenant.takenAt!)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: CliinAppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],

        // Le bouton "Contacter" n'apparaît PAS dans le tableau de bord intervenant
        // L'intervenant ne peut pas se contacter lui-même — spec

        // ── Séparateur + bloc WhatsApp ──────────────────────────────
        const SizedBox(height: CliinAppConstants.spacingM),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: CliinAppConstants.spacingM),

        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFF25D366), shape: BoxShape.circle),
            child: const Icon(Icons.phone_iphone_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Text('Contact WhatsApp',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
          ),
        ]),

        const SizedBox(height: CliinAppConstants.spacingM),

        // ── CAS 1 : Aucun numéro enregistré ──────────────────────
        if (number == null) ...[
          Text('Aucun numéro enregistré.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: CliinAppColors.textSecondary)),
          const SizedBox(height: CliinAppConstants.spacingM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAddNumberSheet,
              icon: const Icon(Icons.add_rounded,
                  size: 16, color: CliinAppColors.primary),
              label: Text('Ajouter un numéro',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: CliinAppColors.primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: CliinAppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
              ),
            ),
          ),
        ],

        // ── CAS 2 : Numéro enregistré ─────────────────────────────
        if (number != null) ...[
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(number,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: CliinAppColors.textDark)),
                Text('Visible au public',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: CliinAppColors.textSecondary)),
              ]),
            ),
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: _whatsAppVisible,
                onChanged: _toggleWhatsApp,
                activeThumbColor: CliinAppColors.primary,
                activeTrackColor: CliinAppColors.primaryLight,
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _buildProofBlock() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(
            color: CliinAppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.camera_alt_outlined,
            color: CliinAppColors.primary, size: 28),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Marquer comme traité',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: CliinAppColors.textDark)),
            Text('Ajoutez une photo APRÈS pour valider l\'intervention.',
                style: GoogleFonts.inter(
                    fontSize: 11, color: CliinAppColors.textSecondary),
                maxLines: 2),
          ]),
        ),
        const SizedBox(width: CliinAppConstants.spacingS),
        ElevatedButton(
          onPressed: _openProofCamera,
          style: ElevatedButton.styleFrom(
            backgroundColor: CliinAppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            elevation: 0,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            Text('Photo APRÈS',
                style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildInfoAndHistory() {
    final createdAt = _report.createdAt;
    final history = _report.history;

    return Container(
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              CliinAppConstants.spacingL,
              CliinAppConstants.spacingL,
              CliinAppConstants.spacingL,
              CliinAppConstants.spacingM),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Informations',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: CliinAppColors.textDark)),
            const SizedBox(height: CliinAppConstants.spacingM),
            Row(children: [
              Expanded(child: _InfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Signalé le',
                value: createdAt != null ? _formatDate(createdAt) : '—',
              )),
              const SizedBox(width: CliinAppConstants.spacingM),
              Expanded(child: _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Localisation',
                value: _report.location,
              )),
            ]),
            const SizedBox(height: CliinAppConstants.spacingM),
            if (_isTerminalOutcome)
              _InfoTile(
                icon: Icons.tag_rounded,
                label: 'Référence',
                value: _report.reference,
              )
            else
              Row(children: [
                Expanded(child: _InfoTile(
                  icon: Icons.tag_rounded,
                  label: 'Référence',
                  value: _report.reference,
                )),
                const SizedBox(width: CliinAppConstants.spacingM),
                Expanded(child: _InfoTile(
                  icon: Icons.verified_outlined,
                  label: 'GPS AVANT/APRÈS',
                  value: 'En attente',
                  valueColor: CliinAppColors.alertOrange,
                )),
              ]),
          ]),
        ),

        if (history.isNotEmpty) ...[
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.all(CliinAppConstants.spacingL),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Historique',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: CliinAppColors.textDark)),
              const SizedBox(height: CliinAppConstants.spacingM),
              ...history.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == history.length - 1;
                return _HistoryTile(entry: item, isLast: isLast);
              }),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS INTERNES
// ─────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MiniChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: CliinAppColors.background,
      borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: CliinAppColors.textSecondary),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, color: CliinAppColors.textDark,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({
    required this.icon, required this.label, required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 12, color: CliinAppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(
            fontSize: 10, color: CliinAppColors.textSecondary)),
      ]),
      const SizedBox(height: 2),
      Text(value,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: valueColor ?? CliinAppColors.textDark),
          maxLines: 2, overflow: TextOverflow.ellipsis),
    ],
  );
}

class _HistoryTile extends StatelessWidget {
  final ReportHistoryEntry entry;
  final bool isLast;
  const _HistoryTile({required this.entry, required this.isLast});

  String _formatDate(DateTime dt) {
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin',
        'Juil','Août','Sep','Oct','Nov','Déc'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : CliinAppConstants.spacingM),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: entry.type.color, shape: BoxShape.circle),
            child: Icon(entry.type.icon, color: Colors.white, size: 14),
          ),
          if (!isLast)
            Container(width: 2, height: 24, color: CliinAppColors.divider),
        ]),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.type.label,
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: CliinAppColors.textDark)),
                Text(_formatDate(entry.dateTime),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: CliinAppColors.textSecondary)),
                if (entry.actorName != null)
                  Text('Par ${entry.actorName}',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: CliinAppColors.textSecondary)),
              ]),
            ),
            if (entry.isCurrentStep &&
                entry.type != HistoryEventType.abandonne &&
                entry.type != HistoryEventType.rejete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: CliinAppColors.alertOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                ),
                child: Text('En cours',
                    style: GoogleFonts.inter(
                        fontSize: 9, color: CliinAppColors.alertOrange,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ]),
    );
  }
}