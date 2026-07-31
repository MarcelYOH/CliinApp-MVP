// lib/features/groups/pages/group_contributors_page.dart
//
// Page "Nos contributeurs" (Correction 1) — classement des membres qui
// contribuent au groupe, agrégé depuis 4 sources DÉJÀ EXISTANTES (jamais
// une nouvelle logique métier, jamais une donnée inventée) :
// - Cas signalés      : ReportStore.reports où groupId == group.id, groupé
//   par signaleParId (même source que "Nos cas signalés").
// - Prises en charge  : ReportStore.reports où intervenant.groupName ==
//   group.nom, groupé par intervenant.id (même source que "Nos prises en
//   charge").
// - Actions organisées : ActionStore.allActions où organisateurEstGroupe &&
//   organisateurId == group.id, groupé par creeParId (même source que "Nos
//   actions").
// - Participations    : ActionStore.participantIdsFor(actionId) pour
//   chaque action du groupe, agrégé par participant (même bookkeeping déjà
//   produit par joinAction, simplement exposé en lecture).
//
// ⚠️ Point à clarifier signalé dans le rapport : cette app (mock, sans
// annuaire multi-utilisateurs réel — un seul utilisateur authentifiable à
// la fois) ne peut résoudre un nom/avatar/rôle que pour l'utilisateur
// courant (AuthStore) ou un membre déjà mis en cache comme administrateur
// du groupe (GroupStore.cachedMembers). Un contributeur dont l'id ne
// correspond à aucun des deux affiche le libellé générique "Membre" — non
// une identité inventée.
//
// Page unique, poussée depuis 2 points d'entrée distincts (onglet "Nos
// contributeurs" du profil groupe + rubrique de l'Espace gestion) — jamais
// dupliquée.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/report_card.dart' show buildReportImage;
import '../models/group_model.dart';

enum ContributionType { casSignales, prisesEnCharge, actionsOrganisees, participations }

extension ContributionTypeExt on ContributionType {
  String get label => switch (this) {
        ContributionType.casSignales => 'Cas signalés',
        ContributionType.prisesEnCharge => 'Prises en charge',
        ContributionType.actionsOrganisees => 'Actions organisées',
        ContributionType.participations => 'Participations',
      };

  IconData get icon => switch (this) {
        ContributionType.casSignales => Icons.description_rounded,
        ContributionType.prisesEnCharge => Icons.volunteer_activism_rounded,
        ContributionType.actionsOrganisees => Icons.campaign_rounded,
        ContributionType.participations => Icons.groups_rounded,
      };

  // Couleurs déjà définies dans app_colors.dart — violet (levelEngage) et
  // bleu (levelOfficiel) réutilisés tels quels, cohérents avec le reste de
  // la palette (aucune nouvelle constante nécessaire pour ces deux-là).
  Color get color => switch (this) {
        ContributionType.casSignales => CliinAppColors.primary,
        ContributionType.prisesEnCharge => CliinAppColors.alertOrange,
        ContributionType.actionsOrganisees => CliinAppColors.levelEngage,
        ContributionType.participations => CliinAppColors.levelOfficiel,
      };
}

class GroupContributorStats {
  final String userId;
  final String nom;
  final String? avatarPath;
  final String? role;
  final Map<ContributionType, int> counts;

  const GroupContributorStats({
    required this.userId,
    required this.nom,
    this.avatarPath,
    this.role,
    required this.counts,
  });

  int get total => counts.values.fold(0, (a, b) => a + b);
  int countFor(ContributionType? type) => type == null ? total : (counts[type] ?? 0);
}

(String, String?, String?) _resolveIdentity(GroupModel group, String userId) {
  final currentUser = AuthStore.instance.currentUser;
  if (currentUser != null && currentUser.id == userId) {
    return (currentUser.username, currentUser.avatarPath, 'Vous');
  }
  final cached =
      GroupStore.instance.cachedMembers(group.id).where((m) => m.id == userId);
  if (cached.isNotEmpty) {
    final m = cached.first;
    return (
      m.nom,
      GroupStore.instance.effectiveAvatarPath(m),
      m.role ?? (m.estAdmin ? 'Administrateur' : 'Membre'),
    );
  }
  return ('Membre', null, null);
}

// Réutilisée par cette page ET par la rubrique "Nos contributeurs" de
// l'Espace gestion (comptage) — jamais recalculée deux fois sous une forme
// différente.
List<GroupContributorStats> computeGroupContributors(GroupModel group) {
  final reportsSignales =
      ReportStore.instance.reports.where((r) => r.groupId == group.id).toList();
  final reportsPrisEnCharge = ReportStore.instance.reports
      .where((r) => r.intervenant?.groupName == group.nom)
      .toList();
  final groupActions = ActionStore.instance.allActions
      .where((a) => a.organisateurEstGroupe && a.organisateurId == group.id)
      .toList();
  final participantsByAction = <String, Set<String>>{
    for (final a in groupActions) a.id: ActionStore.instance.participantIdsFor(a.id),
  };

  final ids = <String>{};
  for (final r in reportsSignales) {
    if (r.signaleParId != null) ids.add(r.signaleParId!);
  }
  for (final r in reportsPrisEnCharge) {
    final id = r.intervenant?.id;
    if (id != null) ids.add(id);
  }
  for (final a in groupActions) {
    ids.add(a.creeParId);
  }
  for (final participants in participantsByAction.values) {
    ids.addAll(participants);
  }

  final result = <GroupContributorStats>[];
  for (final id in ids) {
    final casSignales = reportsSignales.where((r) => r.signaleParId == id).length;
    final prisesEnCharge =
        reportsPrisEnCharge.where((r) => r.intervenant?.id == id).length;
    final actionsOrganisees = groupActions.where((a) => a.creeParId == id).length;
    final participations =
        participantsByAction.values.where((p) => p.contains(id)).length;

    // Jamais un membre à 0 contribution — jamais une fausse valeur "pour
    // faire joli" (règle critique de la Correction 1).
    if (casSignales + prisesEnCharge + actionsOrganisees + participations == 0) {
      continue;
    }

    final (nom, avatarPath, role) = _resolveIdentity(group, id);
    result.add(GroupContributorStats(
      userId: id,
      nom: nom,
      avatarPath: avatarPath,
      role: role,
      counts: {
        ContributionType.casSignales: casSignales,
        ContributionType.prisesEnCharge: prisesEnCharge,
        ContributionType.actionsOrganisees: actionsOrganisees,
        ContributionType.participations: participations,
      },
    ));
  }
  return result;
}

class GroupContributorsPage extends StatefulWidget {
  final GroupModel group;
  const GroupContributorsPage({super.key, required this.group});

  @override
  State<GroupContributorsPage> createState() => _GroupContributorsPageState();
}

class _GroupContributorsPageState extends State<GroupContributorsPage> {
  ContributionType? _selectedFilter; // null = "Tout"

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [ReportStore.instance, ActionStore.instance, GroupStore.instance]),
      builder: (context, _) {
        final contributors = computeGroupContributors(widget.group)
          ..sort((a, b) => b.countFor(_selectedFilter).compareTo(a.countFor(_selectedFilter)));

        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                // Correction 5 — zone FIXE (ne scrolle jamais) : bandeau
                // explicatif, filtres, compteur. Seule la liste des
                // contributeurs ci-dessous est scrollable.
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    CliinAppConstants.pagePadding,
                    CliinAppConstants.spacingM,
                    CliinAppConstants.pagePadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBanner(),
                      const SizedBox(height: CliinAppConstants.spacingL),
                      _buildFilterRow(),
                      const SizedBox(height: CliinAppConstants.spacingM),
                      Text(
                        '${contributors.length} membre'
                        '${contributors.length > 1 ? 's' : ''} contributeur'
                        '${contributors.length > 1 ? 's' : ''} classé'
                        '${contributors.length > 1 ? 's' : ''}',
                        style: CliinAppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600, color: CliinAppColors.textDark),
                      ),
                      const SizedBox(height: CliinAppConstants.spacingM),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      CliinAppConstants.pagePadding,
                      0,
                      CliinAppConstants.pagePadding,
                      MediaQuery.of(context).padding.bottom + CliinAppConstants.spacingXL,
                    ),
                    children: [
                      if (contributors.isEmpty)
                        _buildEmpty()
                      else
                        for (var i = 0; i < contributors.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: i < contributors.length - 1
                                    ? CliinAppConstants.spacingS
                                    : 0),
                            child: _buildContributorRow(contributors[i], i),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: CliinAppColors.cardWhite,
      decoration:
          const BoxDecoration(border: Border(bottom: BorderSide(color: CliinAppColors.divider))),
      padding: EdgeInsets.fromLTRB(CliinAppConstants.pagePadding,
          MediaQuery.of(context).padding.top + 12, CliinAppConstants.pagePadding, 12),
      child: Row(children: [
        CircleIconButton.back(onTap: () => Navigator.pop(context), size: 36, iconSize: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Nos contributeurs',
              style: CliinAppTextStyles.headingMedium.copyWith(fontSize: 15)),
        ),
      ]),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(children: [
        const Icon(Icons.trending_up_rounded, color: CliinAppColors.primary, size: 22),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Text(
            'Vue d\'ensemble des membres qui contribuent au groupe — utile '
            'pour identifier et valoriser les plus engagés.',
            style: CliinAppTextStyles.bodySmall.copyWith(color: CliinAppColors.textDark),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterRow() {
    const types = [null, ...ContributionType.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < types.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i < types.length - 1 ? 8 : 0),
              child: _buildFilterChip(types[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ContributionType? type) {
    final selected = _selectedFilter == type;
    final color = type?.color ?? CliinAppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (type != null) ...[
            Icon(type.icon, size: 14, color: selected ? CliinAppColors.textWhite : color),
            const SizedBox(width: 5),
          ],
          Text(
            type?.label ?? 'Tout',
            style: CliinAppTextStyles.bodySmall.copyWith(
              color: selected ? CliinAppColors.textWhite : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildContributorRow(GroupContributorStats c, int index) {
    final rank = index + 1;
    return Container(
      padding: const EdgeInsets.all(CliinAppConstants.spacingM),
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: CliinAppConstants.spacingM),
          _buildAvatar(c),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nom,
                    style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (c.role != null)
                  Text(c.role!, style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 11)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  children: [
                    for (final type in ContributionType.values)
                      if ((c.counts[type] ?? 0) > 0) _buildMiniIcon(type, c.counts[type]!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: CliinAppConstants.spacingS),
          Text('${c.total}',
              style:
                  CliinAppTextStyles.headingSmall.copyWith(fontSize: 16, color: CliinAppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank > 3) {
      return SizedBox(
        width: 32,
        child: Center(
          child: Text('$rank',
              style: CliinAppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700, color: CliinAppColors.textSecondary)),
        ),
      );
    }
    final (icon, color) = switch (rank) {
      1 => (Icons.emoji_events_rounded, CliinAppColors.podiumGold),
      2 => (Icons.military_tech_rounded, CliinAppColors.podiumSilver),
      _ => (Icons.workspace_premium_rounded, CliinAppColors.podiumBronze),
    };
    return Container(
      width: 32,
      height: 32,
      decoration:
          BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildAvatar(GroupContributorStats c) {
    const size = 44.0;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: CliinAppColors.primaryDark, shape: BoxShape.circle),
      child: c.avatarPath != null
          ? ClipOval(
              child: buildReportImage(c.avatarPath!,
                  fit: BoxFit.cover, errorBuilder: (_, _, _) => _initials(c.nom)))
          : _initials(c.nom),
    );
  }

  Widget _initials(String nom) {
    final initials = nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase();
    return Center(
      child: Text(initials,
          style: const TextStyle(color: CliinAppColors.textWhite, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMiniIcon(ContributionType type, int count) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(type.icon, size: 12, color: type.color),
      const SizedBox(width: 2),
      Text('$count',
          style: CliinAppTextStyles.bodySmall
              .copyWith(fontSize: 10, color: type.color, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CliinAppConstants.spacingXL),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, color: CliinAppColors.textSecondary, size: 40),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text('Aucun contributeur pour l\'instant', style: CliinAppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(
              'Les membres qui signalent, prennent en charge, organisent ou '
              'participent apparaîtront ici.',
              style: CliinAppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
