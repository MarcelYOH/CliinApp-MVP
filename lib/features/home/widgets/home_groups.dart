// lib/features/home/widgets/home_groups.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/group_model.dart';

class HomeGroups extends StatelessWidget {
  final List<GroupModel> groups;
  final VoidCallback? onVoirTout;
  final void Function(GroupModel)? onCardTap;

  const HomeGroups({
    super.key,
    required this.groups,
    this.onVoirTout,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.62;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Groupes actifs',
                  style: CliinAppTextStyles.headingMedium
                      .copyWith(color: const Color(0xFF1A1A1A))),
              GestureDetector(
                onTap: onVoirTout,
                child: Row(children: [
                  Text('Voir tout',
                      style: CliinAppTextStyles.link.copyWith(fontSize: 13)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right,
                      color: CliinAppColors.primary, size: 18),
                ]),
              ),
            ],
          ),
        ),

        const SizedBox(height: CliinAppConstants.spacingM),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: CliinAppConstants.pagePadding),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(groups.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < groups.length - 1
                        ? CliinAppConstants.spacingM
                        : 0,
                  ),
                  child: _GroupCard(
                    data: groups[index],
                    width: cardWidth,
                    onTap: () => onCardTap?.call(groups[index]),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carte groupe ──────────────────────────────────────────────────────────────
class _GroupCard extends StatefulWidget {
  final GroupModel data;
  final double width;
  final VoidCallback? onTap;

  const _GroupCard({
    required this.data,
    required this.width,
    this.onTap,
  });

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _isFollowing = false;

  static const Color _kGreen      = CliinAppColors.primary;
  static const Color _kGreenDark  = Color(0xFF1A6B2F);
  static const Color _kGreenLight = CliinAppColors.primaryLight;

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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerSection(),
            _buildInfoSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Bannière ──────────────────────────────────────────────────
  Widget _buildBannerSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(CliinAppConstants.radiusLarge),
        topRight: Radius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Stack(children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: Image.asset(
            widget.data.bannerAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, color: Colors.grey, size: 36),
            ),
          ),
        ),
        Positioned(
            bottom: 10, left: 12, child: _buildLogoCercle()),
        Positioned(
            top: 10, right: 10, child: _buildActifBadge()),
      ]),
    );
  }

  Widget _buildLogoCercle() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _kGreenDark,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: widget.data.hasLeafIcon
            ? const Icon(Icons.eco_rounded, color: Colors.white, size: 26)
            : Text(
                widget.data.logoText ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildActifBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kGreenLight,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusLarge),
      ),
      child: Text('Actif',
          style: CliinAppTextStyles.badge.copyWith(
              color: _kGreen, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  // ── Infos ─────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CliinAppConstants.spacingL,
        CliinAppConstants.spacingM,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ]),
          const SizedBox(height: CliinAppConstants.spacingS),
          _infoRow(Icons.group_rounded,
              '${widget.data.membersCount} membres'),
          const SizedBox(height: CliinAppConstants.spacingXS),
          _infoRow(Icons.shield_rounded,
              '${widget.data.actionsCount} actions'),
          const SizedBox(height: CliinAppConstants.spacingXS),
          _infoRow(Icons.location_on_rounded, widget.data.location,
              grey: true),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool grey = false}) {
    return Row(children: [
      Icon(icon, color: grey ? Colors.grey : _kGreen, size: 15),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: CliinAppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: grey
                  ? CliinAppColors.textSecondary
                  : const Color(0xFF1A1A1A),
            ),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  // ── Footer : avatars + bouton Suivre/Suivi ────────────────────
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
          _buildAvatars(),
          // ✅ Bouton Suivre / Suivi
          GestureDetector(
            onTap: _toggleFollow,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _isFollowing ? _kGreenLight : _kGreen,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusLarge),
                border: Border.all(
                  color: _isFollowing ? _kGreen : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isFollowing) ...[
                    const Icon(Icons.check_rounded,
                        color: _kGreen, size: 13),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _isFollowing ? 'Suivi' : 'Suivre',
                    style: CliinAppTextStyles.badge.copyWith(
                      color: _isFollowing ? _kGreen : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatars() {
    return SizedBox(
      width: 80,
      height: 30,
      child: Stack(
        children: List.generate(4, (i) {
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/profile.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: _kGreenDark.withValues(alpha: 0.7 - i * 0.1),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}