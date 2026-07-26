// lib/features/auth/pages/phone_entry_page.dart
// Saisie numéro téléphone — image2_phone_entry.png

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/auth_store.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/phone_country_field.dart';
import '../widgets/auth_stepper.dart';
import 'otp_verification_page.dart';
import 'email_entry_page.dart';

class PhoneEntryPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const PhoneEntryPage({super.key, required this.onAuthenticated});

  @override
  State<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends State<PhoneEntryPage> {
  String _dialCode = '+225';
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final local = _phoneController.text.trim();
    if (local.isEmpty) return '';
    const removeTrunk = {'+33', '+32', '+44', '+31', '+39', '+34'};
    final shouldRemove =
        local.startsWith('0') && removeTrunk.contains(_dialCode);
    final cleaned = shouldRemove ? local.substring(1) : local;
    return '$_dialCode$cleaned';
  }

  bool get _canSubmit =>
      _phoneController.text.trim().length >= 6 && !_isLoading;

  Future<void> _sendCode() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);
    try {
      await AuthStore.instance.sendPhoneOtp(_fullPhone);
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
              contact: _fullPhone,
              isPhone: true,
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
                    // Stepper
                    const AuthStepper(state: AuthStepperState.method),
                    const SizedBox(height: 32),

                    // Titre
                    Text(
                      'Entrez votre numéro\nde téléphone',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nous vous enverrons un code de vérification\npar SMS pour sécuriser votre compte.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CliinAppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Champ téléphone
                    Container(
                      decoration: BoxDecoration(
                        color: CliinAppColors.cardWhite,
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium),
                        border: Border.all(color: CliinAppColors.primary),
                      ),
                      child: PhoneCountryField(
                        phoneController: _phoneController,
                        onDialCodeChanged: (code) =>
                            setState(() => _dialCode = code),
                        onPhoneChanged: (_) => setState(() {}),
                        autofocus: true,
                      ),
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
                              'CliinApp ne partage jamais votre numéro.',
                        ),
                        const SizedBox(height: 10),
                        _TrustRow(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'SMS uniquement',
                          subtitle: 'Aucun appel ne sera effectué.',
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
                                  Text('Recevoir le code par SMS',
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

                    // Autres options
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

                    // Email option
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => EmailEntryPage(
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
                          Icon(Icons.email_outlined,
                              color: CliinAppColors.textSecondary,
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Utiliser mon adresse email',
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
