import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// Widget — ReportCameraHeader
// AppBar de la page caméra (fond noir)
// ─────────────────────────────────────────
class ReportCameraHeader extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onHelpTap;
  final String title;
  final String? subtitle;

  const ReportCameraHeader({
    super.key,
    required this.onBackTap,
    required this.onHelpTap,
    this.title = 'Signaler un cas d\'insalubrité',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.pagePadding,
        vertical: CliinAppConstants.spacingM,
      ),
      child: Row(
        children: [
          // ── Bouton retour ──
          GestureDetector(
            onTap: onBackTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: CliinAppColors.textWhite,
                size: 20,
              ),
            ),
          ),

          // ── Titre centré ──
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textWhite,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CliinAppColors.textWhite.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Bouton aide ──
          GestureDetector(
            onTap: onHelpTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CliinAppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.question_mark_rounded,
                    color: CliinAppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aide',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: CliinAppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}