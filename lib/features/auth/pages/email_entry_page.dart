// lib/features/auth/pages/email_entry_page.dart
// Miroir de phone_entry_page.dart — même structure, champ email à la place

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/auth_store.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../widgets/auth_stepper.dart';
import 'otp_verification_page.dart';
import 'phone_entry_page.dart';

class EmailEntryPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const EmailEntryPage({super.key, required this.onAuthenticated});

  @override
  State<EmailEntryPage> createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.') && !_isLoading;
  }

  Future<void> _sendCode() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);
    try {
      await AuthStore.instance.sendEmailOtp(_emailController.text.trim());
      final code = AuthStore.instance.lastDebugCode;
      if (mounted && code != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔑 Code de test : $code',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            backgroundColor: const Color(0xFF1A6B2F),
            duration: const Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => OtpVerificationPage(
              contact: _emailController.text.trim(),
              isPhone: false,
              onAuthenticated: widget.onAuthenticated,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.cardWhite,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding,
                  MediaQuery.of(context).padding.top + 12,
                  CliinAppConstants.pagePadding,
                  12),
              child: Row(children: [
                CircleIconButton.back(onTap: () => Navigator.pop(context)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CliinAppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CliinAppColors.primary),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shield_outlined,
                        color: CliinAppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text('Sécurisé',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CliinAppColors.primary)),
                  ]),
                ),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    CliinAppConstants.pagePadding,
                    0,
                    CliinAppConstants.pagePadding,
                    MediaQuery.of(context).padding.bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const AuthStepper(state: AuthStepperState.method),
                    const SizedBox(height: 32),

                    Text(
                      'Entrez votre adresse\nemail',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nous vous enverrons un code de vérification\npar email pour sécuriser votre compte.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CliinAppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Champ email
                    Container(
                      decoration: BoxDecoration(
                        color: CliinAppColors.cardWhite,
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium),
                        border: Border.all(color: CliinAppColors.primary),
                      ),
                      child: Row(children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.email_outlined,
                              color: CliinAppColors.textSecondary, size: 20),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                color: CliinAppColors.textDark),
                            decoration: InputDecoration(
                              hintText: 'exemple@email.com',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: CliinAppColors.textSecondary),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 14),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Encarts de confiance
                    Container(
                      padding: const EdgeInsets.all(
                          CliinAppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: CliinAppColors.primaryLight,
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium),
                      ),
                      child: Column(children: [
                        _TrustRow(
                          icon: Icons.shield_outlined,
                          title: 'Vos données sont protégées',
                          subtitle:
                              'CliinApp ne partage jamais votre email.',
                        ),
                        const SizedBox(height: 10),
                        _TrustRow(
                          icon: Icons.email_outlined,
                          title: 'Email uniquement',
                          subtitle: 'Aucun spam ni marketing.',
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Bouton principal
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _sendCode : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CliinAppColors.primary,
                          disabledBackgroundColor: CliinAppColors.divider,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                CliinAppConstants.radiusMedium),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text('Recevoir le code par email',
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Autres options',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CliinAppColors.textSecondary)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => PhoneEntryPage(
                              onAuthenticated: widget.onAuthenticated,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: CliinAppColors.cardWhite,
                          borderRadius: BorderRadius.circular(
                              CliinAppConstants.radiusMedium),
                          border: Border.all(color: CliinAppColors.divider),
                        ),
                        child: Row(children: [
                          const Icon(Icons.phone_rounded,
                              color: CliinAppColors.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Utiliser mon numéro de téléphone',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: CliinAppColors.textDark)),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: CliinAppColors.textSecondary),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TrustRow(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: CliinAppColors.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textDark)),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 12, color: CliinAppColors.textSecondary)),
        ]),
      ),
      const Icon(Icons.lock_rounded,
          color: CliinAppColors.primary, size: 16),
    ]);
  }
}
