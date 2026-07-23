import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/report_model.dart';
import '../data/report_dummy_data.dart';
import '../widgets/report_stepper.dart';
import '../widgets/attribution_choice_sheet.dart';
import 'report_success_page.dart';

// ─────────────────────────────────────────────────────────────────
// CORRECTION — Génération réelle du code de signalement
// ─────────────────────────────────────────────────────────────────
// Avant : reportCode était codé en dur ('#CLN-6589'), donc TOUS les
// signalements créés affichaient exactement le même code.
// Maintenant : un code aléatoire est généré ici (une seule fois), puis
// transmis tel quel à ReportSuccessPage → cohérence garantie entre le
// code affiché à l'écran de confirmation et celui stocké dans le store.
String _generateReportCode() {
  final n = 1000 + Random().nextInt(8999);
  return '#CLN-$n';
}

class ReportUploadPage extends StatefulWidget {
  final ReportModel report;
  const ReportUploadPage({super.key, required this.report});

  @override
  State<ReportUploadPage> createState() => _ReportUploadPageState();
}

class _ReportUploadPageState extends State<ReportUploadPage>
    with SingleTickerProviderStateMixin {
  late List<ReportUploadStepModel> _steps;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _steps = ReportUploadStep.values
        .map((s) => ReportUploadStepModel(
              step: s,
              status: UploadStepStatus.enAttente,
            ))
        .toList();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _simulateUpload();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _simulateUpload() async {
    final durations = [800, 1000, 1200, 800, 600];
    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _steps[i] = _steps[i].copyWith(status: UploadStepStatus.enCours);
      });
      await Future.delayed(Duration(milliseconds: durations[i]));
      setState(() {
        _steps[i] = _steps[i].copyWith(status: UploadStepStatus.termine);
      });
    }

    // ✅ ReportWorkflowStatus (renommé pour éviter conflit avec shared/report_status.dart)
    // ✅ CORRECTION : code généré réellement, ne réutilise l'existant que
    //    s'il a déjà été défini plus tôt dans le flow (ne devrait pas
    //    arriver normalement, mais on respecte le code déjà présent).
    final publishedReport = widget.report.copyWith(
      reportCode: widget.report.reportCode ?? _generateReportCode(),
      createdAt: DateTime.now(),
      status: ReportWorkflowStatus.enAttente,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('[ATTRIBUTION-DEBUG] creation: après délai, mounted=$mounted');
    if (!mounted) return;

    debugPrint('[ATTRIBUTION-DEBUG] creation: appel showAttributionChoiceSheet');
    final attribution = await showAttributionChoiceSheet(context);
    debugPrint('[ATTRIBUTION-DEBUG] creation: résultat reçu = '
        'nom=${attribution.signaleParNom} groupId=${attribution.groupId} '
        'anonyme=${attribution.isAnonyme}, mounted=$mounted');
    if (!mounted) return;

    final attributedReport = publishedReport.copyWith(
      signaleParNom: attribution.signaleParNom,
      signaleParId: attribution.signaleParId,
      groupId: attribution.groupId,
      isAnonyme: attribution.isAnonyme,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReportSuccessPage(report: attributedReport),
      ),
    );
  }

  double get _progressValue =>
      _steps.where((s) => s.status == UploadStepStatus.termine).length /
      _steps.length;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: CliinAppColors.background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              CliinAppConstants.pagePadding,
              MediaQuery.of(context).padding.top,
              CliinAppConstants.pagePadding,
              MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: CliinAppConstants.spacingM),
                _buildHeader(),
                const SizedBox(height: CliinAppConstants.spacingM),
                const ReportStepper(currentStep: 4),
                const SizedBox(height: CliinAppConstants.spacingXL * 2),
                _buildUploadAnimation(),
                const SizedBox(height: CliinAppConstants.spacingXL),
                _buildTitleSubtitle(),
                const SizedBox(height: CliinAppConstants.spacingXL),
                _buildStepsList(),
                const SizedBox(height: CliinAppConstants.spacingXL),
                _buildMotivationBanner(),
                const SizedBox(height: CliinAppConstants.spacingL),
                _buildDidYouKnowBanner(),
                const SizedBox(height: CliinAppConstants.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Publication en cours',
          style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CliinAppColors.textDark),
        ),
        Text(
          'Votre signalement est en cours d\'envoi',
          style: GoogleFonts.inter(
              fontSize: 13, color: CliinAppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildUploadAnimation() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: CliinAppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            color: CliinAppColors.primary,
            size: 52,
          ),
        ),
        const SizedBox(height: CliinAppConstants.spacingL),
        ClipRRect(
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          child: LinearProgressIndicator(
            value: _progressValue,
            minHeight: 10,
            backgroundColor: CliinAppColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(
                CliinAppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSubtitle() {
    return Column(
      children: [
        Text(
          ReportDummyData.uploadTitle,
          style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CliinAppColors.textDark),
        ),
        const SizedBox(height: CliinAppConstants.spacingS),
        Text(
          ReportDummyData.uploadSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 13, color: CliinAppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStepsList() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(
        children: _steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == _steps.length - 1;
          return Column(
            children: [
              _UploadStepRow(stepModel: step),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: CliinAppConstants.spacingXS,
                    bottom: CliinAppConstants.spacingXS,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 1.5,
                        height: 16,
                        color: step.status == UploadStepStatus.termine
                            ? CliinAppColors.primary
                            : CliinAppColors.divider,
                      ),
                    ],
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMotivationBanner() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined,
              color: CliinAppColors.primary, size: 22),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Text(
              ReportDummyData.uploadMotivationText,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDidYouKnowBanner() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: CliinAppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: CliinAppColors.textWhite, size: 18),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReportDummyData.uploadDidYouKnowTitle,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.textDark),
                ),
                const SizedBox(height: CliinAppConstants.spacingXS),
                Text(
                  ReportDummyData.uploadDidYouKnowText,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: CliinAppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadStepRow extends StatelessWidget {
  final ReportUploadStepModel stepModel;
  const _UploadStepRow({required this.stepModel});

  @override
  Widget build(BuildContext context) {
    final isTermine  = stepModel.status == UploadStepStatus.termine;
    final isEnCours  = stepModel.status == UploadStepStatus.enCours;
    final isEnAttente = stepModel.status == UploadStepStatus.enAttente;

    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: isTermine
              ? Container(
                  decoration: const BoxDecoration(
                    color: CliinAppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: CliinAppColors.textWhite, size: 16),
                )
              : isEnCours
                  ? const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          CliinAppColors.primary),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                    ),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepModel.step.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isEnAttente
                      ? CliinAppColors.textSecondary
                      : CliinAppColors.textDark,
                ),
              ),
              Text(
                stepModel.step.description,
                style: GoogleFonts.inter(
                    fontSize: 11, color: CliinAppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.spacingM,
              vertical: CliinAppConstants.spacingXS),
          decoration: BoxDecoration(
            color: isTermine
                ? CliinAppColors.primaryLight
                : isEnCours
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFF5F5F5),
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall),
          ),
          child: Text(
            stepModel.status.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isTermine
                  ? CliinAppColors.primary
                  : isEnCours
                      ? CliinAppColors.alertOrange
                      : CliinAppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}