// lib/features/reports/pages/proof_preview_page.dart
// Aperçu professionnel de la photo de preuve avant envoi
// Design identique à ReportPreviewPage du module signalement

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/user_location_service.dart';
import '../../../../features/home/models/home_report_model.dart';
import 'proof_camera_page.dart';
import 'proof_upload_page.dart';
import '../../../../shared/navigation/fast_page_route.dart';

class ProofPreviewPage extends StatelessWidget {
  final HomeReportModel report;
  final String imagePath;
  final String address;
  final double proofLatitude;
  final double proofLongitude;
  final double? proofAccuracy;

  const ProofPreviewPage({
    super.key,
    required this.report,
    required this.imagePath,
    required this.address,
    required this.proofLatitude,
    required this.proofLongitude,
    this.proofAccuracy,
  });

  bool get _isImprecise =>
      proofAccuracy != null &&
      proofAccuracy! > UserLocationService.approximateAccuracyMeters;

  void _reprendre(BuildContext context) {
    // Retour à la caméra — remplace la page actuelle
    Navigator.pushReplacement(
      context,
      fastFadeRoute<void>(ProofCameraPage(report: report)),
    );
  }

  void _continuer(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProofUploadPage(
          report: report,
          imagePath: imagePath,
          proofLatitude: proofLatitude,
          proofLongitude: proofLongitude,
          proofAccuracy: proofAccuracy,
        ),
      ),
    );
  }

  Widget _imageError() => Container(
    color: CliinAppColors.background,
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined,
          size: 48, color: CliinAppColors.textSecondary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
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
                const SizedBox(width: CliinAppConstants.spacingM),
                Text('Aperçu de la preuve',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark)),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Bannière vérification ──────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: CliinAppColors.primaryLight,
                        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(
                              color: CliinAppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.verified_user_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: CliinAppConstants.spacingM),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Vérifiez votre photo',
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.bold,
                                    color: CliinAppColors.textDark)),
                            Text('Assurez-vous que le traitement est bien visible.',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: CliinAppColors.textSecondary)),
                          ]),
                        ),
                      ]),
                    ),

                    const SizedBox(height: CliinAppConstants.spacingL),

                    // ── Photo plein cadre ───────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: kIsWeb
                            ? Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _imageError(),
                              )
                            : Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _imageError(),
                              ),
                      ),
                    ),

                    const SizedBox(height: CliinAppConstants.spacingL),

                    // ── Position détectée + Modifier ────────────
                    Container(
                      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: CliinAppColors.cardWhite,
                        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
                        border: Border.all(color: CliinAppColors.divider),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: CliinAppColors.primary, size: 20),
                        const SizedBox(width: CliinAppConstants.spacingS),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Position détectée',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: CliinAppColors.textSecondary)),
                            Text(address,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.bold,
                                    color: CliinAppColors.textDark),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (_isImprecise) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Précision GPS faible (~${proofAccuracy!.round()} m) '
                                '— la vérification anti-fraude attendra une '
                                'meilleure position avant de valider ou rejeter.',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: CliinAppColors.alertOrange),
                              ),
                            ],
                          ]),
                        ),
                      ]),
                    ),

                    const SizedBox(height: CliinAppConstants.spacingXL),
                  ],
                ),
              ),
            ),

            // ── Boutons Reprendre / Continuer ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding, 0,
                  CliinAppConstants.pagePadding, CliinAppConstants.spacingM),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reprendre(context),
                    icon: const Icon(Icons.camera_alt_outlined,
                        size: 18, color: CliinAppColors.primary),
                    label: Text('Reprendre',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: CliinAppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: CliinAppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
                    ),
                  ),
                ),
                const SizedBox(width: CliinAppConstants.spacingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _continuer(context),
                    icon: const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.white),
                    label: Text('Continuer',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CliinAppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
                    ),
                  ),
                ),
              ]),
            ),

            // Footer hint
            Padding(
              padding: const EdgeInsets.only(bottom: CliinAppConstants.spacingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 14, color: CliinAppColors.primary),
                  const SizedBox(width: 6),
                  Text('Votre preuve aide à valider le traitement du cas.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: CliinAppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}