// lib/shared/widgets/group_card.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/home/models/group_model.dart';

// Carte groupe partagée — utilisée partout où une carte groupe apparaît
// (accueil, module Groupes, recherche). Ne jamais coder une variante
// séparément : réutiliser ce widget.
class GroupCard extends StatefulWidget {
  final GroupModel data;
  final double? width;
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.data,
    this.width,
    this.onTap,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _isFollowing = false;

  static const double _coverHeight = 92;
  static const double _avatarSize = 58;

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFollowing
              ? 'Vous suivez maintenant ${widget.data.name}.'
              : 'Vous ne suivez plus ${widget.data.name}.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isFollowing
            ? CliinAppColors.primary
            : CliinAppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: CliinAppColors.cardWhite,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
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

  // ── Photo de couverture ─────────────────────────────────────────
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
            child: Image.asset(
              widget.data.bannerAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildCoverFallback(),
            ),
          ),
          if (widget.data.isActive)
            Positioned(top: 8, right: 10, child: _buildActifBadge()),
        ]),
      ),
    );
  }

  Widget _buildCoverFallback() {
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
            color: CliinAppColors.textWhite.withValues(alpha: 0.25),
            size: 40),
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
    final avatarAsset = widget.data.avatarAsset;
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        color: CliinAppColors.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(color: CliinAppColors.cardWhite, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: avatarAsset != null
          ? ClipOval(
              child: Image.asset(
                avatarAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildAvatarFallback(),
              ),
            )
          : _buildAvatarFallback(),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: widget.data.hasLeafIcon
          ? const Icon(Icons.eco_rounded,
              color: CliinAppColors.textWhite, size: 26)
          : Text(
              widget.data.logoText ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CliinAppTextStyles.badge.copyWith(
                color: CliinAppColors.textWhite,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
    );
  }

  // ── Infos ─────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    final orderedBadges = kGroupLevelOrder
        .where((level) => widget.data.levelBadges.contains(level))
        .toList();
    final description = widget.data.description;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.spacingL,
        40,
        CliinAppConstants.spacingS,
        CliinAppConstants.spacingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(widget.data.name,
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
                  orderedBadges.map((label) => _buildLevelBadge(label)).toList(),
            ),
          ],
          const SizedBox(height: CliinAppConstants.spacingS),
          _infoRow(Icons.group_rounded, '${widget.data.membersCount} membres'),
          const SizedBox(height: CliinAppConstants.spacingXS),
          _infoRow(Icons.shield_rounded, '${widget.data.actionsCount} actions'),
          const SizedBox(height: CliinAppConstants.spacingXS),
          _infoRow(Icons.location_on_rounded, widget.data.location,
              grey: true),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: CliinAppConstants.spacingXS),
            Text(_truncateDescription(description),
                style: CliinAppTextStyles.bodySmall.copyWith(
                    fontSize: 12, color: CliinAppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  String _truncateDescription(String text) {
    if (text.length <= 60) return text;
    return '${text.substring(0, 60).trimRight()}...';
  }

  Color _levelBadgeColor(String level) {
    switch (level) {
      case 'Engagé':
        return CliinAppColors.levelEngage;
      case 'Officiel':
        return CliinAppColors.levelOfficiel;
      case 'Impact':
      default:
        return CliinAppColors.primary;
    }
  }

  Widget _buildLevelBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _levelBadgeColor(label),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Text(label.toUpperCase(),
          style: CliinAppTextStyles.badge.copyWith(
              color: CliinAppColors.textWhite,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3)),
    );
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
    final avatars = widget.data.leaderAvatarAssets.take(4).toList();
    if (avatars.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 18.0 * (avatars.length - 1) + 30,
      height: 30,
      child: Stack(
        children: List.generate(avatars.length, (i) {
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
                child: Image.asset(
                  avatars[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: CliinAppColors.primaryDark
                        .withValues(alpha: 0.7 - i * 0.1),
                    child: const Icon(Icons.person,
                        color: CliinAppColors.textWhite, size: 14),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isFollowing
              ? CliinAppColors.primaryLight
              : CliinAppColors.primary,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          border: Border.all(
            color: _isFollowing ? CliinAppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFollowing
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: _isFollowing
                  ? CliinAppColors.primary
                  : CliinAppColors.textWhite,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              _isFollowing ? 'Suivi' : 'Suivre',
              style: CliinAppTextStyles.badge.copyWith(
                color: _isFollowing
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
