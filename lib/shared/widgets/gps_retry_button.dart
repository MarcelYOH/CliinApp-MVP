// lib/shared/widgets/gps_retry_button.dart
// Bouton "Réessayer/Actualiser la détection GPS" — réutilisable partout où
// une position est détectée automatiquement (création de signalement,
// création de groupe, et futur module Actions Terrain — champ lieu de
// l'action, à brancher ici même le moment venu plutôt que de dupliquer).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class GpsRetryButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  const GpsRetryButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.label = 'Réessayer la détection GPS',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CliinAppColors.primary,
                  ),
                )
              : const Icon(Icons.refresh, color: CliinAppColors.primary, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CliinAppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
