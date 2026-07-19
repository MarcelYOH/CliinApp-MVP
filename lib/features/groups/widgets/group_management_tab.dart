// lib/features/groups/widgets/group_management_tab.dart
// Onglet "Espace gestion" du profil groupe — réservé aux administrateurs.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/data/mock_groups.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/store/report_store.dart';
import '../../home/models/home_report_model.dart';
import '../../profile/pages/mes_cas_signales_page.dart';
import '../../profile/pages/mes_prises_en_charge_page.dart';
import '../models/group_model.dart';
import 'add_admin_sheet.dart';
import 'group_form_fields.dart' show GroupFormDashedCirclePainter;

class GroupManagementTab extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;

  const GroupManagementTab({
    super.key,
    required this.group,
    required this.isAdmin,
  });

  bool _isGroupCas(HomeReportModel r) => r.groupId == mockGroupId(group.nom);
  bool _isGroupPriseEnCharge(HomeReportModel r) =>
      r.intervenant?.groupName == group.nom;

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le module Actions Terrain arrive bientôt.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAllAdmins(BuildContext context, List<GroupMemberModel> admins) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
              const SizedBox(height: CliinAppConstants.spacingL),
              Text('Tous les administrateurs',
                  style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 16)),
              const SizedBox(height: CliinAppConstants.spacingM),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: admins.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: CliinAppColors.divider),
                  itemBuilder: (_, i) {
                    final m = admins[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: CliinAppColors.primaryDark,
                        child: Text(
                          m.nom.trim().isEmpty ? '?' : m.nom.trim()[0].toUpperCase(),
                          style: const TextStyle(color: CliinAppColors.textWhite),
                        ),
                      ),
                      title: Text(m.nom,
                          style: CliinAppTextStyles.bodyMedium
                              .copyWith(color: CliinAppColors.textDark)),
                      subtitle: Text(
                          m.role ?? 'Administrateur délégué',
                          style: CliinAppTextStyles.bodySmall),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
          child: Text(
            'Cet espace est réservé aux administrateurs du groupe.',
            style: CliinAppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final admins = GroupStore.instance.cachedMembers(group.id);
    final casSignalesCount =
        ReportStore.instance.reports.where(_isGroupCas).length;
    final prisesEnChargeCount =
        ReportStore.instance.reports.where(_isGroupPriseEnCharge).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingM,
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingXL,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(CliinAppConstants.spacingM),
          decoration: BoxDecoration(
            color: CliinAppColors.background,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          ),
          child: Row(children: [
            const Icon(Icons.shield_outlined,
                color: CliinAppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Espace réservé aux administrateurs du groupe.',
                  style: CliinAppTextStyles.bodySmall),
            ),
          ]),
        ),
        const SizedBox(height: CliinAppConstants.spacingL),
        _buildAdminsRow(context, admins),
        const SizedBox(height: CliinAppConstants.spacingL),
        Text('Gestion du groupe', style: CliinAppTextStyles.headingSmall),
        const SizedBox(height: CliinAppConstants.spacingM),
        Container(
          decoration: BoxDecoration(
            color: CliinAppColors.cardWhite,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
            border: Border.all(color: CliinAppColors.divider),
          ),
          child: Column(children: [
            _buildRubriqueRow(
              icon: Icons.description_rounded,
              color: CliinAppColors.primary,
              label: 'Nos cas signalés',
              count: casSignalesCount,
              onTap: () => Navigator.push(
                context,
                fastFadeRoute<void>(MesCasSignalesPage(
                  headerTitle: 'Nos cas signalés',
                  filterOverride: _isGroupCas,
                )),
              ),
            ),
            const Divider(height: 1, color: CliinAppColors.divider),
            _buildRubriqueRow(
              icon: Icons.volunteer_activism_rounded,
              color: CliinAppColors.alertOrange,
              label: 'Nos prises en charge',
              count: prisesEnChargeCount,
              onTap: () => Navigator.push(
                context,
                fastFadeRoute<void>(MesPrisesEnChargePage(
                  headerTitle: 'Nos prises en charge',
                  filterOverride: _isGroupPriseEnCharge,
                )),
              ),
            ),
            const Divider(height: 1, color: CliinAppColors.divider),
            _buildRubriqueRow(
              icon: Icons.bolt_rounded,
              color: CliinAppColors.levelOfficiel,
              label: 'Nos actions',
              count: group.actionsCount,
              onTap: () => _showComingSoon(context),
            ),
          ]),
        ),
        const SizedBox(height: CliinAppConstants.spacingL),
        Text(
          'En tant qu\'administrateur, vous pouvez modifier, supprimer, '
          'prendre en charge et soumettre une preuve pour tout cas rattaché '
          'au groupe — peu importe quel membre l\'a signalé.',
          style: CliinAppTextStyles.bodySmall.copyWith(
              fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildAdminsRow(BuildContext context, List<GroupMemberModel> admins) {
    final visible = admins.take(5).toList();
    final overflow = admins.length - visible.length;
    return SizedBox(
      height: 52,
      child: Row(children: [
        for (final m in visible)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: CliinAppColors.primaryDark,
              child: Text(
                m.nom.trim().isEmpty ? '?' : m.nom.trim()[0].toUpperCase(),
                style: const TextStyle(
                    color: CliinAppColors.textWhite, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _showAllAdmins(context, admins),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: CliinAppColors.background,
                child: Text('+$overflow',
                    style: CliinAppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        GestureDetector(
          onTap: () => showAddAdminSheet(context, groupId: group.id),
          child: CustomPaint(
            painter:
                const GroupFormDashedCirclePainter(color: CliinAppColors.primary),
            size: const Size(48, 48),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.add_rounded,
                  color: CliinAppColors.primary, size: 22),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildRubriqueRow({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(CliinAppConstants.spacingM),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: CliinAppColors.textWhite, size: 18),
          ),
          const SizedBox(width: CliinAppConstants.spacingM),
          Expanded(
            child: Text(label,
                style: CliinAppTextStyles.bodyMedium
                    .copyWith(color: CliinAppColors.textDark, fontWeight: FontWeight.w600)),
          ),
          Text('$count',
              style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 14)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              color: CliinAppColors.textSecondary, size: 18),
        ]),
      ),
    );
  }
}
