// lib/features/home/widgets/home_action_banner.dart
// Section "Actions terrain" — page d'accueil — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/action_banner_model.dart';

class HomeActionBanner extends StatelessWidget {
  final ActionBannerModel data;
  final VoidCallback? onTap;

  const HomeActionBanner({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actions terrain',
                  style: CliinAppTextStyles.headingMedium
                      .copyWith(color: CliinAppColors.textDark)),
              GestureDetector(
                onTap: onTap,
                child: Row(children: [
                  Text('Voir plus',
                      style: CliinAppTextStyles.link.copyWith(fontSize: 13)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right,
                      color: CliinAppColors.primary, size: 18),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: CliinAppConstants.spacingM),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: CliinAppColors.cardWhite,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
                // IntrinsicHeight : sans hauteur fixe, permet à la Row de
                // dimensionner la photo (stretch) sur la hauteur réelle du
                // contenu texte, quel que soit le nombre de lignes de la
                // description (jamais tronquée, voir _buildDescription).
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImageSection(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBadge(),
                              const SizedBox(height: 6),
                              _buildTitle(),
                              const SizedBox(height: 6),
                              _buildDividerLine(),
                              const SizedBox(height: 8),
                              _buildDescription(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Image gauche avec dégradé fondu vers droite ──
  Widget _buildImageSection() {
    return SizedBox(
      width: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            data.imageAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, color: Colors.grey, size: 40),
            ),
          ),
          // Fondu léger vers la droite — stops resserrés pour réduire le nuage blanc
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    CliinAppColors.cardWhite.withValues(alpha: 0.3),
                    CliinAppColors.cardWhite,
                  ],
                  stops: const [0.82, 0.95, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Badge pill 🌿 ──
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, color: CliinAppColors.primary, size: 14),
          const SizedBox(width: 4),
          Text(
            data.badgeLabel,
            style: CliinAppTextStyles.badge.copyWith(
              color: CliinAppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Titre ──
  Widget _buildTitle() {
    return Text(
      data.title,
      style: CliinAppTextStyles.headingMedium.copyWith(
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: CliinAppColors.primaryDark,
        height: 1.2,
      ),
    );
  }

  // ── Ligne décorative verte ──
  Widget _buildDividerLine() {
    return Container(
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: CliinAppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Description — jamais tronquée (Correction 1) ──
  Widget _buildDescription() {
    return Text(
      data.description,
      style: CliinAppTextStyles.bodySmall.copyWith(
        fontSize: 11,
        color: CliinAppColors.textSecondary,
        height: 1.4,
      ),
    );
  }
}
