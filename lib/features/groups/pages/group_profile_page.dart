// lib/features/groups/pages/group_profile_page.dart
// Profil complet du groupe — cœur du module Groupes.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/navigation/fast_page_route.dart';
import '../../../shared/navigation/tab_navigation.dart';
import '../../../shared/store/auth_store.dart';
import '../../../shared/store/group_store.dart';
import '../../../shared/store/report_store.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/group_badge_chip.dart';
import '../../auth/auth_guard.dart';
import '../../reports/pages/report_camera_page.dart';
import '../models/group_model.dart';
import '../widgets/group_about_tab.dart';
import '../widgets/group_activities_tab.dart';
import '../widgets/group_chat_tab.dart';
import '../widgets/group_management_tab.dart';
import '../widgets/group_settings_sheet.dart';
import 'edit_group_page.dart';

class GroupProfilePage extends StatefulWidget {
  final String groupId;

  const GroupProfilePage({super.key, required this.groupId});

  @override
  State<GroupProfilePage> createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends State<GroupProfilePage> {
  static const _tabLabels = ['À propos', 'Activités', 'Espace gestion', 'Chat'];

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    GroupStore.instance.addListener(_onStoreUpdate);
    AuthStore.instance.addListener(_onStoreUpdate);
    // "Pris en charge" (onglet À propos) est calculé dynamiquement depuis
    // ReportStore (casPrisEnChargeCountForGroup) — doit se rafraîchir dès
    // qu'une attribution change, sans attendre une réouverture de la page.
    ReportStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    GroupStore.instance.removeListener(_onStoreUpdate);
    AuthStore.instance.removeListener(_onStoreUpdate);
    ReportStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFollow(GroupModel group) async {
    if (!await requireAuth(context)) return;
    if (!mounted) return;
    final userId = AuthStore.instance.currentUser!.id;
    final isFollowing = GroupStore.instance.isFollowing(group.id, userId);
    if (isFollowing) {
      await GroupStore.instance.unfollowGroup(group.id, userId);
    } else {
      await GroupStore.instance.followGroup(group.id, userId);
    }
  }

  Future<void> _openSettings(GroupModel group) async {
    final action = await showGroupSettingsSheet(context);
    if (!mounted || action == null) return;

    if (action == GroupSettingsAction.edit) {
      await Navigator.push(
        context,
        fastFadeRoute<void>(EditGroupPage(groupId: group.id)),
      );
      return;
    }

    // Suppression — confirmation obligatoire, action irréversible.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce groupe ?'),
        content: const Text(
          'Cette action est irréversible. Toutes les informations du '
          'groupe seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: CliinAppColors.alertRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await GroupStore.instance.deleteGroup(group.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _share(GroupModel group) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction de partage bientôt disponible.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCamera() async {
    if (await requireAuth(context)) {
      if (!mounted) return;
      Navigator.push(context, fastFadeRoute<void>(const ReportCameraPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = GroupStore.instance.groupById(widget.groupId);
    if (group == null) {
      return _buildNotFoundScaffold(context);
    }

    final userId = AuthStore.instance.currentUser?.id;
    final isAdmin =
        userId != null && GroupStore.instance.isAdmin(group.id, userId);
    final isFollowing =
        userId != null && GroupStore.instance.isFollowing(group.id, userId);

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildCoverAndAvatar(context, group),
            _buildIdentityBlock(group),
            _buildActionButtons(group, isAdmin, isFollowing),
            _buildTabBar(),
            const SizedBox(height: CliinAppConstants.spacingS),
            Expanded(child: _buildTabContent(group, isAdmin)),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (index) =>
            navigateToTab(context, currentIndex: -1, targetIndex: index),
        onSignalerTap: _openCamera,
      ),
    );
  }

  Widget _buildTabContent(GroupModel group, bool isAdmin) {
    return switch (_selectedTab) {
      0 => GroupAboutTab(group: group, isAdmin: isAdmin),
      1 => const GroupActivitiesTab(),
      2 => GroupManagementTab(group: group, isAdmin: isAdmin),
      _ => const GroupChatTab(),
    };
  }

  Widget _buildNotFoundScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                CliinAppConstants.pagePadding,
                MediaQuery.of(context).padding.top + 12,
                CliinAppConstants.pagePadding,
                12,
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_rounded,
                    color: CliinAppColors.textDark, size: 24),
              ),
            ),
            Expanded(
              child: Center(
                child: Text('Groupe introuvable',
                    style: CliinAppTextStyles.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cover + avatar ─────────────────────────────────────────────
  Widget _buildCoverAndAvatar(BuildContext context, GroupModel group) {
    const coverHeight = 150.0;
    const avatarSize = 84.0;
    return SizedBox(
      height: coverHeight + avatarSize / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: coverHeight, child: _buildCoverBackground()),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _circleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _circleIconButton(
              icon: Icons.share_outlined,
              onTap: () => _share(group),
            ),
          ),
          Positioned(
            top: coverHeight - avatarSize / 2,
            left: 0,
            right: 0,
            child: Center(child: _buildAvatar(group, avatarSize)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverBackground() {
    // Cover toujours en dégradé — le modèle ne porte qu'une seule image
    // (photoPath), utilisée pour l'avatar rond (même choix que GroupCard).
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CliinAppColors.primary, CliinAppColors.primaryDark],
        ),
      ),
      child: Center(
        child: Icon(Icons.groups_rounded,
            color: CliinAppColors.textWhite.withValues(alpha: 0.22), size: 56),
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildAvatar(GroupModel group, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CliinAppColors.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(color: CliinAppColors.cardWhite, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: group.photoPath != null
          ? ClipOval(
              child: Image.asset(
                group.photoPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _avatarInitials(group.nom),
              ),
            )
          : _avatarInitials(group.nom),
    );
  }

  Widget _avatarInitials(String nom) {
    final initials = nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase();
    return Center(
      child: Text(initials,
          style: const TextStyle(
              color: CliinAppColors.textWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold)),
    );
  }

  // ── Identité ────────────────────────────────────────────────────
  Widget _buildIdentityBlock(GroupModel group) {
    final orderedBadges = kGroupBadgeOrder.where(group.badges.contains).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingM,
        CliinAppConstants.pagePadding,
        0,
      ),
      child: Column(
        children: [
          Text(
            group.nom,
            textAlign: TextAlign.center,
            style: CliinAppTextStyles.headingLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CliinAppColors.textDark),
          ),
          const SizedBox(height: 8),
          _buildTypeChip(group.type),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_rounded,
                color: CliinAppColors.textSecondary, size: 15),
            const SizedBox(width: 4),
            Text(group.zone, style: CliinAppTextStyles.bodySmall),
          ]),
          if (orderedBadges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children:
                  orderedBadges.map((b) => GroupBadgeChip(badge: b)).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text('${group.sympathisantsCount} membres',
              style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(GroupType type) {
    final icon = switch (type) {
      GroupType.ong => Icons.public_rounded,
      GroupType.association => Icons.account_balance_rounded,
      GroupType.benevoles => Icons.volunteer_activism_rounded,
      GroupType.autre => Icons.category_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CliinAppColors.background,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: CliinAppColors.textSecondary),
        const SizedBox(width: 4),
        Text(type.label,
            style: CliinAppTextStyles.bodySmall
                .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Boutons d'action ────────────────────────────────────────────
  Widget _buildActionButtons(GroupModel group, bool isAdmin, bool isFollowing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingL,
        CliinAppConstants.pagePadding,
        CliinAppConstants.spacingM,
      ),
      child: Row(children: [
        Expanded(child: _buildFollowButton(group, isFollowing)),
        if (isAdmin) ...[
          const SizedBox(width: CliinAppConstants.spacingM),
          _buildSettingsButton(group),
        ],
      ]),
    );
  }

  Widget _buildFollowButton(GroupModel group, bool isFollowing) {
    return GestureDetector(
      onTap: () => _toggleFollow(group),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isFollowing
              ? CliinAppColors.primaryLight
              : CliinAppColors.primary,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(
            color: isFollowing ? CliinAppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            isFollowing
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            color: isFollowing ? CliinAppColors.primary : CliinAppColors.textWhite,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isFollowing ? 'Suivi' : 'Suivre',
            style: CliinAppTextStyles.button.copyWith(
              color:
                  isFollowing ? CliinAppColors.primary : CliinAppColors.textWhite,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSettingsButton(GroupModel group) {
    return GestureDetector(
      onTap: () => _openSettings(group),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
            color: CliinAppColors.background, shape: BoxShape.circle),
        child: const Icon(Icons.settings_outlined,
            color: CliinAppColors.textDark, size: 22),
      ),
    );
  }

  // ── Onglets ─────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: CliinAppConstants.pagePadding),
      child: Row(
        children: [
          for (var i = 0; i < _tabLabels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: CliinAppConstants.spacingL),
              child: _buildTabItem(_tabLabels[i], i),
            ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
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
          style: CliinAppTextStyles.headingSmall.copyWith(
            fontSize: 13,
            color: selected ? CliinAppColors.primary : CliinAppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
