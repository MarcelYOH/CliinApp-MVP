import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/quick_report_model.dart';

class HomeQuickReport extends StatelessWidget {
  final QuickReportModel data;
  final VoidCallback? onTap;

  const HomeQuickReport({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.pagePadding,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Cercle décoratif arrière-plan ──
          Positioned(
            right: -10,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Contenu ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Textes gauche ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: CliinAppTextStyles.headingMedium.copyWith(
                        color: CliinAppColors.textWhite,
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: CliinAppConstants.spacingXS),
                    Text(
                      data.description,
                      style: CliinAppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: CliinAppConstants.spacingM),

              // ── Bouton signaler ──
              GestureDetector(
                onTap: onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A6B2F),
                        borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Color(0xFF2E7D32),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingXS),
                    Text(
                      data.buttonLabel,
                      style: CliinAppTextStyles.button.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}