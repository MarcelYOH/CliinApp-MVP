// lib/features/groups/widgets/add_admin_sheet.dart
// Sheet "Ajouter un administrateur" — Espace gestion du profil groupe.
// Étape 1 : recherche parmi les membres déjà existants du groupe.
// Étape 2 : choix du rôle — 6 postes classiques, "Autre..." (saisie libre)
// ou "Administrateur (sans poste officiel)".

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/store/group_store.dart';
import '../models/group_model.dart';
import 'group_form_fields.dart';

// Postes "classiques" du bureau exécutif — élargis de 4 à 6 (correction 4).
// Un même poste ne peut avoir qu'un seul titulaire par groupe à la fois
// (correction 3, voir GroupStore.takenPostes) : ne jamais dupliquer cette
// liste, elle est la source unique pour la création ET l'ajout d'admin.
const List<String> kGroupClassicPostes = [
  'Président',
  'Vice-président(e)',
  'Secrétaire général(e)',
  'Trésorier(ère)',
  'Chargé(e) des programmes et opérations',
  'Chargé(e) de communication',
];

// Saisie libre — soumise à la même règle d'unicité (insensible à la casse)
// que les postes classiques une fois le texte validé.
const String kAutrePosteOption = 'Autre...';

// Réservée à l'ajout d'un administrateur délégué (jamais au créateur, qui
// occupe toujours un poste officiel — voir kFounderPosteOptions).
const String kAdminSansPosteOption = 'Administrateur (sans poste officiel)';

Future<void> showAddAdminSheet(BuildContext context, {required String groupId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddAdminSheet(groupId: groupId),
    ),
  );
}

class _AddAdminSheet extends StatefulWidget {
  final String groupId;
  const _AddAdminSheet({required this.groupId});

  @override
  State<_AddAdminSheet> createState() => _AddAdminSheetState();
}

class _AddAdminSheetState extends State<_AddAdminSheet> {
  int _step = 1;
  final _searchController = TextEditingController();
  final _customPosteController = TextEditingController();
  List<GroupMemberModel> _results = const [];
  GroupMemberModel? _selectedMember;
  String? _selectedRole;
  String? _posteError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customPosteController.dispose();
    super.dispose();
  }

  // Postes classiques déjà attribués dans ce groupe — jamais reproposés
  // (correction 3). "Autre..." et "Administrateur sans poste officiel" ne
  // sont jamais filtrés : le premier ouvre une saisie libre validée à part,
  // le second n'attribue aucun poste donc ne peut jamais entrer en conflit.
  List<String> get _availableClassicPostes {
    final taken = GroupStore.instance
        .takenPostes(widget.groupId)
        .map((p) => p.toLowerCase())
        .toSet();
    return kGroupClassicPostes
        .where((p) => !taken.contains(p.toLowerCase()))
        .toList();
  }

  Future<void> _search(String query) async {
    final results =
        await GroupStore.instance.searchSympathisants(widget.groupId, query);
    if (mounted) setState(() => _results = results);
  }

  void _selectMember(GroupMemberModel member) {
    setState(() {
      _selectedMember = member;
      _selectedRole = null;
      _step = 2;
    });
  }

  bool get _canConfirm {
    if (_selectedRole == null) return false;
    if (_selectedRole == kAutrePosteOption) {
      return _customPosteController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _confirm() async {
    final member = _selectedMember;
    if (member == null || !_canConfirm) return;

    String? poste;
    if (_selectedRole == kAdminSansPosteOption) {
      poste = null;
    } else if (_selectedRole == kAutrePosteOption) {
      poste = _customPosteController.text.trim();
      final taken = GroupStore.instance
          .takenPostes(widget.groupId)
          .map((p) => p.toLowerCase())
          .toSet();
      if (taken.contains(poste.toLowerCase())) {
        setState(() =>
            _posteError = 'Ce poste est déjà attribué à quelqu\'un d\'autre.');
        return;
      }
    } else {
      poste = _selectedRole;
    }

    setState(() {
      _posteError = null;
      _isSubmitting = true;
    });
    await GroupStore.instance.addAdmin(widget.groupId, member, poste: poste);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
          CliinAppConstants.pagePadding, 0, CliinAppConstants.pagePadding, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: CliinAppConstants.spacingM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CliinAppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            _step == 1 ? _buildStep1() : _buildStep2(),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ajouter un administrateur',
            style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text('Recherchez parmi les membres du groupe.',
            style: CliinAppTextStyles.bodySmall),
        const SizedBox(height: CliinAppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: CliinAppColors.background,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            style: CliinAppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Nom ou numéro de téléphone...',
              hintStyle: CliinAppTextStyles.bodySmall,
              prefixIcon: const Icon(Icons.search_rounded,
                  color: CliinAppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: CliinAppConstants.spacingM),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: _results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: CliinAppConstants.spacingL),
                  child: Text('Aucun membre trouvé.',
                      style: CliinAppTextStyles.bodySmall),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.only(bottom: CliinAppConstants.spacingM),
                  itemCount: _results.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: CliinAppColors.divider),
                  itemBuilder: (_, i) => _buildSympathisantRow(_results[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSympathisantRow(GroupMemberModel member) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _selectMember(member),
      leading: CircleAvatar(
        backgroundColor: CliinAppColors.primaryDark,
        child: Text(
          member.nom.trim().isEmpty ? '?' : member.nom.trim()[0].toUpperCase(),
          style: const TextStyle(color: CliinAppColors.textWhite, fontSize: 14),
        ),
      ),
      title: Text(member.nom,
          style: CliinAppTextStyles.bodyMedium
              .copyWith(color: CliinAppColors.textDark)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: CliinAppColors.textSecondary),
    );
  }

  Widget _buildStep2() {
    final member = _selectedMember!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text('Choisir un rôle',
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 18)),
          ),
          GestureDetector(
            onTap: () => setState(() => _step = 1),
            child: Text('Changer',
                style: CliinAppTextStyles.link.copyWith(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: CliinAppColors.primaryDark,
            child: Text(
              member.nom.trim().isEmpty ? '?' : member.nom.trim()[0].toUpperCase(),
              style: const TextStyle(color: CliinAppColors.textWhite, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(member.nom,
              style: CliinAppTextStyles.bodyMedium
                  .copyWith(color: CliinAppColors.textDark, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: CliinAppConstants.spacingM),
        Container(
          padding: const EdgeInsets.all(CliinAppConstants.spacingM),
          decoration: BoxDecoration(
            color: CliinAppColors.primaryLight,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: CliinAppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Un poste officiel ajoute la personne à "Notre équipe", visible '
                'publiquement. Sans poste, elle reste administratrice déléguée, '
                'visible uniquement dans l\'Espace gestion.',
                style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 11),
              ),
            ),
          ]),
        ),
        const SizedBox(height: CliinAppConstants.spacingM),
        ...[..._availableClassicPostes, kAutrePosteOption, kAdminSansPosteOption]
            .map((role) {
          final selected = _selectedRole == role;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedRole = role;
                _posteError = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? CliinAppColors.primaryLight
                      : CliinAppColors.cardWhite,
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium),
                  border: Border.all(
                    color: selected
                        ? CliinAppColors.primary
                        : CliinAppColors.divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(role,
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
        }),
        if (_selectedRole == kAutrePosteOption) ...[
          const SizedBox(height: 4),
          buildGroupFormTextField(
            controller: _customPosteController,
            hint: 'Ex : Responsable logistique',
            onChanged: (_) => setState(() => _posteError = null),
          ),
          if (_posteError != null) ...[
            const SizedBox(height: 4),
            Text(_posteError!,
                style: CliinAppTextStyles.bodySmall
                    .copyWith(color: CliinAppColors.alertRed)),
          ],
        ],
        const SizedBox(height: CliinAppConstants.spacingS),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_canConfirm && !_isSubmitting) ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: CliinAppColors.primary,
              disabledBackgroundColor: CliinAppColors.divider,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Confirmer l\'ajout',
                    style: CliinAppTextStyles.button.copyWith(fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
