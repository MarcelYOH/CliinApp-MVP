// lib/features/groups/pages/group_form_page.dart
// Formulaire groupe partagé — création ET modification (correction 5) :
// un seul composant, `groupId == null` bascule en mode création, sinon
// modification pré-remplie. Ne jamais redupliquer ce formulaire ; toute
// nouvelle page qui crée/édite un groupe doit passer par ce widget.

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
// Non proposé en modification : le poste du fondateur se gère via l'ajout
// d'administrateur de l'Espace gestion, pas depuis ce formulaire.
const List<String> kFounderPosteOptions = [
  ...kGroupClassicPostes,
  kAutrePosteOption,
];

class GroupFormPage extends StatefulWidget {
  // null = création d'un nouveau groupe. Renseigné = modification du
  // groupe correspondant.
  final String? groupId;

  const GroupFormPage({super.key, this.groupId});

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage> {
  bool get _isEditMode => widget.groupId != null;

  final _nomController = TextEditingController();
  final _zoneController = TextEditingController();
  final _descController = TextEditingController();
  final _customPosteController = TextEditingController();

  late final GroupModel? _group;

  String? _photoPath;
  String? _bannerPath;
  double _photoAlignY = 0.0;
  double _bannerAlignY = 0.0;
  GroupType _selectedType = GroupType.ong;
  String? _selectedPoste;
  bool _isDetectingZone = false;
  bool _isSubmitting = false;

  // Coordonnées de la détection GPS — jamais devinées à partir du texte de
  // zone, seulement capturées au moment d'un fix GPS réel.
  double? _latitude;
  double? _longitude;

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_nomController.text.trim().isEmpty) return false;
    if (_descController.text.trim().isEmpty) return false;
    if (!_isEditMode) {
      if (_selectedPoste == null) return false;
      if (_selectedPoste == kAutrePosteOption &&
          _customPosteController.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _group = GroupStore.instance.groupById(widget.groupId!);
      final group = _group;
      if (group != null) {
        _nomController.text = group.nom;
        _zoneController.text = group.zone;
        _descController.text = group.description;
        _photoPath = group.photoPath;
        _bannerPath = group.bannerPath;
        _photoAlignY = group.photoAlignY;
        _bannerAlignY = group.bannerAlignY;
        _selectedType = group.type;
        _latitude = group.latitude;
        _longitude = group.longitude;
      }
    } else {
      _group = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoDetectZone());
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _zoneController.dispose();
    _descController.dispose();
    _customPosteController.dispose();
    super.dispose();
  }

  // Détection automatique à la création — ne remplit que si le champ est
  // encore vide, échoue silencieusement (l'utilisateur saisit la zone
  // manuellement).
  Future<void> _autoDetectZone() async {
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

  // Redétection manuelle en modification — déclenchée explicitement par
  // l'utilisateur (icône de localisation), écrase toujours le texte + les
  // coordonnées existantes.
  Future<void> _manualRedetectZone() async {
    setState(() => _isDetectingZone = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Position indisponible — réessayez ou saisissez la zone manuellement.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    try {
      if (_isEditMode) {
        // GroupModel.description EST "Qui sommes-nous" — même donnée,
        // jamais une copie séparée : la mise à jour se reflète directement
        // dans le profil au retour.
        await GroupStore.instance.updateGroup(
          widget.groupId!,
          nom: _nomController.text.trim(),
          photoPath: _photoPath,
          bannerPath: _bannerPath,
          photoAlignY: _photoAlignY,
          bannerAlignY: _bannerAlignY,
          description: _descController.text.trim(),
          type: _selectedType,
          zone: _zoneController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
        if (mounted) Navigator.pop(context);
      } else {
        final user = AuthStore.instance.currentUser!;
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
    if (_isEditMode && _group == null) {
      return Scaffold(
        backgroundColor: CliinAppColors.background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: Text('Groupe introuvable',
                      style: CliinAppTextStyles.bodyMedium),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      helper: _isEditMode
                          ? 'Modifiable manuellement, ou relancez la détection GPS.'
                          : 'Détectée automatiquement — modifiable si besoin.',
                      child: buildGroupFormTextField(
                        controller: _zoneController,
                        hint: (!_isEditMode && _isDetectingZone)
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
                            : (_isEditMode
                                ? IconButton(
                                    icon: const Icon(Icons.my_location_rounded,
                                        color: CliinAppColors.primary, size: 20),
                                    onPressed: _manualRedetectZone,
                                    tooltip: 'Redétecter ma position',
                                  )
                                : null),
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
                    if (!_isEditMode) ...[
                      const SizedBox(height: CliinAppConstants.spacingL),
                      buildGroupFormLabeledField(
                        label: 'Votre poste dans le groupe',
                        helper: 'Le poste que vous occupez réellement — pas '
                            'forcément Président.',
                        child: _buildPosteSelector(),
                      ),
                    ],
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
                label: _isEditMode ? 'Enregistrer les modifications' : 'Créer le groupe',
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
        Text(_isEditMode ? 'Modifier le groupe' : 'Créer un groupe',
            style: CliinAppTextStyles.headingMedium),
      ]),
    );
  }
}
