// lib/shared/widgets/more_menu_sheet.dart
// Bottom sheet "Plus" — continuité visuelle de la bottom bar — CliinApp
//
// Grille de tuiles dans le même langage visuel que AppBottomNav (icône
// dans un cercle + libellé dessous) : le sheet prolonge la barre de
// navigation plutôt que d'ouvrir un menu au style générique différent.
// Ajouter un futur module se fait en ajoutant une ligne à _entries, sans
// réécrire la structure du sheet.

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

void _openActionTerrain(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Action Terrain — module en cours de déploiement.'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );
}

class _MoreMenuEntry {
  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;
  const _MoreMenuEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _MoreMenuSheet extends StatelessWidget {
  const _MoreMenuSheet();

  // Seul module réellement en cours d'implémentation — pas de placeholder
  // pour des fonctionnalités hypothétiques (ex: tableau de bord public,
  // déjà écarté du MVP).
  static const List<_MoreMenuEntry> _entries = [
    _MoreMenuEntry(
      icon: Icons.bolt_rounded,
      label: 'Action\nTerrain',
      onTap: _openActionTerrain,
    ),
  ];

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Plus',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 20,
                children: [
                  for (final entry in _entries)
                    _MoreMenuTile(
                      icon: entry.icon,
                      label: entry.label,
                      onTap: () => entry.onTap(context),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Tuile — même langage visuel que les items de AppBottomNav (icône dans
// un cercle plein + libellé dessous), pour prolonger la bottom bar.
// ─────────────────────────────────────────
class _MoreMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: CliinAppColors.primary, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CliinAppColors.textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
