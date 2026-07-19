// lib/features/groups/pages/edit_group_page.dart
// Modification d'un groupe existant — même structure visuelle exacte que
// CreateGroupPage, pré-remplie avec les valeurs actuelles. Accessible
// uniquement depuis les Paramètres du groupe (Lot 3), réservé aux
// administrateurs.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/group_store.dart';
import '../../reports/pages/report_camera_page.dart';
import '../models/group_model.dart';
import '../widgets/group_form_fields.dart';

class EditGroupPage extends StatefulWidget {
  final String groupId;

  const EditGroupPage({super.key, required this.groupId});

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late final GroupModel? _group;

  final _nomController = TextEditingController();
  final _zoneController = TextEditingController();
  final _descController = TextEditingController();

  String? _photoPath;
  GroupType _selectedType = GroupType.ong;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isSubmitting &&
      _nomController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _group = GroupStore.instance.groupById(widget.groupId);
    final group = _group;
    if (group != null) {
      _nomController.text = group.nom;
      _zoneController.text = group.zone;
      _descController.text = group.description;
      _photoPath = group.photoPath;
      _selectedType = group.type;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _zoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    try {
      // GroupModel.description EST "Qui sommes-nous" — même donnée, jamais
      // une copie séparée : la mise à jour se reflète directement dans le
      // profil au retour.
      await GroupStore.instance.updateGroup(
        widget.groupId,
        nom: _nomController.text.trim(),
        photoPath: _photoPath,
        description: _descController.text.trim(),
        type: _selectedType,
        zone: _zoneController.text.trim(),
      );
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
    if (_group == null) {
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
                    buildGroupFormPhotoPicker(
                        photoPath: _photoPath, onTap: _pickPhoto),
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
                        hint: 'Ex : Riviera 2, Cocody',
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
                label: 'Enregistrer les modifications',
              ),
            ),
          ],
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
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded,
              color: CliinAppColors.textDark, size: 24),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Text('Modifier le groupe', style: CliinAppTextStyles.headingMedium),
      ]),
    );
  }
}
