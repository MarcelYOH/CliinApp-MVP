// lib/features/home/widgets/home_alert_banner.dart
// Bannière Alerte — CliinApp

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/alert_banner_model.dart';

class HomeAlertBanner extends StatelessWidget {
  final AlertBannerModel data;
  final VoidCallback? onVoirTap;

  const HomeAlertBanner({
    super.key,
    required this.data,
    this.onVoirTap,
  });

  static const Color _kAlertRed      = Color(0xFFE8412A);
  static const Color _kAlertRedPill  = Color(0xFFFFDAD6);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.pagePadding,
      ),
      // ── Hauteur réduite, le contenu dicte la taille ──
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        // Fond blanc plein (au lieu d'un rose pâle proche du blanc) pour un
        // contraste maximal avec le texte foncé, lisible en plein soleil.
        color: CliinAppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: _kAlertRed.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── BLOC GAUCHE rouge avec radar ──
              _buildLeftBlock(),

              // ── BLOC DROIT contenu ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildTextContent()),
                      const SizedBox(width: CliinAppConstants.spacingS),
                      _buildVoirButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftBlock() {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF5350), Color(0xFFE8412A)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRadarCircle(54, 0.10),
          _buildRadarCircle(36, 0.16),
          _buildRadarCircle(20, 0.22),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge ⚡ ALERTE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _kAlertRedPill,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: _kAlertRed, size: 11),
              const SizedBox(width: 3),
              Text(
                data.badgeLabel,
                style: CliinAppTextStyles.badge.copyWith(
                  fontSize: 9,
                  color: _kAlertRed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),

        // Ligne 1 + Ligne 2 en RichText — maxLines: 2, pas de coupure
        RichText(
          maxLines: 3,
          overflow: TextOverflow.visible,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${data.textLine1}\n',
                style: CliinAppTextStyles.bodyMedium.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: CliinAppColors.textDark,
                  height: 1.35,
                ),
              ),
              TextSpan(
                text: data.textLine2Prefix,
                style: CliinAppTextStyles.bodyMedium.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: CliinAppColors.textDark,
                  height: 1.35,
                ),
              ),
              TextSpan(
                text: data.textLine2Highlight,
                style: CliinAppTextStyles.bodyMedium.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _kAlertRed,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoirButton() {
    return GestureDetector(
      onTap: onVoirTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(color: _kAlertRed, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.buttonLabel,
              style: CliinAppTextStyles.badge.copyWith(
                fontSize: 11,
                color: _kAlertRed,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right, color: _kAlertRed, size: 13),
          ],
        ),
      ),
    );
  }
}