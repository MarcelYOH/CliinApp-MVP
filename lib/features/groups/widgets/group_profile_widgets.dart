// lib/features/groups/widgets/group_profile_widgets.dart
//
// Widgets partagés par l'onglet "À propos" du profil groupe : le cadre de
// thème (trait vertical + titre) et la carte d'info éditable (logique
// Indiegogo — "Qui sommes-nous", "Notre mission", etc.).

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

class GroupThemeSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color accentColor;
  final Color backgroundColor;
  final Color? borderColor;
  final List<Widget> children;

  const GroupThemeSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
    this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: CliinAppTextStyles.headingSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: CliinAppColors.textDark)),
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(subtitle!,
                  style:
                      CliinAppTextStyles.bodySmall.copyWith(fontSize: 11)),
            ),
          ],
          const SizedBox(height: CliinAppConstants.spacingM),
          ...children,
        ],
      ),
    );
  }
}

// Carte d'info éditable (logique Indiegogo) — utilisée pour "Qui sommes-nous",
// "Notre mission", "Nos activités clés" et les 4 catégories de "Nos besoins".
// Bouton Modifier/Ajouter réservé aux admins ; état vide adapté selon que le
// visiteur est admin ou non.
class GroupEditableInfoSection extends StatefulWidget {
  final String title;
  final String? value;
  final String placeholder;
  final bool isAdmin;
  final Future<void> Function(String newValue) onSave;

  const GroupEditableInfoSection({
    super.key,
    required this.title,
    required this.value,
    required this.placeholder,
    required this.isAdmin,
    required this.onSave,
  });

  @override
  State<GroupEditableInfoSection> createState() =>
      _GroupEditableInfoSectionState();
}

class _GroupEditableInfoSectionState extends State<GroupEditableInfoSection> {
  bool _isEditing = false;
  bool _isSaving = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant GroupEditableInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEdit() {
    _controller.text = widget.value ?? '';
    setState(() => _isEditing = true);
  }

  void _cancel() => setState(() => _isEditing = false);

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_controller.text.trim());
      if (mounted) setState(() => _isEditing = false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null && widget.value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title,
                style: CliinAppTextStyles.headingSmall.copyWith(
                    fontSize: 13.5, color: CliinAppColors.textDark)),
            if (widget.isAdmin && !_isEditing)
              GestureDetector(
                onTap: _startEdit,
                child: Text(hasValue ? 'Modifier' : 'Ajouter',
                    style: CliinAppTextStyles.link.copyWith(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_isEditing) ...[
          TextField(
            controller: _controller,
            maxLines: null,
            minLines: 3,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: CliinAppTextStyles.bodyMedium
                .copyWith(color: CliinAppColors.textDark),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: CliinAppTextStyles.bodyMedium
                  .copyWith(fontStyle: FontStyle.italic),
              filled: true,
              fillColor: CliinAppColors.cardWhite,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
                borderSide: const BorderSide(color: CliinAppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
                borderSide:
                    const BorderSide(color: CliinAppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            TextButton(
              onPressed: _isSaving ? null : _cancel,
              child: Text('Annuler',
                  style: CliinAppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: CliinAppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Enregistrer',
                      style: CliinAppTextStyles.button.copyWith(fontSize: 12)),
            ),
          ]),
        ] else if (hasValue)
          Text(widget.value!,
              style: CliinAppTextStyles.bodyMedium
                  .copyWith(color: CliinAppColors.textDark))
        else
          Text(
            widget.isAdmin ? widget.placeholder : 'Non renseigné pour l\'instant.',
            style: CliinAppTextStyles.bodyMedium.copyWith(
              fontStyle: widget.isAdmin ? FontStyle.italic : FontStyle.normal,
              color: CliinAppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

// Bordure arrondie pointillée — utilisée pour les boutons "call to action"
// discrets (ex: "Organiser une action"). Flutter n'a pas de style de
// bordure pointillée natif pour un rectangle arrondi.
class GroupDashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const GroupDashedRectPainter({required this.color, this.radius = 14});

  static const double _dashLength = 5;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
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
  bool shouldRepaint(covariant GroupDashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

Widget buildGroupImpactStatCard({
  required IconData icon,
  required String value,
  required String label,
}) {
  return Container(
    width: 92,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: CliinAppColors.cardWhite,
      borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      border: Border.all(color: CliinAppColors.divider),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: CliinAppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: CliinAppTextStyles.headingSmall.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CliinAppColors.textDark)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 10)),
      ],
    ),
  );
}
