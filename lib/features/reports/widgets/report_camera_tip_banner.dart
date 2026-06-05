import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// Widget — ReportCameraTipBanner
// Bandeau conseil blanc en haut du viewfinder
// ─────────────────────────────────────────
class ReportCameraTipBanner extends StatelessWidget {
  final String text;
  final String highlightWord;

  const ReportCameraTipBanner({
    super.key,
    required this.text,
    required this.highlightWord,
  });

  @override
  Widget build(BuildContext context) {
    // Séparer le texte pour mettre en valeur le mot clé
    final parts = text.split(highlightWord);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.pagePadding,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.spacingL,
        vertical: CliinAppConstants.spacingM,
      ),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Row(
        children: [
          // ── Icône caméra verte ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CliinAppColors.primary,
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: CliinAppColors.textWhite,
              size: 22,
            ),
          ),

          const SizedBox(width: CliinAppConstants.spacingM),

          // ── Texte avec mot clé mis en valeur ──
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: CliinAppColors.textDark,
                  height: 1.4,
                ),
                children: [
                  if (parts.isNotEmpty) TextSpan(text: parts[0]),
                  TextSpan(
                    text: highlightWord,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.primary,
                    ),
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}