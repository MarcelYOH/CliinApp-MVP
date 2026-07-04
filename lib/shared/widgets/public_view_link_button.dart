// lib/shared/widgets/public_view_link_button.dart
// Lien discret vers l'affichage public d'un cas — utilisé depuis les pages
// privées (ReportDetailPage isAuthor, IntervenantDetailPage).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class PublicViewLinkButton extends StatelessWidget {
  final VoidCallback onTap;
  const PublicViewLinkButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.visibility_outlined,
            color: CliinAppColors.textSecondary, size: 18),
        label: Text('Voir l\'affichage public',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textSecondary)),
        style: OutlinedButton.styleFrom(
          backgroundColor: CliinAppColors.cardWhite,
          side: const BorderSide(color: CliinAppColors.divider),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
        ),
      ),
    );
  }
}
