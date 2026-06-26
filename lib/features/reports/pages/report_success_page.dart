// lib/features/reports/pages/report_success_page.dart
// Confirmation de publication (étape 5) — branché sur ReportStore

import 'package:flutter/material.dart';
import '../../../../core/utils/clipboard_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/report_model.dart';
import '../../../../shared/models/report_category.dart';
import '../data/report_dummy_data.dart';
import '../widgets/report_stepper.dart';
import 'report_camera_page.dart';
import '../../../../shared/store/report_store.dart';
import '../../../../features/home/models/home_report_model.dart' as home;

class ReportSuccessPage extends StatefulWidget {
  final ReportModel report;

  const ReportSuccessPage({super.key, required this.report});

  @override
  State<ReportSuccessPage> createState() => _ReportSuccessPageState();
}

class _ReportSuccessPageState extends State<ReportSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _codeCopied = false;

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
    _addToStore();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _addToStore() async {
    try {
      final r = widget.report;
      final homeReport = home.HomeReportModel(
        id: r.id ?? 'report_${DateTime.now().millisecondsSinceEpoch}',
        // ✅ CORRECTION — fallback défensif sur chaîne vide (et non un code
        // factice en dur comme '#CLN-0000'). À ce stade, r.reportCode est
        // normalement déjà renseigné par report_upload_page.dart (génération
        // réelle du code). Si jamais il était vide, MockReportRepository
        // .addReport() détecte reference.isEmpty et génère un vrai code
        // unique au lieu d'écraser tous les signalements avec la même valeur.
        reference: r.reportCode ?? '',
        title: r.title ?? r.category?.label ?? 'Signalement',
        location: r.address ?? '',
        description: r.description ?? '',
        severity: r.severity ?? ReportSeverity.moyen,
        category: r.category ?? ReportCategory.depotsSauvages,
        imageAsset: r.imagePath ?? 'assets/images/depot.jpg',
        // ✅ CORRECTION — '< 1 km' laissait penser à une vraie mesure même
        // quand le GPS échoue totalement. Repli neutre en attendant que
        // UserLocationService calcule la vraie distance à l'affichage.
        distance: '—',
        latitude: r.latitude,
        longitude: r.longitude,
        timeAgo: 'À l\'instant',
        createdAt: r.createdAt ?? DateTime.now(),
        views: 0,
        comments: 0,
        shares: 0,
        signalePar: 'Vous',
        gpsCoords: r.latitude != null
            ? '${r.latitude!.toStringAsFixed(4)}, ${r.longitude!.toStringAsFixed(4)}'
            : null,
      );

      await ReportStore.instance.addReport(homeReport);
    } catch (e) {
      debugPrint('Erreur ajout store : $e');
    }
  }

  // ✅ CORRECTION — copie réellement fonctionnelle, sans message d'échec.
  // copyTextToClipboard() (lib/core/utils/clipboard_helper.dart) retombe
  // automatiquement sur execCommand('copy') si l'API moderne échoue
  // (contexte HTTP non sécurisé) — la copie réussit donc réellement.
  Future<void> _copyCode() async {
    final code = widget.report.reportCode ?? '';
    await copyTextToClipboard(code);
    if (!mounted) return;
    setState(() => _codeCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _continueReporting(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ReportCameraPage()));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const mois = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final jour = date.day.toString().padLeft(2, '0');
    final nomMois = mois[date.month];
    final annee = date.year;
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$jour $nomMois $annee à $heure:$minute';
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
                padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.pagePadding),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: CliinAppConstants.spacingM),
                      const ReportStepper(currentStep: 5),
                      const SizedBox(height: CliinAppConstants.spacingXL),
                      _buildSuccessIcon(),
                      const SizedBox(height: CliinAppConstants.spacingL),
                      _buildSuccessText(),
                      const SizedBox(height: CliinAppConstants.spacingXL),
                      _buildReportCard(),
                      const SizedBox(height: CliinAppConstants.spacingL),
                      _buildMotivationBanner(),
                      const SizedBox(height: CliinAppConstants.spacingXL),
                      _buildNextActionsTitle(),
                      const SizedBox(height: CliinAppConstants.spacingM),
                      _buildNextActionsRow(context),
                      const SizedBox(height: CliinAppConstants.spacingXL),
                      _buildContinueButton(context),
                      const SizedBox(height: CliinAppConstants.spacingXL),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding,
          vertical: CliinAppConstants.spacingM),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _goHome(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
              ),
              child: const Icon(Icons.arrow_back,
                  color: CliinAppColors.primary, size: 20),
            ),
          ),
          Expanded(
            child: Text('Signalement publié !',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: CliinAppColors.textDark)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._buildConfetti(),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: CliinAppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: CliinAppColors.textWhite, size: 44),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConfetti() {
    final positions = [
      const Offset(-50, -30), const Offset(50, -30),
      const Offset(-60, 10),  const Offset(60, 10),
      const Offset(-30, 40),  const Offset(30, 40),
      const Offset(-55, -10), const Offset(55, -10),
    ];
    final colors = [
      CliinAppColors.primary, CliinAppColors.alertOrange,
      const Color(0xFF64B5F6), const Color(0xFFFFD54F),
      CliinAppColors.primary, const Color(0xFF64B5F6),
      CliinAppColors.alertOrange, CliinAppColors.primary,
    ];
    return List.generate(positions.length, (i) => Transform.translate(
      offset: positions[i],
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
            color: colors[i % colors.length],
            borderRadius: BorderRadius.circular(2)),
      ),
    ));
  }

  Widget _buildSuccessText() {
    return Column(children: [
      Text(ReportDummyData.successTitle,
          style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CliinAppColors.textDark)),
      const SizedBox(height: CliinAppConstants.spacingS),
      Text(ReportDummyData.successSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 13, color: CliinAppColors.textSecondary)),
    ]);
  }

  Widget _buildReportCard() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Code du signalement',
            style: GoogleFonts.inter(
                fontSize: 12, color: CliinAppColors.textSecondary)),
        const SizedBox(height: CliinAppConstants.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.spacingL,
              vertical: CliinAppConstants.spacingM),
          decoration: BoxDecoration(
            border: Border.all(color: CliinAppColors.divider),
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
          ),
          child: Row(children: [
            Expanded(
              child: Text(widget.report.reportCode ?? '#CLN-0000',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CliinAppColors.primary)),
            ),
            GestureDetector(
              onTap: _copyCode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.spacingM,
                    vertical: CliinAppConstants.spacingS),
                decoration: BoxDecoration(
                  color: CliinAppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusSmall),
                  border: Border.all(color: CliinAppColors.primary),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      _codeCopied ? Icons.check : Icons.copy_outlined,
                      color: CliinAppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(_codeCopied ? 'Copié !' : 'Copier',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CliinAppColors.primary)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: CliinAppConstants.spacingL),
        const Divider(color: Color(0xFFE0E0E0), height: 1),
        const SizedBox(height: CliinAppConstants.spacingL),
        _InfoRow(
            icon: Icons.access_time_outlined,
            label: 'Publié le',
            value: _formatDate(widget.report.createdAt)),
        const SizedBox(height: CliinAppConstants.spacingM),
        _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Localisation',
            value: widget.report.address ?? ''),
        const SizedBox(height: CliinAppConstants.spacingM),
        _InfoRow(
            icon: Icons.grid_view_outlined,
            label: 'Catégorie',
            value: widget.report.category?.label ?? ''),
        const SizedBox(height: CliinAppConstants.spacingM),
        _SeverityInfoRow(severity: widget.report.severity),
      ]),
    );
  }

  Widget _buildMotivationBanner() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.verified_outlined,
            color: CliinAppColors.primary, size: 22),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ReportDummyData.successMotivationTitle,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
            Text(ReportDummyData.successMotivationText,
                style: GoogleFonts.inter(
                    fontSize: 12, color: CliinAppColors.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildNextActionsTitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(ReportDummyData.successNextActionTitle,
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CliinAppColors.textDark)),
    );
  }

  Widget _buildNextActionsRow(BuildContext context) {
    final actions = [
      _ActionItem(icon: Icons.share_outlined, label: 'Partager\nle signalement'),
      _ActionItem(icon: Icons.visibility_outlined, label: 'Voir mon\nsignalement'),
      _ActionItem(
          icon: Icons.home_outlined,
          label: 'Retour à\nl\'accueil',
          onTap: () => _goHome(context)),
    ];
    return Row(
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return Expanded(
          child: GestureDetector(
            onTap: a.onTap,
            child: Container(
              margin: EdgeInsets.only(
                  right: i < actions.length - 1 ? CliinAppConstants.spacingS : 0),
              padding: const EdgeInsets.symmetric(
                  vertical: CliinAppConstants.spacingL),
              decoration: BoxDecoration(
                color: CliinAppColors.cardWhite,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
                border: Border.all(color: CliinAppColors.divider),
              ),
              child: Column(children: [
                Icon(a.icon, color: CliinAppColors.primary, size: 26),
                const SizedBox(height: CliinAppConstants.spacingS),
                Text(a.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: CliinAppColors.textSecondary)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _continueReporting(context),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: CliinAppColors.primary,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Continuer à signaler',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textWhite)),
          const SizedBox(width: CliinAppConstants.spacingM),
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
                color: CliinAppColors.textWhite, shape: BoxShape.circle),
            child: const Icon(Icons.add,
                color: CliinAppColors.primary, size: 18),
          ),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
            color: CliinAppColors.primaryLight,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Icon(icon, color: CliinAppColors.primary, size: 16),
      ),
      const SizedBox(width: CliinAppConstants.spacingM),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(
              fontSize: 11, color: CliinAppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(
              fontSize: 13, color: CliinAppColors.textDark)),
        ]),
      ),
    ],
  );
}

class _SeverityInfoRow extends StatelessWidget {
  final ReportSeverity? severity;
  const _SeverityInfoRow({required this.severity});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
          color: CliinAppColors.primaryLight,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall)),
      child: const Icon(Icons.flag_outlined,
          color: CliinAppColors.primary, size: 16),
    ),
    const SizedBox(width: CliinAppConstants.spacingM),
    Text('Niveau d\'urgence',
        style: GoogleFonts.inter(fontSize: 13, color: CliinAppColors.textDark)),
    const SizedBox(width: CliinAppConstants.spacingM),
    if (severity != null)
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.spacingM,
            vertical: CliinAppConstants.spacingXS),
        decoration: BoxDecoration(
            color: severity!.bgColor,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(severity!.icon, color: severity!.color, size: 14),
          const SizedBox(width: 4),
          Text(severity!.label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: severity!.color)),
        ]),
      ),
  ]);
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionItem({required this.icon, required this.label, this.onTap});
}