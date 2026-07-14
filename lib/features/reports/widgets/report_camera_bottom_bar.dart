import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// Widget — ReportCameraBottomBar
// Barre bas : Position automatique + Shutter + Texte conseil
// ─────────────────────────────────────────
class ReportCameraBottomBar extends StatelessWidget {
  final VoidCallback onShutterTap;
  final bool isCapturing;
  // Photo de profil : ni position automatique (aucun sens pour un avatar)
  // ni texte de conseil signalement en dessous du shutter.
  final bool isAvatarMode;

  const ReportCameraBottomBar({
    super.key,
    required this.onShutterTap,
    this.isCapturing = false,
    this.isAvatarMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Ligne : Position auto + Shutter ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.spacingXL,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Position automatique (absente en mode photo de profil) ──
              isAvatarMode ? const SizedBox(width: 72) : _PositionAutoButton(),

              // ── Bouton Shutter central ──
              _ShutterButton(
                onTap: onShutterTap,
                isCapturing: isCapturing,
              ),

              // ── Espace symétrique ──
              const SizedBox(width: 72),
            ],
          ),
        ),

        // ── Texte conseil bas (absent en mode photo de profil) ──
        if (!isAvatarMode) ...[
          const SizedBox(height: CliinAppConstants.spacingL),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding,
            ),
            child: Column(
              children: [
                Text(
                  'Assurez-vous que le problème est bien visible.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: CliinAppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: CliinAppColors.textWhite,
                    ),
                    children: [
                      const TextSpan(text: 'Une bonne photo aide '),
                      TextSpan(
                        text: 'la communauté à agir.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CliinAppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────
// Widget interne — Bouton Position Auto
// ─────────────────────────────────────────
class _PositionAutoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x66FFFFFF), // white 40%
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.person_pin_circle_outlined,
            color: CliinAppColors.textWhite,
            size: 26,
          ),
        ),
        const SizedBox(height: CliinAppConstants.spacingXS),
        Text(
          'Position\nautomatique',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: CliinAppColors.textWhite,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Widget interne — Bouton Shutter
// ─────────────────────────────────────────
class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCapturing;

  const _ShutterButton({
    required this.onTap,
    required this.isCapturing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: CliinAppColors.primary,
            width: 4,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isCapturing ? 50 : 62,
            height: isCapturing ? 50 : 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CliinAppColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }
}