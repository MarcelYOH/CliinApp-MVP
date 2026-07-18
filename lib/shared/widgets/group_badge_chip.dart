// lib/shared/widgets/group_badge_chip.dart
// Badge de niveau d'un groupe — Engagé -> Impact -> Officiel (ordre de
// progression fixe). Réutilisé partout où un badge de groupe est affiché.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

// Ordre d'affichage fixe, quel que soit l'ordre dans GroupModel.badges.
const List<String> kGroupBadgeOrder = ['engage', 'impact', 'officiel'];

String groupBadgeLabel(String badge) => switch (badge) {
      'engage' => 'Engagé',
      'impact' => 'Impact',
      'officiel' => 'Officiel',
      _ => badge,
    };

Color groupBadgeColor(String badge) => switch (badge) {
      'engage' => CliinAppColors.levelEngage,
      'officiel' => CliinAppColors.levelOfficiel,
      'impact' => CliinAppColors.primary,
      _ => CliinAppColors.primary,
    };

class GroupBadgeChip extends StatelessWidget {
  final String badge;

  const GroupBadgeChip({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: groupBadgeColor(badge),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        groupBadgeLabel(badge).toUpperCase(),
        style: CliinAppTextStyles.badge.copyWith(
          color: CliinAppColors.textWhite,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
