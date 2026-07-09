// lib/shared/widgets/more_menu_sheet.dart
// Bottom sheet "Plus" — modules à venir de CliinApp
//
// Liste d'entrées déclarative (_entries) : ajouter un futur module
// (Marketplace, E-learning, ...) se fait en ajoutant une ligne à la
// liste, sans réécrire la structure du sheet.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

Future<void> showMoreMenuSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MoreMenuSheet(),
  );
}

class _MoreMenuEntry {
  final IconData icon;
  final String label;
  const _MoreMenuEntry({required this.icon, required this.label});
}

class _MoreMenuSheet extends StatelessWidget {
  const _MoreMenuSheet();

  static const List<_MoreMenuEntry> _entries = [
    _MoreMenuEntry(icon: Icons.bolt_rounded, label: 'Actions Terrains'),
  ];

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bientôt disponible'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CliinAppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Plus de modules',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ces fonctionnalités arrivent bientôt.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CliinAppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              for (final entry in _entries) ...[
                _MoreMenuItem(
                  icon: entry.icon,
                  label: entry.label,
                  onTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CliinAppColors.background,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: CliinAppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CliinAppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CliinAppColors.divider),
              ),
              child: Text(
                'Bientôt',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
