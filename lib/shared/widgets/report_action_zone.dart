// lib/shared/widgets/report_action_zone.dart
//
// Widget partagé entre ReportCard et ReportDetailPage.
// Gère les trois états (disponible / en cours / traité) avec leur propre
// logique UI (suivi, confirmation, contestation).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/home/models/home_report_model.dart';
import 'package:cliinapp/features/auth/auth_guard.dart';

const double _kBtnHeight = 48.0;
const double _kSpacing = 8.0;

// ─────────────────────────────────────────────────────────────────
// Avatar intervenant — widget public réutilisable
// ─────────────────────────────────────────────────────────────────
class ReportIntervenantAvatar extends StatelessWidget {
  final IntervenantModel intervenant;
  final double size;
  const ReportIntervenantAvatar({
    super.key,
    required this.intervenant,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CliinAppColors.primaryLight,
          border: Border.all(color: CliinAppColors.primary, width: 1.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: intervenant.logoAsset != null
            ? Image.asset(intervenant.logoAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback())
            : _fallback(),
      );

  Widget _fallback() => Center(
        child: Text(
          intervenant.name.isNotEmpty
              ? intervenant.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: CliinAppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// Zone d'action principale — partagée carte / page détail
// compact = true  → carte  (icône cloche seule, bandeau info, texte notif)
// compact = false → détail (bouton Suivre avec texte, pas de bandeau)
// ─────────────────────────────────────────────────────────────────
class ReportActionZone extends StatefulWidget {
  final HomeReportModel data;
  final bool compact;
  final VoidCallback? onTakeCharge;
  final VoidCallback? onContact;
  final VoidCallback? onIntervenantTap;

  const ReportActionZone({
    super.key,
    required this.data,
    this.compact = true,
    this.onTakeCharge,
    this.onContact,
    this.onIntervenantTap,
  });

  @override
  State<ReportActionZone> createState() => _ReportActionZoneState();
}

class _ReportActionZoneState extends State<ReportActionZone> {
  bool _isFollowing = false;
  int _confirmCount = 12;
  bool _isConfirmed = false;
  bool _showConfirmPrompt = false;
  bool _showPersistPrompt = false;
  bool _isContested = false;

  @override
  Widget build(BuildContext context) {
    switch (widget.data.status) {
      case ReportStatus.disponible:
        return _buildDisponible();
      case ReportStatus.enCours:
        return _buildEnCours();
      case ReportStatus.traite:
        return _buildTraite();
    }
  }

  // ── DISPONIBLE ────────────────────────────────────────────────
  Widget _buildDisponible() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _kBtnHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onTakeCharge,
                  icon: const Icon(Icons.volunteer_activism_rounded,
                      color: CliinAppColors.textWhite, size: 20),
                  label: Text('Prendre en charge',
                      style: CliinAppTextStyles.button
                          .copyWith(color: CliinAppColors.textWhite)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CliinAppColors.primary,
                    disabledBackgroundColor: CliinAppColors.primary,
                    disabledForegroundColor: CliinAppColors.textWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            CliinAppConstants.radiusMedium)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: _kSpacing),
              _followButton(),
            ],
          ),
        ),
        if (widget.compact) ...[
          const SizedBox(height: _kSpacing),
          _infoBanner(),
        ],
      ],
    );
  }

  Widget _followButton() {
    final active = _isFollowing;
    if (widget.compact) {
      return GestureDetector(
        onTap: () async {
          if (await requireAuth(context)) {
            setState(() => _isFollowing = !_isFollowing);
          }
        },
        child: Container(
          width: _kBtnHeight,
          height: _kBtnHeight,
          decoration: BoxDecoration(
            color: active
                ? CliinAppColors.primaryLight
                : CliinAppColors.cardWhite,
            border: Border.all(
              color: active ? CliinAppColors.primary : CliinAppColors.divider,
              width: active ? 1.5 : 1.0,
            ),
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusMedium),
          ),
          child: Icon(
            active
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: active
                ? CliinAppColors.primary
                : CliinAppColors.textSecondary,
            size: 22,
          ),
        ),
      );
    }
    // Détail : bouton outlined avec texte
    return OutlinedButton.icon(
      onPressed: () async {
        if (await requireAuth(context)) {
          setState(() => _isFollowing = !_isFollowing);
        }
      },
      icon: Icon(
        active
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        size: 18,
        color:
            active ? CliinAppColors.primary : CliinAppColors.textSecondary,
      ),
      label: Text(
        'Suivre',
        style: CliinAppTextStyles.button.copyWith(
            color: active
                ? CliinAppColors.primary
                : CliinAppColors.textSecondary),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color:
                active ? CliinAppColors.primary : CliinAppColors.divider),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusMedium)),
      ),
    );
  }

  // ── EN COURS ──────────────────────────────────────────────────
  Widget _buildEnCours() {
    final intervenant = widget.data.intervenant;
    if (intervenant == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intervenantBlock(intervenant),
        if (widget.compact) ...[
          const SizedBox(height: _kSpacing),
          _infoBanner(),
          if (_isFollowing) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                '🔔 Vous serez notifié dès que ce cas sera traité',
                style: CliinAppTextStyles.bodySmall.copyWith(
                    color: CliinAppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _intervenantBlock(IntervenantModel intervenant) {
    final active = _isFollowing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius:
            BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(
            color: CliinAppColors.alertOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportIntervenantAvatar(intervenant: intervenant, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pris en charge par',
                    style: CliinAppTextStyles.bodySmall.copyWith(
                        color: CliinAppColors.textSecondary, fontSize: 10),
                    maxLines: 1),
                GestureDetector(
                  onTap: widget.onIntervenantTap,
                  child: Text(
                      intervenant.groupName ?? intervenant.name,
                      style: CliinAppTextStyles.headingSmall.copyWith(
                        color: CliinAppColors.primary,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: CliinAppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (intervenant.takenAgo != null)
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 10, color: CliinAppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text(intervenant.takenAgo!,
                        style: CliinAppTextStyles.bodySmall.copyWith(
                            color: CliinAppColors.textSecondary,
                            fontSize: 10),
                        maxLines: 1),
                  ]),
                // Contacter — conditionnel : visible UNIQUEMENT si isContactable
                if (intervenant.isContactable &&
                    widget.onContact != null) ...[
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: widget.onContact,
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 13, color: CliinAppColors.alertOrange),
                    label: Text('Contacter',
                        style: CliinAppTextStyles.badge.copyWith(
                            color: CliinAppColors.alertOrange,
                            fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      side: const BorderSide(
                          color: CliinAppColors.alertOrange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              CliinAppConstants.radiusMedium)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Bell — coin supérieur droit, indépendant du bouton Contacter
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              if (await requireAuth(context)) {
                setState(() => _isFollowing = !_isFollowing);
              }
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: active
                    ? CliinAppColors.primaryLight
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                active
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 20,
                color: active
                    ? CliinAppColors.primary
                    : CliinAppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TRAITÉ ────────────────────────────────────────────────────
  Widget _buildTraite() {
    final intervenant = widget.data.intervenant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResolutionBlock(
            data: widget.data, onIntervenantTap: widget.onIntervenantTap),
        const SizedBox(height: _kSpacing),
        // Compteur confirmations
        Center(
          child: Text(
            '👍 $_confirmCount personne${_confirmCount > 1 ? 's' : ''}'
            ' confirm${_confirmCount > 1 ? 'ent' : 'e'} que c\'est résolu',
            style: CliinAppTextStyles.bodySmall
                .copyWith(fontSize: 12, color: CliinAppColors.textDark),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: _kSpacing),
        // Bouton confirmer ou état post-confirmation
        if (_isConfirmed)
          Center(
            child: Text(
              'Merci ! $_confirmCount confirmations au total',
              style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          )
        else if (_showConfirmPrompt)
          _inlineDialog(
            question:
                'Confirmer que ce problème est bien résolu sur place ?',
            yesLabel: 'Oui, confirmer',
            onYes: () => setState(() {
              _confirmCount++;
              _isConfirmed = true;
              _showConfirmPrompt = false;
            }),
            onCancel: () =>
                setState(() => _showConfirmPrompt = false),
          )
        else
          SizedBox(
            height: _kBtnHeight,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (await requireAuth(context)) {
                  setState(() => _showConfirmPrompt = true);
                }
              },
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: CliinAppColors.textWhite, size: 20),
              label: Text('Confirmer la résolution',
                  style: CliinAppTextStyles.button
                      .copyWith(color: CliinAppColors.textWhite)),
              style: ElevatedButton.styleFrom(
                backgroundColor: CliinAppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        CliinAppConstants.radiusMedium)),
                elevation: 0,
              ),
            ),
          ),
        // Lien "persiste" ou message contesté
        if (_isContested) ...[
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CliinAppColors.alertOrange.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusMedium),
            ),
            child: Text(
              'Cas remis en cours — ${intervenant?.name ?? 'l\'intervenant'}'
              ' a été notifié et doit fournir une nouvelle preuve',
              style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: CliinAppColors.alertOrange,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ] else if (_showPersistPrompt) ...[
          const SizedBox(height: 6),
          _inlineDialog(
            question:
                'Le cas sera remis En cours et l\'intervenant sera notifié pour re-traiter.',
            yesLabel: 'Oui, ça persiste',
            onYes: () => setState(() {
              _isContested = true;
              _showPersistPrompt = false;
            }),
            onCancel: () =>
                setState(() => _showPersistPrompt = false),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              onTap: () async {
                if (await requireAuth(context)) {
                  setState(() => _showPersistPrompt = true);
                }
              },
              child: Text(
                'Le problème persiste encore ?',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: CliinAppColors.textSecondary,
                    decoration: TextDecoration.underline,
                    decorationColor: CliinAppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _inlineDialog({
    required String question,
    required String yesLabel,
    required VoidCallback onYes,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CliinAppColors.background,
        borderRadius:
            BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(question,
              style: CliinAppTextStyles.bodySmall.copyWith(
                  fontSize: 11, color: CliinAppColors.textDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CliinAppColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: Text('Annuler',
                    style: CliinAppTextStyles.badge
                        .copyWith(color: CliinAppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: onYes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CliinAppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CliinAppConstants.radiusMedium)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                ),
                child: Text(yesLabel,
                    style: CliinAppTextStyles.badge
                        .copyWith(color: CliinAppColors.textWhite)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Bandeau info (carte seulement) ────────────────────────────
  Widget _infoBanner() {
    return SizedBox(
      height: _kBtnHeight,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.data.status.bannerBgColor,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: widget.data.status.bannerIconColor,
                    shape: BoxShape.circle),
                child: Icon(widget.data.status.bannerIcon,
                    color: CliinAppColors.textWhite, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.data.status == ReportStatus.disponible
                      ? 'Cas disponible, tout utilisateur peut le prendre en charge.'
                      : 'Ce cas est déjà pris en charge. Merci pour votre engagement !',
                  style: CliinAppTextStyles.bodySmall.copyWith(
                      color: CliinAppColors.textDark,
                      fontSize: 11,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bloc résolution (état Traité)
// ─────────────────────────────────────────────────────────────────
class _ResolutionBlock extends StatelessWidget {
  final HomeReportModel data;
  final VoidCallback? onIntervenantTap;
  const _ResolutionBlock({required this.data, this.onIntervenantTap});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final intervenant = data.intervenant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CliinAppColors.primaryLight,
        borderRadius:
            BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              color: CliinAppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              color: CliinAppColors.textWhite, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                intervenant != null
                    ? 'Ce problème a été résolu par'
                    : 'Ce problème a été résolu.',
                style: CliinAppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CliinAppColors.textDark,
                    fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (intervenant != null)
                GestureDetector(
                  onTap: onIntervenantTap,
                  child: Text(intervenant.name,
                      style: CliinAppTextStyles.bodySmall.copyWith(
                        color: CliinAppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: CliinAppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 10, color: CliinAppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  intervenant?.treatedAt != null
                      ? _formatDate(intervenant!.treatedAt!)
                      : 'Date de traitement non renseignée',
                  style: CliinAppTextStyles.bodySmall.copyWith(
                      color: CliinAppColors.textSecondary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
