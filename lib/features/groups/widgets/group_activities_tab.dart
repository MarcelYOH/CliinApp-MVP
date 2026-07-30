// lib/features/groups/widgets/group_activities_tab.dart
//
// Onglet "Publications" du profil groupe (renommé depuis "Activités",
// Correction 1) — feed mixte des actions terrain organisées PAR ce groupe
// (ActionStore, organisateurEstGroupe && organisateurId == group.id) ET des
// signalements publiés EN SON NOM par ses membres (ReportStore,
// r.groupId == group.id — même logique déjà utilisée par l'Espace gestion,
// group_management_tab.dart). Recherche texte unifiée (search_helper.dart)
// + filtre de nature (Tout/Actions/Signalements) + filtre de statut
// dynamique selon la nature. Réutilise les vraies cartes déjà validées
// (ActionCard, ReportCard) — jamais de carte dupliquée. "Organiser une
// action" ouvre exactement CreateActionPage, avec ce groupe pré-sélectionné.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/whatsapp_launcher.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/navigation/profile_navigation.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/utils/search_helper.dart';
import '../../../shared/widgets/action_card.dart';
import '../../../shared/widgets/report_card.dart';
import '../../actions/models/action_model.dart';
import '../../actions/pages/action_detail_page.dart';
import '../../actions/pages/create_action_page.dart';
import '../../auth/auth_guard.dart';
import '../../home/models/home_report_model.dart';
import '../../reports/pages/intervenant_detail_page.dart';
import '../../reports/pages/report_detail_page.dart';
import '../../reports/widgets/take_charge_flow.dart';
import '../models/group_model.dart';
import 'group_profile_widgets.dart';

enum _PubNature { tout, actions, signalements }

sealed class _FeedItem {
  DateTime get sortDate;
}

class _ActionFeedItem extends _FeedItem {
  final ActionModel action;
  _ActionFeedItem(this.action);
  @override
  DateTime get sortDate => action.createdAt;
}

class _ReportFeedItem extends _FeedItem {
  final HomeReportModel report;
  _ReportFeedItem(this.report);
  @override
  DateTime get sortDate => report.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class GroupActivitiesTab extends StatefulWidget {
  final GroupModel group;
  const GroupActivitiesTab({super.key, required this.group});

  @override
  State<GroupActivitiesTab> createState() => _GroupActivitiesTabState();
}

class _GroupActivitiesTabState extends State<GroupActivitiesTab> {
  _PubNature _nature = _PubNature.tout;
  String? _selectedStatusLabel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isGroupAction(ActionModel a) =>
      a.organisateurEstGroupe && a.organisateurId == widget.group.id;
  bool _isGroupReport(HomeReportModel r) => r.groupId == widget.group.id;

  // Statuts affichés — dépend de la nature choisie (Correction 1.3).
  List<String> get _statusChips => switch (_nature) {
        _PubNature.tout => const [
            'Disponible', 'En cours', 'Traité', 'À venir', 'Terminée',
          ],
        _PubNature.actions => const ['À venir', 'En cours', 'Terminée'],
        _PubNature.signalements => const ['Disponible', 'En cours', 'Traité'],
      };

  void _onNatureTap(_PubNature n) {
    setState(() {
      _nature = n;
      // "Actions" présélectionne "À venir" par défaut ; les autres natures
      // n'ont aucun statut présélectionné (Correction 1.3).
      _selectedStatusLabel = n == _PubNature.actions ? 'À venir' : null;
    });
  }

  Future<void> _openCreateAction(BuildContext context) async {
    if (await requireAuth(context)) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        fastFadeRoute<void>(CreateActionPage(preselectedGroupId: widget.group.id)),
      );
    }
  }

  void _openActionDetail(BuildContext context, ActionModel action) {
    Navigator.push(context, fastFadeRoute<void>(ActionDetailPage(data: action)));
  }

  void _onReportTap(HomeReportModel report) {
    Navigator.push(context, fastFadeRoute<void>(ReportDetailPage(data: report)));
  }

  void _onTakeCharge(HomeReportModel report) async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      showTakeChargeFlow(
        context: context,
        report: report,
        onSuccess: (updated) {
          if (mounted) {
            Navigator.push(
              context,
              fastFadeRoute<void>(IntervenantDetailPage(report: updated)),
            );
          }
        },
      );
    }
  }

  void _onContact(HomeReportModel report) {
    openWhatsApp(context: context, intervenant: report.intervenant);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ActionStore.instance, ReportStore.instance]),
      builder: (context, _) {
        final actions = _nature == _PubNature.signalements
            ? const <ActionModel>[]
            : ActionStore.instance.allActions.where(_isGroupAction).where((a) {
                if (_selectedStatusLabel != null &&
                    a.statut.label != _selectedStatusLabel) {
                  return false;
                }
                return matchesSearch(_searchQuery, [a.type.label, a.description, a.lieu]);
              }).toList();

        final reports = _nature == _PubNature.actions
            ? const <HomeReportModel>[]
            : ReportStore.instance.reports.where(_isGroupReport).where((r) {
                if (_selectedStatusLabel != null &&
                    r.status.label != _selectedStatusLabel) {
                  return false;
                }
                return matchesSearch(
                    _searchQuery, [r.title, r.description, r.location, r.reference]);
              }).toList();

        final items = <_FeedItem>[
          ...actions.map(_ActionFeedItem.new),
          ...reports.map(_ReportFeedItem.new),
        ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(CliinAppConstants.pagePadding, 0,
                  CliinAppConstants.pagePadding, CliinAppConstants.spacingM),
              child: _buildSearchBar(),
            ),
            _buildNatureRow(),
            const SizedBox(height: CliinAppConstants.spacingS),
            _buildStatusRow(),
            const SizedBox(height: CliinAppConstants.spacingM),
            Expanded(
              child: items.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: CliinAppConstants.pagePadding),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: CliinAppConstants.spacingM),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return switch (item) {
                          _ActionFeedItem(:final action) => ActionCard(
                              data: action,
                              onTap: () => _openActionDetail(context, action),
                            ),
                          _ReportFeedItem(:final report) => ReportCard(
                              data: report,
                              onTap: () => _onReportTap(report),
                              onTakeCharge: () => _onTakeCharge(report),
                              onContact: () => _onContact(report),
                              onIntervenantTap: () =>
                                  openIntervenantProfile(context, report),
                            ),
                        };
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
              child: GestureDetector(
                onTap: () => _openCreateAction(context),
                child: CustomPaint(
                  painter: const GroupDashedRectPainter(
                      color: CliinAppColors.primary,
                      radius: CliinAppConstants.radiusMedium),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: CliinAppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text('Organiser une action',
                            style: CliinAppTextStyles.link.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: CliinAppTextStyles.bodyMedium.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Titre, catégorie, lieu...',
          hintStyle: CliinAppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            color: CliinAppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: CliinAppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : GestureDetector(
                  onTap: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                  child: const Icon(Icons.close_rounded,
                      color: CliinAppColors.textSecondary, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNatureRow() {
    const natures = [
      (_PubNature.tout, 'Tout'),
      (_PubNature.actions, 'Actions'),
      (_PubNature.signalements, 'Signalements'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: Row(
        children: natures
            .map((n) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _chip(
                    label: n.$2,
                    selected: _nature == n.$1,
                    onTap: () => _onNatureTap(n.$1),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStatusRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: Row(
        children: _statusChips
            .map((label) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _chip(
                    label: label,
                    selected: _selectedStatusLabel == label,
                    onTap: () => setState(() => _selectedStatusLabel =
                        _selectedStatusLabel == label ? null : label),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CliinAppColors.primary : CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? CliinAppColors.primary : CliinAppColors.divider),
        ),
        child: Text(
          label,
          style: CliinAppTextStyles.bodySmall.copyWith(
            color: selected ? CliinAppColors.textWhite : CliinAppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dynamic_feed_rounded,
              color: CliinAppColors.textSecondary, size: 40),
          const SizedBox(height: CliinAppConstants.spacingM),
          Text('Aucune publication pour l\'instant',
              style: CliinAppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(
            'Les actions organisées et les signalements publiés au nom de ce '
            'groupe apparaîtront ici.',
            style: CliinAppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
