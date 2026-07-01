// lib/features/auth/pages/auth_gate_sheet.dart
// Bottom sheet "Connectez-vous pour participer" — image1_auth_gate_sheet.png

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/auth_store.dart';
import 'phone_entry_page.dart';
import 'email_entry_page.dart';

Future<bool> showAuthGateSheet(BuildContext context) async {
  bool didAuth = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AuthGateSheet(
      onAuthenticated: () {
        didAuth = true;
        // ProfileSetupPage ferme tout le flow via popUntil(route.isFirst)
      },
    ),
  );
  return didAuth;
}

class AuthGateSheet extends StatelessWidget {
  final VoidCallback onAuthenticated;

  const AuthGateSheet({super.key, required this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CliinAppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Icône cadenas vert
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: CliinAppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: CliinAppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                'Connectez-vous pour participer',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CliinAppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Sous-titre
              Text(
                'Rejoignez votre communauté et contribuez\nà améliorer votre environnement.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CliinAppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Bouton Google
              _AuthOptionButton(
                icon: _GoogleIcon(),
                label: 'Continuer avec Google',
                onTap: () async {
                  try {
                    await AuthStore.instance.signInWithGoogle();
                  } catch (e) {
                    if (e is UnsupportedError && e.message == 'google_not_yet') {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bientôt disponible'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Bouton téléphone
              _AuthOptionButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: CliinAppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: CliinAppColors.primary,
                    size: 18,
                  ),
                ),
                label: 'Continuer avec un numéro de téléphone',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PhoneEntryPage(
                        onAuthenticated: onAuthenticated,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Bouton email
              _AuthOptionButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                ),
                label: 'Continuer avec un email',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EmailEntryPage(
                        onAuthenticated: onAuthenticated,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Séparateur "ou"
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CliinAppColors.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ]),

              const SizedBox(height: 16),

              // Continuer en exploration
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Continuer en exploration',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CliinAppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthOptionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _AuthOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Row(children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CliinAppColors.textDark,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// Icône Google colorée dessinée manuellement (pas de package externe)
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Fond blanc circulaire
    canvas.drawCircle(center, r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
    canvas.drawCircle(center, r,
        Paint()
          ..color = const Color(0xFFDDDDDD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);

    // Lettre "G" simplifiée en couleurs Google
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
