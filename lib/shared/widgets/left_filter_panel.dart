// lib/shared/widgets/left_filter_panel.dart
//
// Panneau de filtres ancré sur le CÔTÉ GAUCHE de l'écran — jamais un
// dialogue centré ni un bottom sheet classique (Correction 2, module
// Groupes : "Groupes actifs", "Découvrir", "Mes groupes"). Glisse depuis la
// gauche, pleine hauteur, largeur partielle — le reste de l'écran reste
// visible en surimpression sombre et cliquable pour fermer. Réutilisé
// partout où ce même bouton "Filtres" existe, jamais reconstruit
// localement.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

Future<void> showLeftFilterPanel(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final width = MediaQuery.of(context).size.width * 0.82;
  // DEBUG TEMPORAIRE (diagnostic Correction 2) — à retirer après validation.
  debugPrint('[FILTER-DEBUG] showLeftFilterPanel() — alignment=Alignment.centerLeft, '
      'width=$width (82% de ${MediaQuery.of(context).size.width})');
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Filtres',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) => Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: CliinAppColors.cardWhite,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: SafeArea(child: Builder(builder: builder)),
        ),
      ),
    ),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
