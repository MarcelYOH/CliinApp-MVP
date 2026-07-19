// lib/features/groups/widgets/group_about_tab.dart
// Onglet "À propos" du profil groupe — logique Indiegogo, 3 thèmes visuels.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/store/group_store.dart';
import '../models/group_model.dart';
import 'group_profile_widgets.dart';

class GroupAboutTab extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;

  const GroupAboutTab({super.key, required this.group, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final members = GroupStore.instance.bureauExecutifMembers(group.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingM,
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingXL,
      ),
      children: [
        // ═══ THÈME 1 — PRÉSENTATION ═══
        GroupThemeSection(
          title: 'Présentation',
          accentColor: CliinAppColors.primary,
          backgroundColor: CliinAppColors.cardWhite,
          borderColor: CliinAppColors.divider,
          children: [
            GroupEditableInfoSection(
              title: 'Qui sommes-nous',
              value: group.description,
              placeholder: 'Présentez votre structure en quelques phrases...',
              isAdmin: isAdmin,
              onSave: (v) async {
                await GroupStore.instance.updateGroup(group.id, description: v);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CliinAppConstants.spacingM),
              child: Divider(height: 1, color: CliinAppColors.divider),
            ),
            GroupEditableInfoSection(
              title: 'Notre mission',
              value: group.missionTexte,
              placeholder: 'Quel est l\'objectif de votre groupe ?',
              isAdmin: isAdmin,
              onSave: (v) async {
                await GroupStore.instance.updateGroup(group.id, missionTexte: v);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CliinAppConstants.spacingM),
              child: Divider(height: 1, color: CliinAppColors.divider),
            ),
            GroupEditableInfoSection(
              title: 'Nos activités clés',
              value: group.activitesClesTexte,
              placeholder:
                  'Listez vos principales activités (nettoyage, sensibilisation, collecte...)',
              isAdmin: isAdmin,
              onSave: (v) async {
                await GroupStore.instance
                    .updateGroup(group.id, activitesClesTexte: v);
              },
            ),
          ],
        ),

        const SizedBox(height: CliinAppConstants.spacingL),

        // ═══ THÈME 2 — IMPACT & ÉQUIPE ═══
        GroupThemeSection(
          title: 'Impact & équipe',
          accentColor: CliinAppColors.levelOfficiel,
          backgroundColor: CliinAppColors.background,
          children: [
            Text('Notre impact',
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13.5)),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildImpactCarousel(),
            const SizedBox(height: CliinAppConstants.spacingL),
            Text('Notre équipe',
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13.5)),
            const SizedBox(height: CliinAppConstants.spacingM),
            members.isEmpty
                ? Text('Aucun membre du bureau exécutif renseigné pour l\'instant.',
                    style: CliinAppTextStyles.bodySmall)
                : Column(children: [
                    for (var i = 0; i < members.length; i++) ...[
                      if (i > 0) const SizedBox(height: CliinAppConstants.spacingM),
                      _buildTeamMemberRow(members[i]),
                    ],
                  ]),
            const SizedBox(height: CliinAppConstants.spacingL),
            Text('Nos sympathisants',
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13.5)),
            const SizedBox(height: CliinAppConstants.spacingM),
            _buildSympathisantsCard(),
          ],
        ),

        const SizedBox(height: CliinAppConstants.spacingL),

        // ═══ THÈME 3 — NOS BESOINS ═══
        GroupThemeSection(
          title: 'Nos besoins',
          subtitle:
              'Besoins permanents, renseignés par nature — pour un besoin '
              'ponctuel lié à une action précise, utilisez Organiser une action.',
          accentColor: CliinAppColors.primary,
          backgroundColor: CliinAppColors.primaryLight,
          borderColor: CliinAppColors.primary,
          children: [
            GroupEditableInfoSection(
              title: '📢 Communication et mobilisation',
              value: group.besoinCommunication,
              placeholder: 'Décrivez votre besoin en communication...',
              isAdmin: isAdmin,
              onSave: (v) async {
                await GroupStore.instance
                    .updateGroup(group.id, besoinCommunication: v);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CliinAppConstants.spacingM),
              child: Divider(height: 1, color: CliinAppColors.primary),
            ),
            GroupEditableInfoSection(
              title: '🙋 Bénévoles',
              value: group.besoinBenevoles,
              placeholder: 'Décrivez votre besoin en bénévoles...',
              isAdmin: isAdmin,
              onSave: (v) async {
                await GroupStore.instance
                    .updateGroup(group.id, besoinBenevoles: v);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CliinAppConstants.spacingM),
              child: Divider(height: 1, color: CliinAppColors.primary),
            ),
            GroupEditableInfoSection(
              title: '💰 Financement',
              value: group.besoinFinancement,
              placeholder: 'Décrivez votre besoin en financement...',
              isAdmin: isAdmin,
              onSave: (v) async {
                await GroupStore.instance
                    .updateGroup(group.id, besoinFinancement: v);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CliinAppConstants.spacingM),
              child: Divider(height: 1, color: CliinAppColors.primary),
            ),
            GroupEditableInfoSection(
              title: '🧰 Matériel et logistique',
              value: group.besoinMateriel,
              placeholder: 'Décrivez votre besoin en matériel...',
              isAdmin: isAdmin,
              onSave: (v) async {
                await GroupStore.instance
                    .updateGroup(group.id, besoinMateriel: v);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImpactCarousel() {
    // "Mobilisation moyenne/action" nécessite les participations réelles par
    // action (module Actions Terrain, pas encore implémenté) — affichée en
    // "—" plutôt qu'une valeur inventée, en attendant.
    final cards = [
      (Icons.campaign_rounded, '${group.casSignalesCount}', 'Cas signalés'),
      (Icons.task_alt_rounded, '${group.casTraitesCount}', 'Cas traités'),
      (Icons.volunteer_activism_rounded, '${group.casPrisEnChargeCount}',
          'Pris en charge'),
      (Icons.bolt_rounded, '${group.actionsCount}', 'Actions'),
      (Icons.groups_rounded, '—', 'Mobilisation\nmoyenne/action'),
    ];
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: CliinAppConstants.spacingS),
        itemBuilder: (_, i) => buildGroupImpactStatCard(
          icon: cards[i].$1,
          value: cards[i].$2,
          label: cards[i].$3,
        ),
      ),
    );
  }

  Widget _buildTeamMemberRow(GroupMemberModel member) {
    return Row(children: [
      Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: CliinAppColors.primaryDark,
          shape: BoxShape.circle,
        ),
        child: member.avatarPath != null
            ? ClipOval(
                child: Image.asset(member.avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initialsAvatar(member.nom)))
            : _initialsAvatar(member.nom),
      ),
      const SizedBox(width: CliinAppConstants.spacingM),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.nom,
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13)),
            if (member.role != null)
              Text(member.role!,
                  style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
      ),
    ]);
  }

  Widget _initialsAvatar(String nom) {
    final initials = nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase();
    return Center(
      child: Text(initials,
          style: CliinAppTextStyles.badge
              .copyWith(color: CliinAppColors.textWhite, fontSize: 14)),
    );
  }

  Widget _buildSympathisantsCard() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(children: [
        const Icon(Icons.group_rounded, color: CliinAppColors.primary, size: 24),
        const SizedBox(width: CliinAppConstants.spacingM),
        Text.rich(
          TextSpan(
            style:
                CliinAppTextStyles.bodyMedium.copyWith(color: CliinAppColors.textDark),
            children: [
              TextSpan(
                text: '${group.sympathisantsCount} ',
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 15),
              ),
              const TextSpan(text: 'sympathisants au total'),
            ],
          ),
        ),
      ]),
    );
  }
}
