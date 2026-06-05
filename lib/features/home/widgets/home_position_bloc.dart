import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/position_model.dart';

class HomePositionBloc extends StatelessWidget {
  final PositionModel position;

  const HomePositionBloc({
    super.key,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.pagePadding,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Ma position ──
          Expanded(
            child: _buildPositionItem(
              icon: Icons.location_on,
              label: position.label,
              value: position.value,
            ),
          ),

          // ── Séparateur ──
          Container(
            width: 1,
            height: 36,
            color: CliinAppColors.divider,
          ),

          const SizedBox(width: 14),

          // ── Autour de moi ──
          Expanded(
            child: _buildPositionItem(
              icon: Icons.my_location,
              label: position.radiusLabel,
              value: 'Rayon : ${position.radiusKm.toInt()} km',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: CliinAppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: CliinAppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}