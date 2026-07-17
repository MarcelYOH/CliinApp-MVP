// lib/shared/widgets/more_menu_sheet.dart
// Bottom sheet "Plus" — continuité visuelle de la bottom bar — CliinApp
//
// Liste de barres horizontales (icône + libellé sur une ligne) : ce sheet
// regroupe les fonctionnalités à venir, une par ligne. Ajouter un futur
// module se fait en ajoutant une ligne à _entries, sans réécrire la
// structure du sheet.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

// showModalBottomSheet pousse son contenu au-dessus de la route entière,
// y compris la Scaffold.bottomNavigationBar : par défaut, la barre du bas
// (et donc l'icône "Plus" censée passer en vert) se retrouve donc
// entièrement recouverte par le sheet + son voile semi-transparent tant
// qu'il est ouvert — invisible pour l'utilisateur, quel que soit l'état
// isMoreMenuOpen. On construit ici un contenu qui occupe toute la hauteur
// de l'écran mais laisse une bande transparente (et non cliquable côté
// sheet, IgnorePointer) exactement à la hauteur de la barre de nav, pour
// que celle-ci reste visible et interactive par-dessous — c'est ce qui
// permet à "Plus" d'apparaître réellement vert pendant que le menu est
// ouvert.
Future<void> showMoreMenuSheet(BuildContext context) {
  final double navBarHeight = 80 + MediaQuery.of(context).padding.bottom;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(sheetContext).maybePop(),
              child: Container(color: Colors.black54),
            ),
          ),
          const _MoreMenuSheet(),
          IgnorePointer(
            child: SizedBox(height: navBarHeight),
          ),
        ],
      ),
    ),
  );
}

void _openActionTerrain(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Campagnes organisées — module en cours de déploiement.'),
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
      // "Voir les campagnes organisées" ne tient pas sur une ligne dans
      // l'espace disponible (icône + chevron) sur les petits écrans —
      // version courte retenue comme prévu si le libellé long débordait.
      label: 'Voir les campagnes',
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
              Column(
                children: [
                  for (final entry in _entries)
                    _MoreMenuBar(
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
// Barre horizontale — une fonctionnalité à venir par ligne : icône dans
// un cercle plein + libellé, sur toute la largeur du sheet.
// ─────────────────────────────────────────
class _MoreMenuBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuBar({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CliinAppColors.primaryLight,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: CliinAppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CliinAppColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CliinAppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
