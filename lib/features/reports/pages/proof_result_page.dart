// lib/features/reports/pages/proof_result_page.dart
// Résultat de la vérification de preuve — validée ou rejetée

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/home/models/home_report_model.dart';
import '../../../../shared/repositories/report_repository.dart';
import 'intervenant_detail_page.dart';
import 'report_detail_page.dart';
import '../../../../shared/navigation/fast_page_route.dart';

class ProofResultPage extends StatelessWidget {
  final HomeReportModel report;
  final ProofVerificationResult result;

  const ProofResultPage({
    super.key,
    required this.report,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return result.isValid
        ? _ValidatedView(report: report, result: result)
        : _RejectedView(report: report, result: result);
  }
}

// ─────────────────────────────────────────────────────────────────
// VUE PREUVE VALIDÉE
// ─────────────────────────────────────────────────────────────────
class _ValidatedView extends StatefulWidget {
  final HomeReportModel report;
  final ProofVerificationResult result;

  const _ValidatedView({required this.report, required this.result});

  @override
  State<_ValidatedView> createState() => _ValidatedViewState();
}

class _ValidatedViewState extends State<_ValidatedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
        parent: _animController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  HomeReportModel get _updatedReport =>
      widget.result.updatedReport ?? widget.report;

  void _viewIntervention(BuildContext context) {
    Navigator.push(
      context,
      fastFadeRoute<void>(IntervenantDetailPage(report: _updatedReport)),
    );
  }

  void _viewPublic(BuildContext context) {
    Navigator.push(
      context,
      fastFadeRoute<void>(
          ReportDetailPage(data: _updatedReport, isAuthor: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: CliinAppConstants.spacingXL),

                // Icône succès
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: CliinAppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 44),
                  ),
                ),

                const SizedBox(height: CliinAppConstants.spacingL),

                Text('Preuve validée !',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark)),
                const SizedBox(height: CliinAppConstants.spacingS),
                Text(
                  'Votre intervention a été enregistrée avec succès.\n'
                  'Le cas signalé est maintenant marqué comme traité.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: CliinAppColors.textSecondary),
                ),

                const SizedBox(height: CliinAppConstants.spacingXL),

                // Carte résultat GPS
                Container(
                  padding: const EdgeInsets.all(CliinAppConstants.spacingL),
                  decoration: BoxDecoration(
                    color: CliinAppColors.cardWhite,
                    borderRadius:
                        BorderRadius.circular(CliinAppConstants.radiusMedium),
                    border: Border.all(color: CliinAppColors.divider),
                  ),
                  child: Column(children: [
                    _ResultRow(
                      icon: Icons.verified_outlined,
                      color: CliinAppColors.primary,
                      label: 'Vérification GPS',
                      value: 'Conforme',
                    ),
                    const Divider(height: CliinAppConstants.spacingL),
                    _ResultRow(
                      icon: Icons.my_location_rounded,
                      color: CliinAppColors.primary,
                      label: 'Distance du cas signalé',
                      value:
                          '${widget.result.distanceMeters.toStringAsFixed(0)} m',
                    ),
                    const Divider(height: CliinAppConstants.spacingL),
                    _ResultRow(
                      icon: Icons.tag_rounded,
                      color: CliinAppColors.textSecondary,
                      label: 'Référence',
                      value: widget.report.reference,
                    ),
                    const Divider(height: CliinAppConstants.spacingL),
                    _ResultRow(
                      icon: Icons.access_time_rounded,
                      color: CliinAppColors.textSecondary,
                      label: 'Enregistré le',
                      value: _formatNow(),
                    ),
                  ]),
                ),

                const SizedBox(height: CliinAppConstants.spacingL),

                // Bannière motivation
                Container(
                  padding: const EdgeInsets.all(CliinAppConstants.spacingL),
                  decoration: BoxDecoration(
                    color: CliinAppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(CliinAppConstants.radiusMedium),
                  ),
                  child: Row(children: [
                    const Icon(Icons.verified_outlined,
                        color: CliinAppColors.primary, size: 22),
                    const SizedBox(width: CliinAppConstants.spacingM),
                    Expanded(
                      child: Text(
                        'Merci pour votre intervention ! Votre action contribue à un environnement plus propre.',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CliinAppColors.textDark),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: CliinAppConstants.spacingXL),

                // Actions
                _ActionButton(
                  label: 'Voir ma prise en charge',
                  icon: Icons.assignment_turned_in_outlined,
                  isPrimary: true,
                  onTap: () => _viewIntervention(context),
                ),
                const SizedBox(height: CliinAppConstants.spacingM),
                _ActionButton(
                  label: 'Voir l\'affichage public',
                  icon: Icons.visibility_outlined,
                  isPrimary: false,
                  onTap: () => _viewPublic(context),
                ),
                const SizedBox(height: CliinAppConstants.spacingL),
                Center(
                  child: GestureDetector(
                    onTap: () => _goHome(context),
                    child: Text('Retour à l\'accueil',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CliinAppColors.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationColor: CliinAppColors.textSecondary)),
                  ),
                ),

                const SizedBox(height: CliinAppConstants.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year} • '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────
// VUE PREUVE REJETÉE
// ─────────────────────────────────────────────────────────────────
class _RejectedView extends StatelessWidget {
  final HomeReportModel report;
  final ProofVerificationResult result;

  const _RejectedView({required this.report, required this.result});

  HomeReportModel get _updatedReport => result.updatedReport ?? report;

  void _viewIntervention(BuildContext context) {
    Navigator.push(
      context,
      fastFadeRoute<void>(IntervenantDetailPage(report: _updatedReport)),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Column(
            children: [
              const SizedBox(height: CliinAppConstants.spacingXL),

              // Icône rejet
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: CliinAppColors.alertRedBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gps_off_rounded,
                    color: CliinAppColors.alertRed, size: 44),
              ),

              const SizedBox(height: CliinAppConstants.spacingL),

              Text('Preuve non validée',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CliinAppColors.textDark)),
              const SizedBox(height: CliinAppConstants.spacingS),
              Text(
                'Les coordonnées GPS ne correspondent pas\nà l\'emplacement du cas signalé.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: CliinAppColors.textSecondary),
              ),

              const SizedBox(height: CliinAppConstants.spacingXL),

              // Détail erreur
              Container(
                padding: const EdgeInsets.all(CliinAppConstants.spacingL),
                decoration: BoxDecoration(
                  color: CliinAppColors.alertRedBg,
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium),
                  border: Border.all(
                      color: CliinAppColors.alertRed.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  _ResultRow(
                    icon: Icons.gps_off_rounded,
                    color: CliinAppColors.alertRed,
                    label: 'Vérification GPS',
                    value: 'Non conforme',
                    valueColor: CliinAppColors.alertRed,
                  ),
                  const Divider(height: CliinAppConstants.spacingL),
                  _ResultRow(
                    icon: Icons.my_location_rounded,
                    color: CliinAppColors.alertRed,
                    label: 'Distance détectée',
                    value:
                        '${result.distanceMeters.toStringAsFixed(0)} m (max : 50 m)',
                    valueColor: CliinAppColors.alertRed,
                  ),
                ]),
              ),

              const SizedBox(height: CliinAppConstants.spacingL),

              // Explication
              Container(
                padding: const EdgeInsets.all(CliinAppConstants.spacingL),
                decoration: BoxDecoration(
                  color: CliinAppColors.cardWhite,
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium),
                  border: Border.all(color: CliinAppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: CliinAppColors.textSecondary, size: 20),
                    const SizedBox(width: CliinAppConstants.spacingM),
                    Expanded(
                      child: Text(
                        'La photo doit être prise sur le lieu exact du cas signalé '
                        '(dans un rayon de 50 m). '
                        'Assurez-vous d\'être bien sur place avant de prendre la photo.',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CliinAppColors.textSecondary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: CliinAppConstants.spacingXL),

              // Actions
              _ActionButton(
                label: 'Voir ma prise en charge',
                icon: Icons.assignment_turned_in_outlined,
                isPrimary: true,
                onTap: () => _viewIntervention(context),
              ),
              const SizedBox(height: CliinAppConstants.spacingL),
              Center(
                child: GestureDetector(
                  onTap: () => _goHome(context),
                  child: Text('Retour à l\'accueil',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CliinAppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: CliinAppColors.textSecondary)),
                ),
              ),

              const SizedBox(height: CliinAppConstants.spacingXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS INTERNES
// ─────────────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Color? valueColor;

  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: CliinAppColors.textSecondary)),
        ),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? CliinAppColors.textDark)),
      ]);
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: isPrimary
            ? ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(icon, color: Colors.white, size: 18),
                label: Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CliinAppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                  elevation: 0,
                ),
              )
            : OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icon, color: CliinAppColors.primary, size: 18),
                label: Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CliinAppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CliinAppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                ),
              ),
      );
}