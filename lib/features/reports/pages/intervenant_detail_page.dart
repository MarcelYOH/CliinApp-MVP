// lib/features/reports/pages/intervenant_detail_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/store/report_store.dart';
import '../../../../features/home/models/report_model.dart';
import 'proof_camera_page.dart';

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
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
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Août','Sep','Oct','Nov','Déc'];
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
                  80,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Statut + compteur (2 colonnes) ──────────
                    _buildStatusBar(),
                    const SizedBox(height: CliinAppConstants.spacingM),
                    // ── Résumé signalement ───────────────────────
                    _buildReportSummary(),
                    const SizedBox(height: CliinAppConstants.spacingM),
                    // ── Intervenant + WhatsApp (fusionnés) ───────
                    _buildIntervenantWhatsAppBlock(),
                    const SizedBox(height: CliinAppConstants.spacingM),
                    // ── Bouton preuve ────────────────────────────
                    _buildProofBlock(),
                    const SizedBox(height: CliinAppConstants.spacingM),
                    // ── Infos + Historique ───────────────────────
                    _buildInfoAndHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
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
            child: const Icon(Icons.arrow_back, color: CliinAppColors.primary, size: 20),
          ),
        ),
        Expanded(
          child: Text('Mon intervention',
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

  // ── Barre statut — 2 colonnes au lieu de 3 ────────────────────
  // La date de prise en charge est intégrée dans le bloc intervenant
  Widget _buildStatusBar() {
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
        // Statut
        Expanded(
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: const Icon(Icons.access_time_rounded,
                  color: CliinAppColors.alertOrange, size: 18),
            ),
            const SizedBox(width: CliinAppConstants.spacingS),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Statut',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: CliinAppColors.textSecondary)),
                Text('En cours',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: CliinAppColors.alertOrange)),
              ]),
            ),
          ]),
        ),

        Container(width: 1, height: 32, color: CliinAppColors.divider),
        const SizedBox(width: CliinAppConstants.spacingM),

        // Compteur 72h
        Expanded(
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
              ),
              child: const Icon(Icons.timer_outlined,
                  color: CliinAppColors.primary, size: 18),
            ),
            const SizedBox(width: CliinAppConstants.spacingS),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Temps restant',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: CliinAppColors.textSecondary)),
                Text(_countdownText,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: CliinAppColors.primary),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Résumé signalement ─────────────────────────────────────────
  Widget _buildReportSummary() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image
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
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_report.severity.label.toUpperCase(),
                    style: CliinAppTextStyles.badge.copyWith(
                        color: Colors.white, fontSize: 8)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        // Infos
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
            // Référence + distance sur une ligne
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

  // ── Intervenant + WhatsApp fusionnés ───────────────────────────
  Widget _buildIntervenantWhatsAppBlock() {
    final intervenant = _report.intervenant;
    if (intervenant == null) return const SizedBox.shrink();

    final number = intervenant.whatsAppNumber;
    // Nom du compte : groupe sélectionné ou "Moi-même"
    // On détecte via le nom de l'intervenant vs celui de l'user
    // Pour le MVP on affiche le champ tel quel
    final accountLabel = intervenant.name;

    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Ligne 1 : Avatar + infos intervenant + bouton Contacter ──
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

          // Nom + compte
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(accountLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: CliinAppColors.primary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Text('Pour le compte de : ',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: CliinAppColors.textSecondary)),
                Text('Moi-même',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: CliinAppColors.textDark)),
              ]),
            ]),
          ),

          // Bouton Contacter — visible seulement si whatsApp ON
          if (_whatsAppVisible && number != null) ...[
            const SizedBox(width: CliinAppConstants.spacingS),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 15, color: Color(0xFF25D366)),
              label: Text('Contacter',
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: CliinAppColors.textDark)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                side: const BorderSide(color: Color(0xFF25D366)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
              ),
            ),
          ],
        ]),

        // ── Date de prise en charge ───────────────────────────────
        if (intervenant.takenAt != null) ...[
          const SizedBox(height: CliinAppConstants.spacingS),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 12, color: CliinAppColors.textSecondary),
            const SizedBox(width: 4),
            Text('Pris en charge le ${_formatDate(intervenant.takenAt!)}',
                style: GoogleFonts.inter(
                    fontSize: 11, color: CliinAppColors.textSecondary)),
          ]),
        ],

        // ── Séparateur + bloc WhatsApp si numéro renseigné ────────
        if (number != null) ...[
          const SizedBox(height: CliinAppConstants.spacingM),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: CliinAppConstants.spacingM),

          Row(children: [
            // Icône WhatsApp
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: Color(0xFF25D366), shape: BoxShape.circle),
              child: const Icon(Icons.phone_iphone_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: CliinAppConstants.spacingM),

            // Label + numéro
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Contact WhatsApp',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: CliinAppColors.textDark)),
                Text(number,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: CliinAppColors.textSecondary)),
              ]),
            ),

            // Toggle visibilité
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                _whatsAppVisible ? 'Visible' : 'Masqué',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _whatsAppVisible
                        ? CliinAppColors.primary
                        : CliinAppColors.textSecondary),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _whatsAppVisible,
                  onChanged: _toggleWhatsApp,
                  activeThumbColor: CliinAppColors.primary,
                  activeTrackColor: CliinAppColors.primaryLight,
                ),
              ),
            ]),
          ]),
        ],
      ]),
    );
  }

  // ── Bouton preuve — compact ────────────────────────────────────
  Widget _buildProofBlock() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.primary.withValues(alpha: 0.3)),
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

  // ── Infos + Historique dans un seul bloc scrollable ────────────
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

        // ── Section Informations ──────────────────────────────────
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

            // Ligne 1 : Signalé le + Localisation
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

            // Ligne 2 : Référence + Vérification GPS
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

        // ── Séparateur ────────────────────────────────────────────
        if (history.isNotEmpty) ...[
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Section Historique ────────────────────────────────
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
        Text(label,
            style: GoogleFonts.inter(
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
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Août','Sep','Oct','Nov','Déc'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : CliinAppConstants.spacingM),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timeline
        Column(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: entry.type.color, shape: BoxShape.circle),
            child: Icon(entry.type.icon, color: Colors.white, size: 14),
          ),
          if (!isLast)
            Container(width: 2, height: 24, color: CliinAppColors.divider),
        ]),
        const SizedBox(width: CliinAppConstants.spacingM),

        // Contenu
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
              if (entry.isCurrentStep)
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
            ],
          ),
        ),
      ]),
    );
  }
}