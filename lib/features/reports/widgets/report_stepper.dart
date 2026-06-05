import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────
// Widget — ReportStepper
// Indicateur d'étapes partagé (pages 2→5)
// ─────────────────────────────────────────
class ReportStepper extends StatelessWidget {
  final int currentStep; // 1-based : 1=Photo, 2=Aperçu, 3=Infos, 4=Publication, 5=Confirmation

  const ReportStepper({
    super.key,
    required this.currentStep,
  });

  static const List<String> _labels = [
    'Photo',
    'Aperçu',
    'Infos',
    'Publication',
    'Confirmation',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CliinAppConstants.pagePadding,
        vertical: CliinAppConstants.spacingM,
      ),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (index) {
          // Connecteur entre étapes
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep - 1;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? CliinAppColors.primary
                    : const Color(0xFFE0E0E0),
              ),
            );
          }

          // Cercle d'étape
          final stepIndex = index ~/ 2;
          final stepNumber = stepIndex + 1;
          final isCompleted = stepNumber < currentStep;
          final isCurrent = stepNumber == currentStep;
          final isPending = stepNumber > currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Cercle ──
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPending
                      ? const Color(0xFFE0E0E0)
                      : CliinAppColors.primary,
                  border: isCurrent
                      ? Border.all(
                          color: CliinAppColors.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: CliinAppColors.textWhite,
                          size: 16,
                        )
                      : Text(
                          '$stepNumber',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isPending
                                ? const Color(0xFF9E9E9E)
                                : CliinAppColors.textWhite,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: CliinAppConstants.spacingXS),

              // ── Label ──
              Text(
                _labels[stepIndex],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isPending
                      ? const Color(0xFF9E9E9E)
                      : CliinAppColors.primary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}