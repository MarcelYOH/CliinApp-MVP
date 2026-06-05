import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// Widget — ReportCameraSideControls
// Contrôles latéraux droits : Flash / Changer caméra / Galerie
// ─────────────────────────────────────────
class ReportCameraSideControls extends StatelessWidget {
  final FlashMode flashMode;
  final VoidCallback onFlashTap;
  final VoidCallback onFlipTap;
  final VoidCallback onGalleryTap;

  const ReportCameraSideControls({
    super.key,
    required this.flashMode,
    required this.onFlashTap,
    required this.onFlipTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideControlButton(
          icon: _flashIcon(flashMode),
          label: 'Flash',
          onTap: onFlashTap,
          isActive: flashMode == FlashMode.torch || flashMode == FlashMode.always,
        ),
        const SizedBox(height: CliinAppConstants.spacingL),
        _SideControlButton(
          icon: Icons.cameraswitch_outlined,
          label: 'Changer\ncaméra',
          onTap: onFlipTap,
        ),
        const SizedBox(height: CliinAppConstants.spacingL),
        _SideControlButton(
          icon: Icons.image_outlined,
          label: 'Galerie',
          onTap: onGalleryTap,
        ),
      ],
    );
  }

  IconData _flashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.torch:
        return Icons.flash_on;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
    }
    // ignore: dead_code
    return Icons.flash_auto;
  }
}

// ─────────────────────────────────────────
// Widget interne — Bouton contrôle latéral
// ─────────────────────────────────────────
class _SideControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _SideControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? CliinAppColors.primary.withValues(alpha: 0.85)
                  : const Color(0xFF2A2A2A).withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: CliinAppColors.textWhite,
              size: 24,
            ),
          ),
          const SizedBox(height: CliinAppConstants.spacingXS),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: CliinAppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}