// lib/features/reports/widgets/attribution_choice_sheet.dart
// Choix d'attribution avant publication d'un cas signalé : en son nom,
// au nom d'un groupe, ou anonymement.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/store/auth_store.dart';
import '../../../../shared/store/group_store.dart';
import '../../../../features/groups/models/group_model.dart' show GroupModel;

class ReportAttribution {
  final String signaleParNom;
  final String signaleParId;
  final String? groupId;
  final bool isAnonyme;

  const ReportAttribution({
    required this.signaleParNom,
    required this.signaleParId,
    this.groupId,
    this.isAnonyme = false,
  });
}

enum _AttributionChoice { self, group, anonymous }

Future<ReportAttribution> showAttributionChoiceSheet(
    BuildContext context) async {
  debugPrint('[ATTRIBUTION-DEBUG] showAttributionChoiceSheet: entrée dans la fonction');
  final user = AuthStore.instance.currentUser;
  debugPrint('[ATTRIBUTION-DEBUG] showAttributionChoiceSheet: currentUser=${user?.id}');
  if (user == null) {
    debugPrint('[ATTRIBUTION-DEBUG] showAttributionChoiceSheet: currentUser NULL — retour anticipé sans afficher la feuille');
    return const ReportAttribution(signaleParNom: 'Vous', signaleParId: '');
  }
  // Vrais groupes dont l'utilisateur connecté est administrateur — jamais
  // une liste factice déconnectée (voir GroupStore.adminGroups).
  final myGroups = GroupStore.instance.adminGroups(user.id);
  debugPrint('[ATTRIBUTION-DEBUG] showAttributionChoiceSheet: myGroups.length=${myGroups.length}, appel showModalBottomSheet');
  final result = await showModalBottomSheet<ReportAttribution>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttributionSheet(
      username: user.username,
      userId: user.id,
      myGroups: myGroups,
    ),
  );
  debugPrint('[ATTRIBUTION-DEBUG] showAttributionChoiceSheet: showModalBottomSheet a rendu, result=${result == null ? "null (fermé sans choix)" : "choix confirmé"}');
  return result ??
      ReportAttribution(signaleParNom: user.username, signaleParId: user.id);
}

class _AttributionSheet extends StatefulWidget {
  final String username;
  final String userId;
  final List<GroupModel> myGroups;
  const _AttributionSheet({
    required this.username,
    required this.userId,
    required this.myGroups,
  });

  @override
  State<_AttributionSheet> createState() => _AttributionSheetState();
}

class _AttributionSheetState extends State<_AttributionSheet> {
  _AttributionChoice _choice = _AttributionChoice.self;
  GroupModel? _selectedGroup;

  bool get _isValid =>
      _choice != _AttributionChoice.group || _selectedGroup != null;

  void _confirm() {
    late final ReportAttribution attribution;
    switch (_choice) {
      case _AttributionChoice.self:
        attribution = ReportAttribution(
          signaleParNom: widget.username,
          signaleParId: widget.userId,
        );
      case _AttributionChoice.group:
        final group = _selectedGroup!;
        attribution = ReportAttribution(
          signaleParNom: group.nom,
          signaleParId: widget.userId,
          groupId: group.id,
        );
      case _AttributionChoice.anonymous:
        attribution = ReportAttribution(
          signaleParNom: 'Anonyme',
          signaleParId: widget.userId,
          isAnonyme: true,
        );
    }
    Navigator.pop(context, attribution);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[ATTRIBUTION-DEBUG] _AttributionSheet.build: la feuille est en cours de rendu à l\'écran');
    return Container(
      decoration: const BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding, 0,
        CliinAppConstants.pagePadding, 0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: CliinAppConstants.spacingM),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: CliinAppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            Text('Comment publier ce cas ?',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: CliinAppColors.textDark)),
            Text('Choisissez comment ce cas signalé sera attribué.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: CliinAppColors.textSecondary)),
            const SizedBox(height: CliinAppConstants.spacingL),
            _AttributionCard(
              selected: _choice == _AttributionChoice.self,
              icon: Icons.person_rounded,
              title: 'En mon nom',
              subtitle: 'Votre nom sera visible publiquement sur ce cas.',
              onTap: () => setState(() => _choice = _AttributionChoice.self),
            ),
            if (widget.myGroups.isNotEmpty) ...[
              const SizedBox(height: CliinAppConstants.spacingM),
              _AttributionCard(
                selected: _choice == _AttributionChoice.group,
                icon: Icons.group_rounded,
                title: 'Au nom d\'un groupe',
                subtitle: 'Publier au nom d\'un groupe dont vous êtes membre.',
                onTap: () => setState(() => _choice = _AttributionChoice.group),
              ),
              if (_choice == _AttributionChoice.group) ...[
                const SizedBox(height: CliinAppConstants.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: CliinAppColors.cardWhite,
                    borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
                    border: Border.all(color: CliinAppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<GroupModel>(
                      value: _selectedGroup,
                      isExpanded: true,
                      hint: Text('Choisir un groupe',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: CliinAppColors.textSecondary)),
                      items: widget.myGroups.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g.nom, style: GoogleFonts.inter(fontSize: 13)),
                      )).toList(),
                      onChanged: (g) => setState(() => _selectedGroup = g),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: CliinAppConstants.spacingM),
            _AttributionCard(
              selected: _choice == _AttributionChoice.anonymous,
              icon: Icons.visibility_off_rounded,
              title: 'Publier anonymement',
              subtitle: 'Aucun nom ne sera affiché publiquement sur ce cas.',
              onTap: () => setState(() => _choice = _AttributionChoice.anonymous),
            ),
            const SizedBox(height: CliinAppConstants.spacingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CliinAppColors.primary,
                  disabledBackgroundColor: CliinAppColors.divider,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text('Publier le cas',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: CliinAppColors.textWhite)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _AttributionCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttributionCard({
    required this.selected, required this.icon,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(CliinAppConstants.spacingL),
      decoration: BoxDecoration(
        color: selected ? CliinAppColors.primaryLight : CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(
          color: selected ? CliinAppColors.primary : CliinAppColors.divider,
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: selected ? CliinAppColors.primary : CliinAppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: selected ? CliinAppColors.textWhite : CliinAppColors.textSecondary,
              size: 20),
        ),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: CliinAppColors.textSecondary)),
          ]),
        ),
        if (selected)
          const Icon(Icons.check_circle_rounded,
              color: CliinAppColors.primary, size: 20),
      ]),
    ),
  );
}
