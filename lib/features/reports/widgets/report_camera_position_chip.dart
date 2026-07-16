import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// Widget — ReportCameraPositionChip
// Chip "Position détectée" affiché en bas du viewfinder
// ─────────────────────────────────────────
class ReportCameraPositionChip extends StatelessWidget {
  final String address;
  final bool isLoading;
  // Texte discret affiché sous l'adresse quand la position GPS est encore
  // imprécise (accuracy > seuil) — null quand tout va bien.
  final String? warningText;

  const ReportCameraPositionChip({
    super.key,
    required this.address,
    this.isLoading = false,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.spacingL,
        vertical: CliinAppConstants.spacingM,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Icône position ──
          const Icon(
            Icons.location_on,
            color: CliinAppColors.primary,
            size: 18,
          ),
          const SizedBox(width: CliinAppConstants.spacingS),

          // ── Textes ──
          isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CliinAppColors.primary,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Position détectée',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: CliinAppColors.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      address,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CliinAppColors.textWhite,
                      ),
                    ),
                    if (warningText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        warningText!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CliinAppColors.alertOrange,
                        ),
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}