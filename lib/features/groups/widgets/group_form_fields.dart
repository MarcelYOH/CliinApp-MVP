// lib/features/groups/widgets/group_form_fields.dart
//
// Champs de formulaire partagés entre CreateGroupPage et EditGroupPage —
// même structure visuelle exacte pour les deux (photo, nom, type, zone,
// description). Ne jamais dupliquer ces widgets localement dans une page.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/report_card.dart' show buildReportImage;
import '../models/group_model.dart';

Widget buildGroupFormPhotoPicker({
  required String? photoPath,
  required VoidCallback onTap,
}) {
  return Center(
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        height: 90,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: const Size(90, 90),
            painter:
                const GroupFormDashedCirclePainter(color: CliinAppColors.primary),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: CliinAppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: photoPath != null
                ? buildReportImage(photoPath, fit: BoxFit.cover)
                : const Icon(Icons.camera_alt_rounded,
                    color: CliinAppColors.primary, size: 30),
          ),
        ]),
      ),
    ),
  );
}

// ── Photo de bannière/couverture — rectangulaire, distincte du logo ─────
Widget buildGroupFormBannerPicker({
  required String? bannerPath,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: double.infinity,
      height: 110,
      child: Stack(fit: StackFit.expand, children: [
        CustomPaint(
          painter: GroupFormDashedRectPainter(color: CliinAppColors.primary),
        ),
        Padding(
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusMedium - 2),
            child: Container(
              color: CliinAppColors.primaryLight,
              child: bannerPath != null
                  ? buildReportImage(bannerPath, fit: BoxFit.cover)
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_outlined,
                              color: CliinAppColors.primary, size: 26),
                          const SizedBox(height: 4),
                          Text('Photo de couverture',
                              style: CliinAppTextStyles.bodySmall.copyWith(
                                  color: CliinAppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ]),
    ),
  );
}

Widget buildGroupFormLabeledField({
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

Widget buildGroupFormTextField({
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
  );
}

Widget buildGroupFormTypeChips({
  required GroupType selected,
  required ValueChanged<GroupType> onSelect,
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: GroupType.values.map((t) {
      final isSelected = selected == t;
      return GestureDetector(
        onTap: () => onSelect(t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? CliinAppColors.primary : CliinAppColors.cardWhite,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
            border: Border.all(
              color: isSelected ? CliinAppColors.primary : CliinAppColors.divider,
            ),
          ),
          child: Text(
            t.label,
            style: CliinAppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? CliinAppColors.textWhite : CliinAppColors.textDark,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

Widget buildGroupFormSubmitButton({
  required bool enabled,
  required bool isSubmitting,
  required VoidCallback onPressed,
  required String label,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: CliinAppColors.primary,
        disabledBackgroundColor: CliinAppColors.divider,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        elevation: 0,
      ),
      child: isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: CliinAppTextStyles.button.copyWith(fontSize: 15)),
    ),
  );
}

class GroupFormDashedCirclePainter extends CustomPainter {
  final Color color;
  const GroupFormDashedCirclePainter({required this.color});

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
  bool shouldRepaint(covariant GroupFormDashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class GroupFormDashedRectPainter extends CustomPainter {
  final Color color;
  GroupFormDashedRectPainter({required this.color});

  static const double _dashLength = 5;
  static const double _gapLength = 4;
  static const double _radius = CliinAppConstants.radiusMedium;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(_radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant GroupFormDashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
