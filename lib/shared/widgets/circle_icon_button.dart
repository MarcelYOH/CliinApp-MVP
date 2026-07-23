// lib/shared/widgets/circle_icon_button.dart
//
// Bouton rond réutilisé PARTOUT où un bouton retour ou un bouton partager
// apparaît dans l'application : fond vert (CliinAppColors.primary, la même
// couleur que "Suivre" à l'état non-suivi / "Prendre en charge" à l'état
// non pris en charge), icône blanche. Ne jamais recréer localement un
// bouton retour/partager — utiliser CircleIconButton.back / .share, ou le
// constructeur générique avec des couleurs explicites pour les rares cas
// où le fond vert n'a pas de sens visuel (ex: par-dessus une bannière qui
// peut elle-même être verte).

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.backgroundColor = CliinAppColors.primary,
    this.iconColor = CliinAppColors.textWhite,
  });

  // Bouton retour standard — fond vert, flèche blanche.
  const CircleIconButton.back({
    super.key,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.backgroundColor = CliinAppColors.primary,
    this.iconColor = CliinAppColors.textWhite,
  }) : icon = Icons.arrow_back_rounded;

  // Bouton partager standard — même design que le bouton retour.
  const CircleIconButton.share({
    super.key,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.backgroundColor = CliinAppColors.primary,
    this.iconColor = CliinAppColors.textWhite,
  }) : icon = Icons.share_outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
