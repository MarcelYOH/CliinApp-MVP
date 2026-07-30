// lib/shared/widgets/action_card.dart
// Carte réutilisée sur la page principale du module Actions Terrain ET
// dans l'onglet Activités du profil groupe — ne jamais coder de variante
// séparément.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/actions/models/action_model.dart';
import 'action_type_chip.dart';
import 'report_card.dart' show buildReportImage, DynamicDistanceLabel;

const List<String> _actionShortMonths = [
  'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
  'juil', 'août', 'sep', 'oct', 'nov', 'déc',
];

// Publiques — réutilisées par action_detail_page.dart (bloc "Infos clés").
String formatActionDate(DateTime date) =>
    '${date.day} ${_actionShortMonths[date.month - 1]} ${date.year}';

String formatActionHeure(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class ActionCard extends StatelessWidget {
  final ActionModel data;
  final VoidCallback? onTap;
  final double? width;

  const ActionCard({
    super.key,
    required this.data,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusMedium + 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── BLOC 1 : photo + infos ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  height: 200,
                  child: _ActionCardPhoto(data: data),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(CliinAppConstants.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ActionTypeChip(type: data.type),
                        if (data.description != null &&
                            data.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: CliinAppConstants.spacingXS),
                          Text(
                            data.description!.trim(),
                            style: CliinAppTextStyles.bodySmall
                                .copyWith(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: CliinAppConstants.spacingS),
                        _buildDateHeureRow(),
                        const SizedBox(height: CliinAppConstants.spacingXS),
                        _buildLieuRow(),
                        const SizedBox(height: CliinAppConstants.spacingXS),
                        _buildOrganisateurRow(),
                        const SizedBox(height: CliinAppConstants.spacingM),
                        _buildParticipantsDistanceRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
                height: 1, thickness: 1, color: CliinAppColors.divider),
            // ── BLOC 2 : engagement + statut ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CliinAppConstants.pagePadding,
                vertical: CliinAppConstants.spacingS + 2,
              ),
              child: _buildEngagementRow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeureRow() {
    return Row(
      children: [
        const Icon(Icons.calendar_today_rounded,
            size: 13, color: CliinAppColors.textSecondary),
        const SizedBox(width: 4),
        Text(formatActionDate(data.date),
            style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12)),
        Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 10,
            color: CliinAppColors.divider),
        const Icon(Icons.access_time_rounded,
            size: 13, color: CliinAppColors.textSecondary),
        const SizedBox(width: 4),
        Text(formatActionHeure(data.date),
            style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildLieuRow() {
    return Row(
      children: [
        const Icon(Icons.location_on_rounded,
            size: 13, color: CliinAppColors.primary),
        const SizedBox(width: 3),
        Expanded(
          child: Text(data.lieu,
              style: CliinAppTextStyles.bodySmall.copyWith(
                  color: CliinAppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildOrganisateurRow() {
    final organisateur = data.isAnonyme ? 'Anonyme' : data.organisateurNom;
    return Row(
      children: [
        const Icon(Icons.people_alt_rounded,
            size: 13, color: CliinAppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text('Par $organisateur',
              style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildParticipantsDistanceRow() {
    return Row(
      children: [
        const Icon(Icons.people_alt_rounded,
            size: 15, color: CliinAppColors.primary),
        const SizedBox(width: 4),
        Text('${data.participantsCount}',
            style: CliinAppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CliinAppColors.primary)),
        const Spacer(),
        Icon(Icons.near_me_rounded,
            size: 12, color: CliinAppColors.textSecondary.withValues(alpha: 0.8)),
        const SizedBox(width: 3),
        DynamicDistanceLabel(
          latitude: data.latitude,
          longitude: data.longitude,
          style: CliinAppTextStyles.bodySmall.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEngagementRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EngagementStat(icon: Icons.remove_red_eye_outlined, value: data.viewsCount),
            const SizedBox(width: CliinAppConstants.spacingL),
            _EngagementStat(
                icon: Icons.chat_bubble_outline_rounded, value: data.commentsCount),
            const SizedBox(width: CliinAppConstants.spacingL),
            _EngagementStat(icon: Icons.share, value: data.sharesCount),
          ],
        ),
        _StatusBadge(statut: data.statut),
      ],
    );
  }
}

class _ActionCardPhoto extends StatelessWidget {
  final ActionModel data;
  const _ActionCardPhoto({required this.data});

  @override
  Widget build(BuildContext context) {
    return data.photoPath != null
        ? buildReportImage(
            data.photoPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.type.color, data.type.color.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Icon(data.type.icon,
            color: CliinAppColors.textWhite.withValues(alpha: 0.85), size: 30),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ActionStatus statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statut.bgColor,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Text(statut.label,
            style: CliinAppTextStyles.badge
                .copyWith(color: statut.color, fontWeight: FontWeight.w700)),
      );
}

class _EngagementStat extends StatelessWidget {
  final IconData icon;
  final int value;
  const _EngagementStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: CliinAppColors.textSecondary),
          const SizedBox(width: 4),
          Text('$value',
              style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CliinAppColors.textSecondary)),
        ],
      );
}
