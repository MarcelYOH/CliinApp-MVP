// lib/features/home/widgets/home_action_banner.dart
// Bannière Action Citoyenne — CliinApp

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

  static const Color _kGreenDark  = Color(0xFF1A6B2F);
  static const Color _kGreenBadge = Color(0xFFE6F7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.pagePadding,
      ),
      height: 192,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── IMAGE GAUCHE avec fondu ──
            _buildImageSection(),

            // ── CONTENU DROIT ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge(),
                    const SizedBox(height: 6),
                    _buildTitle(),
                    const SizedBox(height: 6),
                    _buildDividerLine(),
                    const SizedBox(height: 8),
                    _buildDescription(),
                    const SizedBox(height: 10),
                    _buildButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image gauche avec dégradé fondu vers droite ──
  Widget _buildImageSection() {
    return SizedBox(
      width: 130,
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

  // ── Badge pill 🍃 ──
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kGreenBadge,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, color: Color(0xFF2DB84B), size: 14),
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
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _kGreenDark,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Ligne décorative verte ──
  Widget _buildDividerLine() {
    return Container(
      width: 28,
      height: 2.5,
      decoration: BoxDecoration(
        color: CliinAppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Description ──
  Widget _buildDescription() {
    return Text(
      data.description,
      style: CliinAppTextStyles.bodySmall.copyWith(
        fontSize: 11,
        color: CliinAppColors.textSecondary,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Bouton vert foncé compact ──
  Widget _buildButton() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kGreenDark,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.eco_rounded, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                data.buttonLabel,
                style: CliinAppTextStyles.button.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}