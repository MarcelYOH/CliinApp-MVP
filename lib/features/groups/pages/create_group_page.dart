// lib/features/groups/pages/create_group_page.dart
// Création d'un groupe — philosophie "moins d'une minute", 4 champs +
// photo facultative — CliinApp

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../reports/pages/report_camera_page.dart';
import '../models/group_model.dart';
import 'group_profile_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nomController = TextEditingController();
  final _zoneController = TextEditingController();
  final _descController = TextEditingController();

  String? _photoPath;
  GroupType _selectedType = GroupType.ong;
  bool _isDetectingZone = false;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isSubmitting &&
      _nomController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty;

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
          setState(() => _zoneController.text = parts.join(', '));
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
    final user = AuthStore.instance.currentUser!;
    try {
      final created = await GroupStore.instance.createGroup(
        nom: _nomController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        zone: _zoneController.text.trim(),
        photoPath: _photoPath,
        createurId: user.id,
        createurNom: user.username,
        createurAvatarPath: user.avatarPath,
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
                    _buildPhotoPicker(),
                    const SizedBox(height: CliinAppConstants.spacingXL),
                    _buildLabeledField(
                      label: 'Nom du groupe',
                      child: _buildTextField(
                        controller: _nomController,
                        hint: 'Ex : Clean Riviera',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    _buildLabeledField(
                      label: 'Type de groupe',
                      child: _buildTypeChips(),
                    ),
                    const SizedBox(height: CliinAppConstants.spacingL),
                    _buildLabeledField(
                      label: 'Zone principale',
                      helper: 'Détectée automatiquement — modifiable si besoin.',
                      child: _buildTextField(
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
                    _buildLabeledField(
                      label: 'Description',
                      child: _buildTextField(
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
              child: _buildSubmitButton(),
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
        Text('Créer un groupe', style: CliinAppTextStyles.headingMedium),
      ]),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        child: SizedBox(
          width: 90,
          height: 90,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(90, 90),
              painter: const _DashedCirclePainter(color: CliinAppColors.primary),
            ),
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: _photoPath != null
                  ? Image.file(File(_photoPath!),
                      fit: BoxFit.cover, width: 78, height: 78)
                  : const Icon(Icons.camera_alt_rounded,
                      color: CliinAppColors.primary, size: 30),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    String? helper,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper, style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 11)),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
    int? minLines,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      style: CliinAppTextStyles.bodyMedium.copyWith(color: CliinAppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: CliinAppTextStyles.bodyMedium,
        filled: true,
        fillColor: CliinAppColors.cardWhite,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }

  Widget _buildTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GroupType.values.map((t) {
        final selected = _selectedType == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? CliinAppColors.primary : CliinAppColors.cardWhite,
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
              border: Border.all(
                color: selected ? CliinAppColors.primary : CliinAppColors.divider,
              ),
            ),
            child: Text(
              t.label,
              style: CliinAppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    selected ? CliinAppColors.textWhite : CliinAppColors.textDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSubmit ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: CliinAppColors.primary,
          disabledBackgroundColor: CliinAppColors.divider,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text('Créer le groupe',
                style: CliinAppTextStyles.button.copyWith(fontSize: 15)),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  static const double _dashLength = 5;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (_dashLength + _gapLength)).floor();
    final dashAngle = _dashLength / radius;
    final gapAngle = _gapLength / radius;

    var angle = -pi / 2;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashAngle,
        false,
        paint,
      );
      angle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
