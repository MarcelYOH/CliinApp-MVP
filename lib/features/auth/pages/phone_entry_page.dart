// lib/features/auth/pages/phone_entry_page.dart
// Saisie numéro téléphone — image2_phone_entry.png

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/auth_store.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../widgets/auth_stepper.dart';
import 'otp_verification_page.dart';
import 'email_entry_page.dart';

// ── Liste indicatifs — réutilisée depuis take_charge_flow.dart ───────
class _CountryCode {
  final String flag;
  final String name;
  final String code;
  const _CountryCode(
      {required this.flag, required this.name, required this.code});
}

const _kCountryCodes = [
  _CountryCode(flag: '🇨🇮', name: 'Côte d\'Ivoire', code: '+225'),
  _CountryCode(flag: '🇸🇳', name: 'Sénégal', code: '+221'),
  _CountryCode(flag: '🇧🇫', name: 'Burkina Faso', code: '+226'),
  _CountryCode(flag: '🇲🇱', name: 'Mali', code: '+223'),
  _CountryCode(flag: '🇬🇳', name: 'Guinée', code: '+224'),
  _CountryCode(flag: '🇬🇭', name: 'Ghana', code: '+233'),
  _CountryCode(flag: '🇧🇯', name: 'Bénin', code: '+229'),
  _CountryCode(flag: '🇹🇬', name: 'Togo', code: '+228'),
  _CountryCode(flag: '🇳🇬', name: 'Nigeria', code: '+234'),
  _CountryCode(flag: '🇫🇷', name: 'France', code: '+33'),
];

Color _countryColor(String code) {
  switch (code) {
    case '+225': return const Color(0xFF009A44);
    case '+221': return const Color(0xFF00853F);
    case '+226': return const Color(0xFFEF2B2D);
    case '+223': return const Color(0xFF009A44);
    case '+224': return const Color(0xFFCE1126);
    case '+233': return const Color(0xFF006B3F);
    case '+229': return const Color(0xFF008751);
    case '+228': return const Color(0xFF006A4E);
    case '+234': return const Color(0xFF008751);
    case '+33': return const Color(0xFF002395);
    default: return CliinAppColors.primary;
  }
}

class PhoneEntryPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const PhoneEntryPage({super.key, required this.onAuthenticated});

  @override
  State<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends State<PhoneEntryPage> {
  _CountryCode _selectedCountry = _kCountryCodes.first;
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
        local.startsWith('0') && removeTrunk.contains(_selectedCountry.code);
    final cleaned = shouldRemove ? local.substring(1) : local;
    return '${_selectedCountry.code}$cleaned';
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

  void _showCountryPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(CliinAppConstants.radiusLarge)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding,
                  CliinAppConstants.spacingM,
                  CliinAppConstants.pagePadding,
                  CliinAppConstants.spacingM),
              child: Column(children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: CliinAppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: CliinAppConstants.spacingM),
                Text('Sélectionner un pays',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: _kCountryCodes.map((c) => ListTile(
                  leading: Container(
                    width: 40, height: 28,
                    decoration: BoxDecoration(
                      color: _countryColor(c.code),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(c.code.replaceAll('+', ''),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  title: Text(c.name,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: CliinAppColors.textDark)),
                  trailing: Text(c.code,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedCountry.code == c.code
                              ? CliinAppColors.primary
                              : CliinAppColors.textSecondary)),
                  selected: _selectedCountry.code == c.code,
                  selectedTileColor: CliinAppColors.primaryLight,
                  onTap: () {
                    setState(() => _selectedCountry = c);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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
                      child: Row(children: [
                        GestureDetector(
                          onTap: _showCountryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: CliinAppColors.background,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(
                                    CliinAppConstants.radiusMedium),
                                bottomLeft: Radius.circular(
                                    CliinAppConstants.radiusMedium),
                              ),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_selectedCountry.flag,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(_selectedCountry.code,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: CliinAppColors.textDark)),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: CliinAppColors.textSecondary),
                            ]),
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: CliinAppColors.divider),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                color: CliinAppColors.textDark),
                            decoration: InputDecoration(
                              hintText: '07 12 34 56 78',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: CliinAppColors.textSecondary),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
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
