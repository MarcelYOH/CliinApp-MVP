// lib/features/actions/pages/create_action_page.dart
// Formulaire de création d'une action — Lot 3/3, module Actions Terrain.
// Philosophie "moins d'une minute" (même esprit que report_camera_page.dart
// et la création de groupe) : le type d'action est la SEULE saisie
// obligatoire, tout le reste est pré-rempli automatiquement ou facultatif.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/report_category.dart';
import '../../../shared/models/report_status.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/action_card.dart'
    show formatActionDate, formatActionHeure;
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/gps_retry_button.dart';
import '../../../shared/widgets/report_card.dart' show buildReportImage;
import '../../groups/widgets/group_form_fields.dart'
    show
        buildGroupFormLabeledField,
        buildGroupFormTextField,
        buildGroupFormSubmitButton,
        GroupFormDashedRectPainter;
import '../../home/models/home_report_model.dart' show HomeReportModel;
import '../../reports/pages/report_camera_page.dart';
import '../../reports/widgets/attribution_choice_sheet.dart';
import '../models/action_model.dart';

class CreateActionPage extends StatefulWidget {
  // Renseigné lorsque la page est ouverte depuis le bouton "Organiser une
  // action" du profil d'un groupe (module Groupes, hors périmètre de ce
  // lot) — pré-sélectionne l'attribution "Au nom d'un groupe" avec ce
  // groupe précis, sans que l'utilisateur ait à re-choisir manuellement.
  // Null = flux normal depuis ActionsPage (attribution "En mon nom" par
  // défaut, modifiable).
  final String? preselectedGroupId;

  // Renseigné = mode modification (formulaire pré-rempli depuis l'action
  // existante, soumission via ActionStore.updateAction). Null = création —
  // même principe que GroupFormPage (groupId == null → création).
  final String? actionId;

  const CreateActionPage({super.key, this.preselectedGroupId, this.actionId});

  @override
  State<CreateActionPage> createState() => _CreateActionPageState();
}

class _CreateActionPageState extends State<CreateActionPage> {
  final _lieuController = TextEditingController();
  final _descController = TextEditingController();
  final _communicationController = TextEditingController();
  final _benevolesController = TextEditingController();
  final _financementController = TextEditingController();
  final _materielController = TextEditingController();

  String? _photoPath;
  ActionType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _latitude;
  double? _longitude;
  bool _isDetectingLieu = false;
  bool _gpsFailed = false;
  final Set<String> _selectedCasIds = {};
  ReportAttribution? _attribution;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.actionId != null;

  // Seule condition obligatoire à la publication — tout le reste du
  // formulaire est facultatif ou pré-rempli.
  bool get _canSubmit => _selectedType != null && !_isSubmitting;

  // Cas de l'utilisateur connecté actuellement "En cours" (pris en charge en
  // son nom personnel) — même filtre que ReportStore.prisEnChargeCount /
  // mes_cas_signales_page.dart, jamais les cas pris en charge au nom d'un
  // groupe (intervenant.groupName != null).
  List<HomeReportModel> get _myCasEnCours {
    final userId = AuthStore.instance.currentUser?.id;
    if (userId == null) return const [];
    return ReportStore.instance.reports
        .where((r) =>
            r.intervenant?.id == userId &&
            r.intervenant?.groupName == null &&
            r.status == ReportStatus.enCours)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final user = AuthStore.instance.currentUser;

    if (_isEditMode) {
      final existing = ActionStore.instance.actionById(widget.actionId!);
      if (existing != null) {
        _selectedType = existing.type;
        _selectedDate = existing.date;
        _selectedTime = TimeOfDay(hour: existing.date.hour, minute: existing.date.minute);
        _lieuController.text = existing.lieu;
        _latitude = existing.latitude;
        _longitude = existing.longitude;
        _photoPath = existing.photoPath;
        _descController.text = existing.description ?? '';
        _communicationController.text = existing.besoinCommunication ?? '';
        _benevolesController.text = existing.besoinBenevoles ?? '';
        _financementController.text = existing.besoinFinancement ?? '';
        _materielController.text = existing.besoinMateriel ?? '';
        _selectedCasIds.addAll(existing.casPrisEnChargeIds);
        // Reconstruit l'attribution depuis le modèle existant — organisateurId
        // porte l'id du groupe quand organisateurEstGroupe, sinon l'id de
        // l'organisateur individuel (même convention que _submit ci-dessous).
        _attribution = ReportAttribution(
          signaleParNom: existing.organisateurNom,
          signaleParId: existing.organisateurEstGroupe
              ? (user?.id ?? existing.organisateurId)
              : existing.organisateurId,
          groupId: existing.organisateurEstGroupe ? existing.organisateurId : null,
          isAnonyme: existing.isAnonyme,
        );
      }
      // Pas de détection GPS automatique en modification — le lieu existant
      // est déjà connu, jamais écrasé silencieusement.
      return;
    }

    if (user != null) {
      if (widget.preselectedGroupId != null) {
        final group = GroupStore.instance.groupById(widget.preselectedGroupId!);
        _attribution = group != null
            ? ReportAttribution(
                signaleParNom: group.nom,
                signaleParId: user.id,
                groupId: group.id,
              )
            : ReportAttribution(signaleParNom: user.username, signaleParId: user.id);
      } else {
        _attribution =
            ReportAttribution(signaleParNom: user.username, signaleParId: user.id);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDetectLieu());
  }

  @override
  void dispose() {
    _lieuController.dispose();
    _descController.dispose();
    _communicationController.dispose();
    _benevolesController.dispose();
    _financementController.dispose();
    _materielController.dispose();
    super.dispose();
  }

  // Détection automatique du lieu à l'ouverture — ne remplit que si le champ
  // est encore vide, échec géré via GpsRetryButton — même logique exacte que
  // group_form_page.dart (_autoDetectZone) et report_form_page.dart, jamais
  // dupliquée sous une forme différente.
  Future<void> _autoDetectLieu() async {
    setState(() {
      _isDetectingLieu = true;
      _gpsFailed = false;
    });
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted && _lieuController.text.trim().isEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (parts.isNotEmpty) {
          setState(() {
            _lieuController.text = parts.join(', ');
            _latitude = position.latitude;
            _longitude = position.longitude;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _gpsFailed = true);
    } finally {
      if (mounted) setState(() => _isDetectingLieu = false);
    }
  }

  // Caméra unique de l'application, une seule image — pas de galerie
  // multi-photos (décision produit MVP) — même composant exact que la photo
  // de profil et la photo de groupe (replaceMode + isAvatarMode).
  Future<void> _pickPhoto() async {
    try {
      final path = await Navigator.push<String>(
        context,
        fastFadeRoute<String>(
          const ReportCameraPage(replaceMode: true, isAvatarMode: true),
        ),
      );
      if (path != null && mounted) setState(() => _photoPath = path);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // Réutilise exactement le composant déjà implémenté pour l'attribution des
  // signalements (report_upload_page.dart) — même logique "En mon nom" /
  // "Au nom d'un groupe" / "Anonyme", jamais dupliquée localement.
  Future<void> _pickAttribution() async {
    final result = await showAttributionChoiceSheet(context);
    if (mounted) setState(() => _attribution = result);
  }

  void _toggleCas(String id) {
    setState(() {
      if (!_selectedCasIds.remove(id)) _selectedCasIds.add(id);
    });
  }

  void _toggleAllCas(List<HomeReportModel> cas) {
    setState(() {
      if (_selectedCasIds.length == cas.length) {
        _selectedCasIds.clear();
      } else {
        _selectedCasIds
          ..clear()
          ..addAll(cas.map((r) => r.id));
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      final user = AuthStore.instance.currentUser!;
      final attribution = _attribution ??
          ReportAttribution(signaleParNom: user.username, signaleParId: user.id);
      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final besoinCommunication = _communicationController.text.trim().isEmpty
          ? null
          : _communicationController.text.trim();
      final besoinBenevoles = _benevolesController.text.trim().isEmpty
          ? null
          : _benevolesController.text.trim();
      final besoinFinancement = _financementController.text.trim().isEmpty
          ? null
          : _financementController.text.trim();
      final besoinMateriel = _materielController.text.trim().isEmpty
          ? null
          : _materielController.text.trim();
      final description =
          _descController.text.trim().isEmpty ? null : _descController.text.trim();

      if (_isEditMode) {
        final existing = ActionStore.instance.actionById(widget.actionId!)!;
        // Construction directe (pas copyWith) — copyWith retombe sur l'ancienne
        // valeur via `??` dès qu'un champ nullable est passé à null, ce qui
        // empêcherait d'effacer une description/un besoin existant.
        final updated = ActionModel(
          id: existing.id,
          type: _selectedType!,
          date: date,
          lieu: _lieuController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          description: description,
          photoPath: _photoPath,
          participantsCount: existing.participantsCount,
          statut: existing.statut,
          organisateurNom: attribution.signaleParNom,
          organisateurId: attribution.groupId ?? attribution.signaleParId,
          organisateurEstGroupe: attribution.groupId != null,
          isAnonyme: attribution.isAnonyme,
          casPrisEnChargeIds: _selectedCasIds.toList(),
          createdAt: existing.createdAt,
          viewsCount: existing.viewsCount,
          commentsCount: existing.commentsCount,
          sharesCount: existing.sharesCount,
          viewedByUserIds: existing.viewedByUserIds,
          commentsList: existing.commentsList,
          besoinCommunication: besoinCommunication,
          besoinBenevoles: besoinBenevoles,
          besoinFinancement: besoinFinancement,
          besoinMateriel: besoinMateriel,
        );
        await ActionStore.instance.updateAction(updated);
      } else {
        final model = ActionModel(
          id: '',
          type: _selectedType!,
          date: date,
          lieu: _lieuController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          description: description,
          photoPath: _photoPath,
          organisateurNom: attribution.signaleParNom,
          organisateurId: attribution.groupId ?? attribution.signaleParId,
          organisateurEstGroupe: attribution.groupId != null,
          isAnonyme: attribution.isAnonyme,
          casPrisEnChargeIds: _selectedCasIds.toList(),
          createdAt: DateTime.now(),
          besoinCommunication: besoinCommunication,
          besoinBenevoles: besoinBenevoles,
          besoinFinancement: besoinFinancement,
          besoinMateriel: besoinMateriel,
        );
        await ActionStore.instance.createAction(model);
      }
      if (mounted) Navigator.pop(context);
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
    final myCas = _myCasEnCours;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: CliinAppConstants.spacingM),
                    buildGroupFormLabeledField(
                      label: 'Photo de l\'action (facultatif)',
                      child: _buildPhotoPicker(),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    Text(
                      'Choisissez le type d\'action — même philosophie que '
                      'Signaler : rapide, sans saisie libre.',
                      style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingM),
                    _buildTypeGrid(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    _buildDateHeureRow(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    buildGroupFormLabeledField(
                      label: 'Lieu',
                      helper: _gpsFailed
                          ? 'GPS indisponible — vérifiez/complétez le lieu manuellement.'
                          : 'Détecté automatiquement — modifiable si besoin.',
                      child: _buildLieuField(),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                    _buildCasSection(myCas),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                    _buildBesoinsSection(),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    buildGroupFormLabeledField(
                      label: 'Description (facultatif)',
                      child: buildGroupFormTextField(
                        controller: _descController,
                        hint: 'Précisions utiles pour les participants...',
                        maxLines: null,
                        minLines: 4,
                      ),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    Text('Attribution',
                        style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13)),
                    const SizedBox(height: CliinAppConstants.spacingS),
                    _buildAttributionCard(),
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
                label: _isEditMode ? 'Enregistrer les modifications' : 'Publier l\'action',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Header — flèche retour + titre centré, espace vide à droite ──
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        MediaQuery.of(context).padding.top + 12,
        CliinAppConstants.pagePadding,
        12,
      ),
      child: Row(
        children: [
          CircleIconButton.back(onTap: () => Navigator.pop(context), size: 36, iconSize: 18),
          Expanded(
            child: Center(
              child: Text(_isEditMode ? 'Modifier l\'action' : 'Créer une action',
                  style: CliinAppTextStyles.headingMedium),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ── 2. Photo de l'action (facultatif) ────────────────────────────────
  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: SizedBox(
        width: double.infinity,
        height: 120,
        child: _photoPath == null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: GroupFormDashedRectPainter(color: CliinAppColors.divider),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_rounded,
                            color: CliinAppColors.textSecondary, size: 26),
                        const SizedBox(height: 6),
                        Text('Ajouter une photo',
                            style: CliinAppTextStyles.bodySmall
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
                child: buildReportImage(_photoPath!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  // ── 4. Grille des 13 types — sélection unique, aucune saisie libre ────
  Widget _buildTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: CliinAppConstants.spacingS,
      crossAxisSpacing: CliinAppConstants.spacingS,
      childAspectRatio: 2.6,
      children: ActionType.values.map(_buildTypeCell).toList(),
    );
  }

  Widget _buildTypeCell(ActionType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? type.color.withValues(alpha: 0.1) : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(
            color: selected ? type.color : CliinAppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(type.icon,
                color: selected ? type.color : CliinAppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                type.label,
                style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? type.color : CliinAppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. Date + Heure — sélecteurs natifs Flutter ────────────────────
  Widget _buildDateHeureRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: buildGroupFormLabeledField(
            label: 'Date',
            child: _buildPickerField(
              icon: Icons.calendar_today_rounded,
              value: formatActionDate(_selectedDate),
              onTap: _pickDate,
            ),
          ),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: buildGroupFormLabeledField(
            label: 'Heure',
            child: _buildPickerField(
              icon: Icons.access_time_rounded,
              value: formatActionHeure(
                  DateTime(2000, 1, 1, _selectedTime.hour, _selectedTime.minute)),
              onTap: _pickTime,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField(
      {required IconData icon, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: CliinAppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: CliinAppTextStyles.bodyMedium
                    .copyWith(color: CliinAppColors.textDark, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. Lieu — pré-rempli via GPS + reverse geocoding ───────────────
  Widget _buildLieuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _lieuController,
          textCapitalization: TextCapitalization.sentences,
          style: CliinAppTextStyles.bodyMedium.copyWith(color: CliinAppColors.textDark),
          decoration: InputDecoration(
            hintText: _isDetectingLieu ? 'Détection en cours...' : 'Ex : Riviera 2, Cocody',
            hintStyle: CliinAppTextStyles.bodyMedium,
            filled: true,
            fillColor: CliinAppColors.cardWhite,
            prefixIcon: const Icon(Icons.location_on_rounded, color: CliinAppColors.primary),
            suffixIcon: _isDetectingLieu
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: CliinAppColors.primary),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
              borderSide: const BorderSide(color: CliinAppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
              borderSide: const BorderSide(color: CliinAppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
              borderSide: const BorderSide(color: CliinAppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (_gpsFailed) ...[
          const SizedBox(height: 6),
          GpsRetryButton(isLoading: _isDetectingLieu, onPressed: _autoDetectLieu),
        ],
      ],
    );
  }

  // ── 7. Cas pris en charge — toujours optionnel, scroll horizontal ─────
  Widget _buildCasSection(List<HomeReportModel> cas) {
    final allSelected = cas.isNotEmpty && _selectedCasIds.length == cas.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Inclure des cas déjà pris en charge (optionnel)',
                  style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13)),
            ),
            if (cas.isNotEmpty)
              GestureDetector(
                onTap: () => _toggleAllCas(cas),
                child: Text(
                  allSelected ? 'Tout désélectionner' : 'Tout sélectionner',
                  style: CliinAppTextStyles.link.copyWith(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_selectedCasIds.length} sélectionné(s) sur ${cas.length}',
          style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 11),
        ),
        const SizedBox(height: CliinAppConstants.spacingM),
        if (cas.isEmpty)
          Text(
            'Aucun cas en cours à proposer pour le moment.',
            style: CliinAppTextStyles.bodySmall
                .copyWith(fontSize: 11.5, fontStyle: FontStyle.italic),
          )
        else ...[
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cas.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _buildCasCard(cas[i]),
            ),
          ),
          if (_selectedCasIds.isEmpty) ...[
            const SizedBox(height: CliinAppConstants.spacingS),
            Text(
              'Aucun cas sélectionné — cette action n\'affichera pas de '
              'section "Cas pris en charge".',
              style: CliinAppTextStyles.bodySmall
                  .copyWith(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildCasCard(HomeReportModel report) {
    final selected = _selectedCasIds.contains(report.id);
    return GestureDetector(
      onTap: () => _toggleCas(report.id),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(CliinAppConstants.spacingS),
        decoration: BoxDecoration(
          color: selected ? CliinAppColors.primaryLight : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(
            color: selected ? CliinAppColors.primary : CliinAppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: selected ? CliinAppColors.primary : CliinAppColors.textSecondary,
                  size: 18,
                ),
                const Spacer(),
                Icon(report.category.icon, color: report.category.color, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.title,
              style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: CliinAppColors.textDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 11, color: CliinAppColors.textSecondary),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    report.location,
                    style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 10.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 8. Besoins ponctuels — 4 champs courts, tous facultatifs ──────────
  Widget _buildBesoinsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Besoins pour cette action (optionnel)',
            style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13)),
        const SizedBox(height: 4),
        Text('Court et concret — laissez vide ce qui ne s\'applique pas.',
            style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 11)),
        const SizedBox(height: CliinAppConstants.spacingM),
        _buildBesoinField('📢', 'Communication et mobilisation', _communicationController,
            'Ex : Relais sur les réseaux du quartier'),
        const SizedBox(height: CliinAppConstants.spacingM),
        _buildBesoinField('🙋', 'Bénévoles', _benevolesController, 'Ex : 15 personnes'),
        const SizedBox(height: CliinAppConstants.spacingM),
        _buildBesoinField(
            '💰', 'Financement', _financementController, 'Ex : Budget transport'),
        const SizedBox(height: CliinAppConstants.spacingM),
        _buildBesoinField('🧰', 'Matériel et logistique', _materielController,
            'Ex : 5 brouettes, gants'),
      ],
    );
  }

  Widget _buildBesoinField(
      String emoji, String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label,
                style: CliinAppTextStyles.bodySmall.copyWith(
                    fontSize: 12, fontWeight: FontWeight.w600, color: CliinAppColors.textDark)),
          ],
        ),
        const SizedBox(height: 6),
        buildGroupFormTextField(controller: controller, hint: hint),
      ],
    );
  }

  // ── 10. Attribution — réutilise showAttributionChoiceSheet ────────────
  Widget _buildAttributionCard() {
    final a = _attribution;
    final label = a == null ? '...' : (a.isAnonyme ? 'Anonyme' : a.signaleParNom);
    final icon = a == null || (!a.isAnonyme && a.groupId == null)
        ? Icons.person_rounded
        : (a.isAnonyme ? Icons.visibility_off_rounded : Icons.group_rounded);
    return GestureDetector(
      onTap: _pickAttribution,
      child: Container(
        padding: const EdgeInsets.all(CliinAppConstants.spacingM),
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  const BoxDecoration(color: CliinAppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, color: CliinAppColors.primary, size: 18),
            ),
            const SizedBox(width: CliinAppConstants.spacingM),
            Expanded(
              child: Text(
                label,
                style: CliinAppTextStyles.bodyMedium
                    .copyWith(color: CliinAppColors.textDark, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('Modifier', style: CliinAppTextStyles.link.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
