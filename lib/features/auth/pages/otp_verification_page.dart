// lib/features/auth/pages/otp_verification_page.dart
// Saisie code OTP 6 chiffres — images 3 et 4 (même page, 2 états)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/auth_store.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../widgets/auth_stepper.dart';
import 'profile_setup_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String contact;
  final bool isPhone;
  final VoidCallback onAuthenticated;

  const OtpVerificationPage({
    super.key,
    required this.contact,
    required this.isPhone,
    required this.onAuthenticated,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const int _codeLength = 6;
  static const int _expirySeconds = 300; // 5 min

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  int _remainingSeconds = _expirySeconds;
  Timer? _timer;
  bool _isVerifying = false;
  bool _hasError = false;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _expirySeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          t.cancel();
          _isExpired = true;
          _hasError = true;
        }
      });
    });
  }

  String get _timerLabel {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _enteredCode =>
      _controllers.map((c) => c.text).join();

  bool get _isCodeComplete => _enteredCode.length == _codeLength;

  Future<void> _verify() async {
    if (!_isCodeComplete || _isVerifying) return;
    setState(() { _isVerifying = true; _hasError = false; });
    try {
      final ok = await AuthStore.instance.verifyOtp(_enteredCode);
      if (!mounted) return;
      if (ok) {
        _timer?.cancel();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProfileSetupPage(
              onAuthenticated: widget.onAuthenticated,
            ),
          ),
        );
      } else {
        setState(() { _hasError = true; });
        // Vider les cases
        for (final c in _controllers) { c.clear(); }
        _focusNodes.first.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _hasError = false;
      _isExpired = false;
      for (final c in _controllers) { c.clear(); }
    });
    if (widget.isPhone) {
      await AuthStore.instance.sendPhoneOtp(widget.contact);
    } else {
      await AuthStore.instance.sendEmailOtp(widget.contact);
    }
    _startTimer();
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
    if (mounted) _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final errorState = _hasError;

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
                    AuthStepper(
                      state: errorState
                          ? AuthStepperState.verifyError
                          : AuthStepperState.verify,
                    ),
                    const SizedBox(height: 32),

                    if (errorState) ...[
                      // État erreur — icône cadenas rouge
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: CliinAppColors.alertRedBg,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.lock_rounded,
                                  color: CliinAppColors.alertRed, size: 36),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: CliinAppColors.alertRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Code incorrect',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: CliinAppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Le code que vous avez saisi est incorrect\nou a expiré.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CliinAppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      // État normal
                      Text(
                        'Entrez le code de vérification',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CliinAppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CliinAppColors.textSecondary,
                              height: 1.5),
                          children: [
                            const TextSpan(text: 'Nous avons envoyé un code à '),
                            TextSpan(
                              text: widget.contact,
                              style: TextStyle(
                                  color: CliinAppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CliinAppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Le code expirera dans '),
                            TextSpan(
                              text: _timerLabel,
                              style: TextStyle(
                                  color: CliinAppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Cases OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_codeLength, (i) {
                        final bgColor = errorState
                            ? CliinAppColors.alertRedBg
                            : CliinAppColors.background;
                        final borderColor = errorState
                            ? CliinAppColors.alertRed
                            : (i == 0 ? CliinAppColors.primary : CliinAppColors.divider);
                        return SizedBox(
                          width: 46,
                          height: 56,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: errorState
                                    ? CliinAppColors.alertRed
                                    : CliinAppColors.textDark),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: bgColor,
                              hintText: '—',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: CliinAppColors.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    CliinAppConstants.radiusMedium),
                                borderSide: BorderSide(
                                    color: borderColor, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    CliinAppConstants.radiusMedium),
                                borderSide: BorderSide(
                                    color: borderColor, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    CliinAppConstants.radiusMedium),
                                borderSide: BorderSide(
                                    color: errorState
                                        ? CliinAppColors.alertRed
                                        : CliinAppColors.primary,
                                    width: 2),
                              ),
                            ),
                            onChanged: (v) {
                              if (v.isNotEmpty && i < _codeLength - 1) {
                                _focusNodes[i + 1].requestFocus();
                              }
                              if (v.isEmpty && i > 0) {
                                _focusNodes[i - 1].requestFocus();
                              }
                              setState(() {});
                              if (_isCodeComplete && !errorState) {
                                _verify();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    if (errorState && _isExpired)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CliinAppColors.alertRedBg,
                          borderRadius: BorderRadius.circular(
                              CliinAppConstants.radiusMedium),
                        ),
                        child: Row(children: [
                          const Icon(Icons.access_time_rounded,
                              color: CliinAppColors.alertRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ce code a expiré.',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: CliinAppColors.alertRed)),
                                Text('Veuillez demander un nouveau code.',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: CliinAppColors.alertRed)),
                              ],
                            ),
                          ),
                        ]),
                      )
                    else if (!errorState)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CliinAppColors.primaryLight,
                          borderRadius: BorderRadius.circular(
                              CliinAppConstants.radiusMedium),
                        ),
                        child: Row(children: [
                          const Icon(Icons.shield_outlined,
                              color: CliinAppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Vos données sont protégées',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: CliinAppColors.textDark)),
                                Text('CliinApp ne partage jamais vos informations.',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: CliinAppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.lock_rounded,
                              color: CliinAppColors.primary, size: 16),
                        ]),
                      ),

                    const SizedBox(height: 16),

                    // Renvoyer le code
                    GestureDetector(
                      onTap: _resendCode,
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
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: errorState
                                  ? CliinAppColors.alertRed
                                  : CliinAppColors.textSecondary,
                              size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Vous n\'avez pas reçu le code ?',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: CliinAppColors.textSecondary),
                            ),
                          ),
                          Text(
                            'Renvoyer le code',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: errorState
                                  ? CliinAppColors.alertRed
                                  : CliinAppColors.primary,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note confidentialité
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 14,
                            color: errorState
                                ? CliinAppColors.textSecondary
                                : CliinAppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.isPhone
                                ? 'Nous n\'utilisons ce numéro que pour la vérification. Aucun spam, aucun marketing.'
                                : 'Nous n\'utilisons cet email que pour la vérification. Aucun spam, aucun marketing.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CliinAppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bouton principal
                    if (!errorState) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed:
                              (_isCodeComplete && !_isVerifying) ? _verify : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CliinAppColors.primary,
                            disabledBackgroundColor: CliinAppColors.divider,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  CliinAppConstants.radiusMedium),
                            ),
                            elevation: 0,
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text('Vérifier le code',
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
                    ] else ...[
                      // Réessayer
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _isExpired = false;
                              for (final c in _controllers) { c.clear(); }
                            });
                            _focusNodes.first.requestFocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CliinAppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  CliinAppConstants.radiusMedium),
                            ),
                            elevation: 0,
                          ),
                          child: Text('Réessayer',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: CliinAppColors.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  CliinAppConstants.radiusMedium),
                            ),
                          ),
                          child: Text(
                            widget.isPhone
                                ? 'Modifier mon numéro'
                                : 'Modifier mon email',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: CliinAppColors.textDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded,
                                size: 12,
                                color: CliinAppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Vos données sont protégées.',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: CliinAppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
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
