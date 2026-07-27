// lib/shared/widgets/action_type_chip.dart
// Chip réutilisable affichant icône + couleur + label d'un ActionType.
// Deux variantes : compacte (rond coloré + label, ActionCard) et étendue
// (icône + label sur fond teinté, formulaire de création + page détails).

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/actions/models/action_model.dart';

class ActionTypeChip extends StatelessWidget {
  final ActionType type;
  final bool extended;

  const ActionTypeChip({
    super.key,
    required this.type,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, color: type.color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                type.label,
                style: CliinAppTextStyles.bodyMedium.copyWith(
                  color: type.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: type.color, shape: BoxShape.circle),
          child: Icon(type.icon, color: CliinAppColors.textWhite, size: 14),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            type.label,
            style: CliinAppTextStyles.headingSmall.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: CliinAppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
