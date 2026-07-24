// lib/features/groups/pages/create_group_page.dart
// Création d'un groupe — philosophie "moins d'une minute", 4 champs +
// photo facultative — CliinApp

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../reports/pages/report_camera_page.dart';
import '../models/group_model.dart';
import '../widgets/add_admin_sheet.dart'
    show kGroupClassicPostes, kAutrePosteOption;
import '../widgets/group_form_fields.dart';
import 'group_photo_adjust_page.dart';
import 'group_profile_page.dart';

// Postes proposés au créateur — les postes classiques + "Autre..." (saisie
// libre), jamais "Administrateur (sans poste officiel)" : le créateur
// occupe toujours un poste officiel dans le bureau exécutif (correction 3).
const List<String> kFounderPosteOptions = [
  ...kGroupClassicPostes,
  kAutrePosteOption,
];

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nomController = TextEditingController();
  final _zoneController = TextEditingController();
  final _descController = TextEditingController();
  final _customPosteController = TextEditingController();

  String? _photoPath;
  String? _bannerPath;
  double _photoAlignY = 0.0;
  double _bannerAlignY = 0.0;
  GroupType _selectedType = GroupType.ong;
  String? _selectedPoste;
  bool _isDetectingZone = false;
  bool _isSubmitting = false;

  // Coordonnées de la détection GPS ci-dessous — jamais devinées à partir
  // du texte de zone, seulement capturées au moment d'un fix GPS réel.
  double? _latitude;
  double? _longitude;

  bool get _canSubmit =>
      !_isSubmitting &&
      _nomController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty &&
      _selectedPoste != null &&
      (_selectedPoste != kAutrePosteOption ||
          _customPosteController.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectZone());
  }

  @override
  void dispose() {
    _nomController.dispose();
    _zoneController.dispose();
    _descController.dispose();
    _customPosteController.dispose();
    super.dispose();
  }

  // Même logique que report_form_page.dart : position GPS puis reverse-
  // geocoding. Simplifié (pas de suivi continu) — la zone d'un groupe n'a
  // pas besoin de la même précision anti-fraude qu'un signalement.
  Future<void> _detectZone() async {
    setState(() => _isDetectingZone = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted && _zoneController.text.trim().isEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (parts.isNotEmpty) {
          setState(() {
            _zoneController.text = parts.join(', ');
            _latitude = position.latitude;
            _longitude = position.longitude;
          });
        }
      }
    } catch (_) {
      // Détection indisponible — l'utilisateur saisit la zone manuellement.
    } finally {
      if (mounted) setState(() => _isDetectingZone = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final path = await Navigator.push<String>(
        context,
        fastFadeRoute<String>(
          const ReportCameraPage(replaceMode: true, isAvatarMode: true),
        ),
      );
      if (path == null || !mounted) return;
      final alignY = await Navigator.push<double>(
        context,
        MaterialPageRoute<double>(
          builder: (_) =>
              GroupPhotoAdjustPage(imagePath: path, isCircular: true),
        ),
      );
      if (mounted) {
        setState(() {
          _photoPath = path;
          _photoAlignY = alignY ?? 0.0;
        });
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

  Future<void> _pickBanner() async {
    try {
      final path = await Navigator.push<String>(
        context,
        fastFadeRoute<String>(
          const ReportCameraPage(replaceMode: true, isAvatarMode: true),
        ),
      );
      if (path == null || !mounted) return;
      final alignY = await Navigator.push<double>(
        context,
        MaterialPageRoute<double>(
          builder: (_) =>
              GroupPhotoAdjustPage(imagePath: path, isCircular: false),
        ),
      );
      if (mounted) {
        setState(() {
          _bannerPath = path;
          _bannerAlignY = alignY ?? 0.0;
        });
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

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    final user = AuthStore.instance.currentUser!;
    try {
      final created = await GroupStore.instance.createGroup(
        nom: _nomController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        zone: _zoneController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        photoPath: _photoPath,
        bannerPath: _bannerPath,
        photoAlignY: _photoAlignY,
        bannerAlignY: _bannerAlignY,
        createurId: user.id,
        createurNom: user.username,
        createurAvatarPath: user.avatarPath,
        createurPoste: _selectedPoste == kAutrePosteOption
            ? _customPosteController.text.trim()
            : _selectedPoste!,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          fastFadeRoute<void>(GroupProfilePage(groupId: created.id)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue. Réessayez.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: CliinAppConstants.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: CliinAppConstants.spacingM),
                    buildGroupFormLabeledField(
                      label: 'Photo de couverture',
                      child: buildGroupFormBannerPicker(
                          bannerPath: _bannerPath, onTap: _pickBanner),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    buildGroupFormLabeledField(
                      label: 'Photo de profil',
                      child: buildGroupFormPhotoPicker(
                          photoPath: _photoPath, onTap: _pickPhoto),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                    buildGroupFormLabeledField(
                      label: 'Nom du groupe',
                      child: buildGroupFormTextField(
                        controller: _nomController,
                        hint: 'Ex : Clean Riviera',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    buildGroupFormLabeledField(
                      label: 'Type de groupe',
                      child: buildGroupFormTypeChips(
                        selected: _selectedType,
                        onSelect: (t) => setState(() => _selectedType = t),
                      ),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    buildGroupFormLabeledField(
                      label: 'Zone principale',
                      helper: 'Détectée automatiquement — modifiable si besoin.',
                      child: buildGroupFormTextField(
                        controller: _zoneController,
                        hint: _isDetectingZone
                            ? 'Détection en cours...'
                            : 'Ex : Riviera 2, Cocody',
                        suffixIcon: _isDetectingZone
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: CliinAppColors.primary),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    buildGroupFormLabeledField(
                      label: 'Description',
                      child: buildGroupFormTextField(
                        controller: _descController,
                        hint: 'Décrivez brièvement qui vous êtes...',
                        maxLines: null,
                        minLines: 4,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    buildGroupFormLabeledField(
                      label: 'Votre poste dans le groupe',
                      helper: 'Le poste que vous occupez réellement — pas '
                          'forcément Président.',
                      child: _buildPosteSelector(),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                CliinAppConstants.pagePadding,
                CliinAppConstants.spacingS,
                CliinAppConstants.pagePadding,
                MediaQuery.of(context).padding.bottom + CliinAppConstants.spacingM,
              ),
              child: buildGroupFormSubmitButton(
                enabled: _canSubmit,
                isSubmitting: _isSubmitting,
                onPressed: _submit,
                label: 'Créer le groupe',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosteSelector() {
    return Column(
      children: [
        ...kFounderPosteOptions.map(_buildPosteOption),
        if (_selectedPoste == kAutrePosteOption) ...[
          const SizedBox(height: 4),
          buildGroupFormTextField(
            controller: _customPosteController,
            hint: 'Ex : Responsable logistique',
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildPosteOption(String poste) {
    final selected = _selectedPoste == poste;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPoste = poste),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? CliinAppColors.primaryLight
                : CliinAppColors.cardWhite,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusMedium),
            border: Border.all(
              color: selected ? CliinAppColors.primary : CliinAppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Text(poste,
                  style: CliinAppTextStyles.bodyMedium.copyWith(
                      color: CliinAppColors.textDark,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? CliinAppColors.primary
                  : CliinAppColors.textSecondary,
              size: 20,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + 12,
        CliinAppConstants.pagePadding,
        12,
      ),
      child: Row(children: [
        CircleIconButton.back(onTap: () => Navigator.pop(context)),
        const SizedBox(width: CliinAppConstants.spacingM),
        Text('Créer un groupe', style: CliinAppTextStyles.headingMedium),
      ]),
    );
  }
}
