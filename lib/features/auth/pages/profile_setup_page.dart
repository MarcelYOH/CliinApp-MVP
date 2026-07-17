// lib/features/auth/pages/profile_setup_page.dart
// Finalisation profil — image5_profile_setup.png

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/user_location_service.dart';
import '../../../../shared/store/auth_store.dart';
import '../../reports/pages/report_camera_page.dart';
import '../../../../shared/navigation/fast_page_route.dart';
import '../widgets/auth_stepper.dart';

class ProfileSetupPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const ProfileSetupPage({super.key, required this.onAuthenticated});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _zoneController;
  String? _avatarPath;
  bool _isLoading = false;
  bool _isLocating = false;
  bool _locationError = false;
  bool _usernameValid = true;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: _generateUsername());
    _zoneController = TextEditingController(text: '');
    _usernameValid = _usernameController.text.isNotEmpty;
    // GPS ne se lance PAS automatiquement — uniquement sur bouton
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  String _generateUsername() {
    final prefixes = [
      'Citoyen', 'Habitant', 'Voisin', 'Acteur', 'Membre'
    ];
    final rand = Random();
    final prefix = prefixes[rand.nextInt(prefixes.length)];
    final number = 100 + rand.nextInt(900);
    return '$prefix$number';
  }

  Future<void> _tryGetZone() async {
    if (_isLocating) return;
    setState(() { _isLocating = true; _locationError = false; });
    try {
      final pos = await UserLocationService.instance
          .getCurrentPosition()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (!mounted) return;
      if (pos == null) { setState(() => _locationError = true); return; }

      final placemarks = await placemarkFromCoordinates(
              pos.latitude, pos.longitude)
          .timeout(const Duration(seconds: 5), onTimeout: () => []);
      if (!mounted) return;
      if (placemarks.isEmpty) { setState(() => _locationError = true); return; }

      final p = placemarks.first;
      final parts = <String>[];
      if (p.subLocality?.isNotEmpty == true) parts.add(p.subLocality!);
      if (p.locality?.isNotEmpty == true) parts.add(p.locality!);
      if (parts.isEmpty && p.administrativeArea?.isNotEmpty == true) {
        parts.add(p.administrativeArea!);
      }
      if (parts.isNotEmpty && mounted) {
        setState(() { _zoneController.text = parts.join(', '); _locationError = false; });
      } else if (mounted) {
        setState(() => _locationError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _locationError = true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  bool get _canSubmit {
    final username = _usernameController.text.trim();
    final zone = _zoneController.text.trim();
    return username.isNotEmpty && zone.isNotEmpty && !_isLoading;
  }

  // Réutilise le même bouton de prise de photo que la création d'un
  // signalement (report_camera_page.dart, replaceMode: true) — caméra
  // plein écran + import galerie déjà implémentés, plutôt qu'un
  // ImagePicker basique séparé.
  Future<void> _pickAvatarPhoto() async {
    try {
      final path = await Navigator.push<String>(
        context,
        fastFadeRoute<String>(
          const ReportCameraPage(
            replaceMode: true,
            isAvatarMode: true,
          ),
        ),
      );
      if (path != null && mounted) {
        setState(() => _avatarPath = path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'accéder à la caméra.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _complete() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);
    try {
      await AuthStore.instance.completeProfile(
        username: _usernameController.text.trim(),
        zone: _zoneController.text.trim(),
        avatarPath: _avatarPath,
      );
      if (mounted) {
        widget.onAuthenticated(); // signale didAuth = true au parent
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue. Réessayez.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: CliinAppColors.textDark, size: 24),
                ),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    const AuthStepper(state: AuthStepperState.profile),
                    const SizedBox(height: 32),

                    // Icône check vert
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: CliinAppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: CliinAppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Bienvenue sur CliinApp ! 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CliinAppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un dernier pas pour personnaliser votre expérience\net commencer à agir pour votre communauté.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CliinAppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Photo facultative
                    GestureDetector(
                      onTap: _pickAvatarPhoto,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: CliinAppColors.divider,
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _avatarPath != null
                                ? Image.file(File(_avatarPath!),
                                    fit: BoxFit.cover, width: 90, height: 90)
                                : const Icon(Icons.camera_alt_rounded,
                                    color: CliinAppColors.primary, size: 36),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: CliinAppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  _avatarPath != null
                                      ? Icons.edit_rounded
                                      : Icons.add_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Ajoutez une photo (facultatif)',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CliinAppColors.textDark)),
                    Text('Cela nous aide à créer une communauté de confiance.',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CliinAppColors.textSecondary)),
                    const SizedBox(height: 24),

                    // Champ nom d'utilisateur
                    Container(
                      decoration: BoxDecoration(
                        color: CliinAppColors.cardWhite,
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium),
                        border: Border.all(color: CliinAppColors.divider),
                      ),
                      child: Row(children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.person_outline_rounded,
                              color: CliinAppColors.textSecondary, size: 20),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  'Nom d\'utilisateur',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: CliinAppColors.textSecondary),
                                ),
                              ),
                              TextField(
                                controller: _usernameController,
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (v) => setState(() {
                                  _usernameValid = v.trim().isNotEmpty;
                                }),
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: CliinAppColors.textDark),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.only(bottom: 10),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_usernameValid)
                          const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(Icons.check_circle_rounded,
                                color: CliinAppColors.primary, size: 20),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ce nom sera visible par les autres utilisateurs.',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: CliinAppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ zone
                    Container(
                      decoration: BoxDecoration(
                        color: CliinAppColors.cardWhite,
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium),
                        border: Border.all(color: CliinAppColors.divider),
                      ),
                      child: Row(children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.location_on_outlined,
                              color: CliinAppColors.textSecondary, size: 20),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  'Votre zone principale',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: CliinAppColors.textSecondary),
                                ),
                              ),
                              TextField(
                                controller: _zoneController,
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: CliinAppColors.textDark),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.only(bottom: 10),
                                  isDense: true,
                                  hintText: 'Ex : Cocody, Abidjan',
                                  hintStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: CliinAppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              color: CliinAppColors.textSecondary, size: 20),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),

                    // Utiliser ma position actuelle — uniquement sur tap
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _isLocating ? null : _tryGetZone,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: CliinAppColors.primary),
                                  )
                                : const Icon(Icons.my_location_rounded,
                                    color: CliinAppColors.primary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              _isLocating
                                  ? 'Localisation en cours...'
                                  : 'Utiliser ma position actuelle',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CliinAppColors.primary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_locationError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Position non trouvée — saisissez votre zone manuellement.',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: CliinAppColors.textSecondary),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // Bouton Commencer à explorer
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _complete : null,
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
                                  Text('Commencer à explorer',
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
                    const SizedBox(height: 16),

                    // Encart "Votre compte est prêt"
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CliinAppColors.primaryLight,
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium),
                      ),
                      child: Row(children: [
                        const Icon(Icons.shield_rounded,
                            color: CliinAppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Votre compte est prêt !',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CliinAppColors.textDark)),
                              Text(
                                'Vous pourrez modifier ces informations plus tard\ndans les paramètres.',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: CliinAppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 12,
                            color: CliinAppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Vos données sont protégées et ne seront jamais partagées.',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CliinAppColors.textSecondary),
                        ),
                      ],
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
