// lib/features/auth/widgets/auth_stepper.dart
// Stepper 3 étapes : Méthode → Vérification → Profil (images 2 à 5)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

enum AuthStepperState {
  method,        // phone/email entry  — step1=done, step2=active, step3=pending
  verify,        // OTP verification   — step1=done+✓, step2=active, step3=pending
  verifyError,   // OTP error          — step1=done+✓, step2=error, step3=pending
  profile,       // profile setup      — step1=done+✓, step2=done+✓, step3=active
}

class AuthStepper extends StatelessWidget {
  final AuthStepperState state;

  const AuthStepper({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStep(
          number: 1,
          label: 'Méthode',
          circleColor: CliinAppColors.primary,
          labelColor: CliinAppColors.textSecondary,
          showCheck: state != AuthStepperState.method,
          isActive: false,
          isError: false,
        ),
        _buildConnector(
          color: CliinAppColors.primary,
        ),
        _buildStep(
          number: 2,
          label: 'Vérification',
          circleColor: state == AuthStepperState.method ||
                  state == AuthStepperState.verify ||
                  state == AuthStepperState.verifyError
              ? CliinAppColors.primary
              : CliinAppColors.primary,
          labelColor: (state == AuthStepperState.method ||
                  state == AuthStepperState.verify ||
                  state == AuthStepperState.verifyError)
              ? CliinAppColors.textDark
              : CliinAppColors.textSecondary,
          showCheck: state == AuthStepperState.profile,
          isActive: state == AuthStepperState.method ||
              state == AuthStepperState.verify ||
              state == AuthStepperState.verifyError,
          isError: state == AuthStepperState.verifyError,
        ),
        _buildConnector(
          color: state == AuthStepperState.profile
              ? CliinAppColors.primary
              : CliinAppColors.divider,
        ),
        _buildStep(
          number: 3,
          label: 'Profil',
          circleColor: state == AuthStepperState.profile
              ? CliinAppColors.primary
              : CliinAppColors.divider,
          labelColor: state == AuthStepperState.profile
              ? CliinAppColors.textDark
              : CliinAppColors.textSecondary,
          showCheck: false,
          isActive: state == AuthStepperState.profile,
          isError: false,
        ),
      ],
    );
  }

  Widget _buildStep({
    required int number,
    required String label,
    required Color circleColor,
    required Color labelColor,
    required bool showCheck,
    required bool isActive,
    required bool isError,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
            if (showCheck) ...[
              const SizedBox(width: 2),
              const Icon(Icons.check_rounded,
                  size: 11, color: CliinAppColors.primary),
            ],
            if (isError) ...[
              const SizedBox(width: 2),
              const Icon(Icons.error_rounded,
                  size: 11, color: CliinAppColors.alertRed),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildConnector({required Color color}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: color,
      ),
    );
  }
}
