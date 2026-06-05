// lib/features/reports/pages/proof_upload_page.dart
// Upload et vérification GPS de la preuve d'intervention
// Simule le processus localement — backend-ready

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/home/models/report_model.dart';
import '../../../../shared/store/report_store.dart';
import 'proof_result_page.dart';

class ProofUploadPage extends StatefulWidget {
  final HomeReportModel report;
  final String imagePath;
  final double proofLatitude;
  final double proofLongitude;

  const ProofUploadPage({
    super.key,
    required this.report,
    required this.imagePath,
    required this.proofLatitude,
    required this.proofLongitude,
  });

  @override
  State<ProofUploadPage> createState() => _ProofUploadPageState();
}

class _ProofUploadPageState extends State<ProofUploadPage> {
  final List<_UploadStep> _steps = [
    _UploadStep(label: 'Compression de la photo', icon: Icons.compress_rounded),
    _UploadStep(label: 'Envoi de la photo', icon: Icons.cloud_upload_outlined),
    _UploadStep(label: 'Vérification GPS AVANT/APRÈS', icon: Icons.my_location_rounded),
    _UploadStep(label: 'Validation de la preuve', icon: Icons.verified_outlined),
    _UploadStep(label: 'Mise à jour du signalement', icon: Icons.update_rounded),
  ];

  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _runUpload();
  }

  Future<void> _runUpload() async {
    final durations = [600, 800, 1000, 700, 500];

    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _steps[i].status = _StepStatus.inProgress;
      });
      await Future.delayed(Duration(milliseconds: durations[i]));
      setState(() => _steps[i].status = _StepStatus.done);
    }

    setState(() => _isDone = true);

    final result = await ReportStore.instance.submitProof(
      reportId: widget.report.id,
      imagePath: widget.imagePath,
      proofLatitude: widget.proofLatitude,
      proofLongitude: widget.proofLongitude,
    );

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProofResultPage(
          report: widget.report,
          result: result,
        ),
      ),
    );
  }

  double get _progress =>
      _steps.where((s) => s.status == _StepStatus.done).length /
      _steps.length;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: CliinAppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.pagePadding),
            child: Column(
              children: [
                const SizedBox(height: CliinAppConstants.spacingXL),

                Text('Vérification en cours',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark)),
                Text('Validation de votre preuve d\'intervention',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CliinAppColors.textSecondary)),

                const SizedBox(height: CliinAppConstants.spacingXL * 2),

                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: CliinAppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: _isDone
                      ? const Icon(Icons.check_circle_rounded,
                          color: CliinAppColors.primary, size: 48)
                      : const Icon(Icons.cloud_upload_outlined,
                          color: CliinAppColors.primary, size: 48),
                ),

                const SizedBox(height: CliinAppConstants.spacingL),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusLarge),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: CliinAppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        CliinAppColors.primary),
                  ),
                ),

                const SizedBox(height: CliinAppConstants.spacingXL),

                Container(
                  padding: const EdgeInsets.all(CliinAppConstants.spacingL),
                  decoration: BoxDecoration(
                    color: CliinAppColors.cardWhite,
                    borderRadius:
                        BorderRadius.circular(CliinAppConstants.radiusMedium),
                    border: Border.all(color: CliinAppColors.divider),
                  ),
                  child: Column(
                    children: _steps.asMap().entries.map((entry) {
                      final i = entry.key;
                      final step = entry.value;
                      final isLast = i == _steps.length - 1;
                      return Column(
                        children: [
                          _StepRow(step: step),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16,
                                  top: CliinAppConstants.spacingXS,
                                  bottom: CliinAppConstants.spacingXS),
                              child: Row(children: [
                                Container(
                                  width: 1.5,
                                  height: 14,
                                  color: step.status == _StepStatus.done
                                      ? CliinAppColors.primary
                                      : CliinAppColors.divider,
                                ),
                              ]),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: CliinAppConstants.spacingXL),

                Container(
                  padding: const EdgeInsets.all(CliinAppConstants.spacingL),
                  decoration: BoxDecoration(
                    color: CliinAppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(CliinAppConstants.radiusMedium),
                  ),
                  child: Row(children: [
                    const Icon(Icons.my_location_rounded,
                        color: CliinAppColors.primary, size: 22),
                    const SizedBox(width: CliinAppConstants.spacingM),
                    Expanded(
                      child: Text(
                        'Les coordonnées GPS de votre photo sont comparées '
                        'avec celles du signalement initial.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: CliinAppColors.textDark),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { waiting, inProgress, done }

class _UploadStep {
  final String label;
  final IconData icon;
  _StepStatus status = _StepStatus.waiting;

  _UploadStep({
    required this.label,
    required this.icon,
  });
}

class _StepRow extends StatelessWidget {
  final _UploadStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 32,
        height: 32,
        child: switch (step.status) {
          _StepStatus.done => Container(
              decoration: const BoxDecoration(
                  color: CliinAppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check,
                  color: Colors.white, size: 16),
            ),
          _StepStatus.inProgress => const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(CliinAppColors.primary),
            ),
          _StepStatus.waiting => Container(
              decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0), shape: BoxShape.circle),
            ),
        },
      ),
      const SizedBox(width: CliinAppConstants.spacingM),
      Icon(step.icon,
          size: 16,
          color: step.status == _StepStatus.done
              ? CliinAppColors.primary
              : CliinAppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(step.label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: step.status == _StepStatus.waiting
                  ? CliinAppColors.textSecondary
                  : CliinAppColors.textDark,
            )),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: switch (step.status) {
            _StepStatus.done       => CliinAppColors.primaryLight,
            _StepStatus.inProgress => const Color(0xFFFFF3E0),
            _StepStatus.waiting    => const Color(0xFFF5F5F5),
          },
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusSmall),
        ),
        child: Text(
          switch (step.status) {
            _StepStatus.done       => 'Terminé',
            _StepStatus.inProgress => 'En cours',
            _StepStatus.waiting    => 'En attente',
          },
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: switch (step.status) {
              _StepStatus.done       => CliinAppColors.primary,
              _StepStatus.inProgress => CliinAppColors.alertOrange,
              _StepStatus.waiting    => CliinAppColors.textSecondary,
            },
          ),
        ),
      ),
    ]);
  }
}