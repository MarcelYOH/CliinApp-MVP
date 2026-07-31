// lib/features/notifications/pages/notifications_page.dart
// Page unique "Notifications" — reproduit fidèlement page_notifications.jsx.
// Accessible depuis toute icône cloche 🔔 de l'application.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/action_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/store/notification_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/report_card.dart' show reportTimeAgoLabel;
import '../../actions/pages/action_detail_page.dart';
import '../../groups/pages/group_profile_page.dart';
import '../../reports/pages/intervenant_detail_page.dart';
import '../../reports/pages/report_detail_page.dart';
import '../models/notification_model.dart';

enum _NotifFilter { toutes, nonLues }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NotifFilter _filter = _NotifFilter.toutes;

  void _showNotFound(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Élément introuvable — il a peut-être été supprimé.'),
          behavior: SnackBarBehavior.floating),
    );
  }

  // Au tap : marque comme lue + navigue vers l'écran concerné selon le
  // type (voir la colonne "destination" de TYPES_NOTIF dans
  // page_notifications.jsx). referenceId absent ou introuvable -> message
  // clair plutôt qu'une navigation cassée.
  Future<void> _handleTap(BuildContext context, NotificationModel notif) async {
    await NotificationStore.instance.marquerCommeLue(notif.id);
    if (!context.mounted) return;
    final refId = notif.referenceId;
    if (refId == null) {
      _showNotFound(context);
      return;
    }

    switch (notif.type) {
      case NotificationType.prisEnCharge:
        final report = ReportStore.instance.reportById(refId);
        if (report == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(
            context, fastFadeRoute<void>(ReportDetailPage(data: report, isAuthor: true)));
        return;

      case NotificationType.traite:
      case NotificationType.conteste:
      case NotificationType.delaiExpire:
      case NotificationType.preuveRejetee:
        final report = ReportStore.instance.reportById(refId);
        if (report == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(context, fastFadeRoute<void>(IntervenantDetailPage(report: report)));
        return;

      // Correction 3 — le destinataire est un simple suiveur (pas
      // nécessairement auteur ni intervenant) : vue publique du cas, pas
      // le tableau de bord privé de l'intervenant.
      case NotificationType.casSuiviMisAJour:
        final report = ReportStore.instance.reportById(refId);
        if (report == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(context, fastFadeRoute<void>(ReportDetailPage(data: report)));
        return;

      case NotificationType.commentaire:
        final report = ReportStore.instance.reportById(refId);
        if (report == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(context, fastFadeRoute<void>(ReportDetailPage(data: report)));
        return;

      case NotificationType.abandonne:
      case NotificationType.rejete:
        final report = ReportStore.instance.reportById(refId);
        if (report == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(
            context, fastFadeRoute<void>(ReportDetailPage(data: report, isAuthor: false)));
        return;

      case NotificationType.nouveauMembre:
      case NotificationType.nouveauBadge:
        final group = GroupStore.instance.groupById(refId);
        if (group == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(
            context, fastFadeRoute<void>(GroupProfilePage(groupId: group.id)));
        return;

      case NotificationType.actionOrganisee:
        final group = GroupStore.instance.groupById(refId);
        if (group == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(context,
            fastFadeRoute<void>(GroupProfilePage(groupId: group.id, initialTab: 1)));
        return;

      case NotificationType.actionRappel:
      case NotificationType.nouvelleAction:
      case NotificationType.commentaireAction:
      case NotificationType.nouveauParticipant:
        final action = ActionStore.instance.actionById(refId);
        if (action == null) {
          _showNotFound(context);
          return;
        }
        Navigator.push(context, fastFadeRoute<void>(ActionDetailPage(data: action)));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationStore.instance,
      builder: (context, _) {
        final all = NotificationStore.instance.notifications;
        final nonLues = all.where((n) => !n.lu).length;
        final affichees =
            _filter == _NotifFilter.nonLues ? all.where((n) => !n.lu).toList() : all;

        return Scaffold(
          backgroundColor: CliinAppColors.background,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, nonLues),
                _buildTabs(nonLues),
                Expanded(
                  child: affichees.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom),
                          itemCount: affichees.length,
                          itemBuilder: (context, i) =>
                              _buildNotifRow(context, affichees[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int nonLues) {
    return Container(
      color: CliinAppColors.cardWhite,
      decoration:
          const BoxDecoration(border: Border(bottom: BorderSide(color: CliinAppColors.divider))),
      padding: EdgeInsets.fromLTRB(CliinAppConstants.pagePadding,
          MediaQuery.of(context).padding.top + 12, CliinAppConstants.pagePadding, 12),
      child: Row(children: [
        CircleIconButton.back(onTap: () => Navigator.pop(context), size: 38, iconSize: 18),
        const SizedBox(width: CliinAppConstants.spacingM),
        Expanded(
          child: Text('Notifications',
              style: CliinAppTextStyles.headingLarge.copyWith(fontSize: 20)),
        ),
        if (nonLues > 0)
          GestureDetector(
            onTap: () => NotificationStore.instance.marquerToutCommeLu(),
            child: Text('Tout marquer lu',
                style: CliinAppTextStyles.link.copyWith(fontSize: 11.5)),
          ),
      ]),
    );
  }

  Widget _buildTabs(int nonLues) {
    return Container(
      color: CliinAppColors.cardWhite,
      padding: const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      decoration:
          const BoxDecoration(border: Border(bottom: BorderSide(color: CliinAppColors.divider))),
      child: Row(children: [
        _buildTabItem('Toutes', _NotifFilter.toutes),
        const SizedBox(width: CliinAppConstants.spacingL),
        _buildTabItem(
            'Non lues${nonLues > 0 ? ' ($nonLues)' : ''}', _NotifFilter.nonLues),
      ]),
    );
  }

  Widget _buildTabItem(String label, _NotifFilter filter) {
    final selected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? CliinAppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: CliinAppTextStyles.bodySmall.copyWith(
            fontSize: 12.5,
            color: selected ? CliinAppColors.primary : CliinAppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNotifRow(BuildContext context, NotificationModel notif) {
    return GestureDetector(
      onTap: () => _handleTap(context, notif),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding, vertical: CliinAppConstants.spacingM),
        decoration: BoxDecoration(
          color: notif.lu ? Colors.transparent : CliinAppColors.primaryLight,
          border: const Border(bottom: BorderSide(color: CliinAppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notif.type.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(notif.type.icon, color: notif.type.color, size: 19),
            ),
            const SizedBox(width: CliinAppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif.titre,
                          style: CliinAppTextStyles.headingSmall.copyWith(
                              fontSize: 13,
                              fontWeight: notif.lu ? FontWeight.w600 : FontWeight.w700),
                        ),
                      ),
                      if (!notif.lu)
                        Container(
                          margin: const EdgeInsets.only(top: 4, left: 6),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: CliinAppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notif.texte,
                      style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(reportTimeAgoLabel(notif.dateCreation, ''),
                      style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 10.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFilteredEmpty = _filter == _NotifFilter.nonLues;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.pagePadding, vertical: CliinAppConstants.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: CliinAppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_off_outlined,
                  color: CliinAppColors.primary, size: 28),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text(
              isFilteredEmpty
                  ? 'Aucune notification non lue'
                  : 'Aucune notification pour le moment',
              style: CliinAppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Vous serez averti dès qu\'une action concernant vos cas, vos '
              'prises en charge ou vos groupes aura lieu.',
              style: CliinAppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
