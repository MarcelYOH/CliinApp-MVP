// lib/shared/widgets/group_card.dart
//
// Carte groupe partagée — utilisée PARTOUT où une carte groupe apparaît
// (accueil, page principale du module Groupes, recherche). Ne jamais coder
// une variante séparément : réutiliser ce widget. Largeur fixe (260px),
// toute la carte navigue vers GroupProfilePage sauf le bouton Suivre.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/auth/auth_guard.dart';
import '../../features/groups/models/group_model.dart';
import '../../features/groups/pages/group_profile_page.dart';
import '../navigation/fast_page_route.dart';
import '../store/auth_store.dart';
import '../store/group_store.dart';
import 'group_badge_chip.dart';

class GroupCard extends StatefulWidget {
  final GroupModel data;

  const GroupCard({super.key, required this.data});

  static const double cardWidth = 260;

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  static const double _coverHeight = 70;
  static const double _avatarSize = 40;

  Future<void> _toggleFollow() async {
    if (!await requireAuth(context)) return;
    if (!mounted) return;
    final userId = AuthStore.instance.currentUser!.id;
    final isFollowing = GroupStore.instance.isFollowing(widget.data.id, userId);
    setState(() {
      if (isFollowing) {
        GroupStore.instance.unfollowGroup(widget.data.id, userId);
      } else {
        GroupStore.instance.followGroup(widget.data.id, userId);
      }
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      fastFadeRoute<void>(GroupProfilePage(groupId: widget.data.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        onTap: _openProfile,
        child: Container(
          width: GroupCard.cardWidth,
          decoration: BoxDecoration(
            color: CliinAppColors.cardWhite,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
            border: Border.all(color: CliinAppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCover(),
                  _buildInfoSection(),
                  _buildFooter(),
                ],
              ),
              Positioned(
                top: _coverHeight - _avatarSize / 2,
                left: 12,
                child: _buildAvatarCircle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Photo de couverture — toujours le dégradé de repli : le modèle ne
  // porte qu'une seule image (photoPath), utilisée pour l'avatar rond ─────
  Widget _buildCover() {
    return SizedBox(
      height: _coverHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CliinAppColors.primary, CliinAppColors.primaryDark],
                ),
              ),
              child: Center(
                child: Icon(Icons.groups_rounded,
                    color: CliinAppColors.textWhite.withValues(alpha: 0.25),
                    size: 34),
              ),
            ),
          ),
          if (widget.data.estActif)
            Positioned(top: 8, right: 10, child: _buildActifBadge()),
        ]),
      ),
    );
  }

  Widget _buildActifBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CliinAppColors.primary,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Text('Actif',
          style: CliinAppTextStyles.badge.copyWith(
              color: CliinAppColors.textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 11)),
    );
  }

  // ── Avatar rond du groupe ────────────────────────────────────────
  Widget _buildAvatarCircle() {
    final photoPath = widget.data.photoPath;
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        color: CliinAppColors.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(color: CliinAppColors.cardWhite, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: photoPath != null
          ? ClipOval(
              child: Image.asset(
                photoPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildAvatarFallback(),
              ),
            )
          : _buildAvatarFallback(),
    );
  }

  Widget _buildAvatarFallback() {
    final initials = widget.data.nom.trim().isEmpty
        ? '?'
        : widget.data.nom.trim().substring(0, 1).toUpperCase();
    return Center(
      child: Text(
        initials,
        style: CliinAppTextStyles.badge.copyWith(
          color: CliinAppColors.textWhite,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Infos ─────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    final orderedBadges =
        kGroupBadgeOrder.where(widget.data.badges.contains).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.spacingL,
        26,
        CliinAppConstants.spacingS,
        CliinAppConstants.spacingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(widget.data.nom,
                  style: CliinAppTextStyles.headingSmall.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: CliinAppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right,
                color: CliinAppColors.textSecondary, size: 18),
          ]),
          if (orderedBadges.isNotEmpty) ...[
            const SizedBox(height: CliinAppConstants.spacingXS),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  orderedBadges.map((b) => GroupBadgeChip(badge: b)).toList(),
            ),
          ],
          const SizedBox(height: CliinAppConstants.spacingS),
          _infoRow(Icons.group_rounded,
              '${widget.data.sympathisantsCount} sympathisants'),
          const SizedBox(height: CliinAppConstants.spacingXS),
          _infoRow(
              Icons.shield_rounded, '${widget.data.actionsCount} actions'),
          const SizedBox(height: CliinAppConstants.spacingXS),
          _infoRow(Icons.location_on_rounded, widget.data.zone, grey: true),
          const SizedBox(height: CliinAppConstants.spacingXS),
          Text(_truncateDescription(widget.data.description),
              style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 12, color: CliinAppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _truncateDescription(String text) {
    if (text.length <= 60) return text;
    return '${text.substring(0, 60).trimRight()}...';
  }

  Widget _infoRow(IconData icon, String text, {bool grey = false}) {
    return Row(children: [
      Icon(icon,
          color: grey ? CliinAppColors.textSecondary : CliinAppColors.primary,
          size: 15),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: CliinAppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: grey
                  ? CliinAppColors.textSecondary
                  : CliinAppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  // ── Footer : avatars équipe dirigeante + bouton Suivre/Suivi ────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.spacingL,
        CliinAppConstants.spacingXS,
        CliinAppConstants.spacingL,
        CliinAppConstants.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLeaderAvatars(),
          _buildFollowButton(),
        ],
      ),
    );
  }

  Widget _buildLeaderAvatars() {
    final leaders = GroupStore.instance.leaderAvatars(widget.data.id);
    if (leaders.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 18.0 * (leaders.length - 1) + 30,
      height: 30,
      child: Stack(
        children: List.generate(leaders.length, (i) {
          final leader = leaders[i];
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CliinAppColors.cardWhite, width: 2),
              ),
              child: ClipOval(
                child: leader.avatarPath != null
                    ? Image.asset(
                        leader.avatarPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _leaderFallback(i),
                      )
                    : _leaderFallback(i),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _leaderFallback(int i) {
    return Container(
      color: CliinAppColors.primaryDark.withValues(alpha: 0.7 - i * 0.1),
      child: const Icon(Icons.person, color: CliinAppColors.textWhite, size: 14),
    );
  }

  Widget _buildFollowButton() {
    final userId = AuthStore.instance.currentUser?.id;
    final isFollowing = userId != null &&
        GroupStore.instance.isFollowing(widget.data.id, userId);
    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing
              ? CliinAppColors.primaryLight
              : CliinAppColors.primary,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(
            color: isFollowing ? CliinAppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowing
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: isFollowing
                  ? CliinAppColors.primary
                  : CliinAppColors.textWhite,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              isFollowing ? 'Suivi' : 'Suivre',
              style: CliinAppTextStyles.badge.copyWith(
                color: isFollowing
                    ? CliinAppColors.primary
                    : CliinAppColors.textWhite,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
