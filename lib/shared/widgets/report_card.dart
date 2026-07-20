// lib/shared/widgets/report_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/utils/clipboard_helper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/user_location_service.dart';
import '../../features/home/models/home_report_model.dart';
import 'report_action_zone.dart';

class ReportCard extends StatelessWidget {
  final HomeReportModel data;
  final VoidCallback? onTap;
  final VoidCallback? onTakeCharge;
  final VoidCallback? onContact;
  final VoidCallback? onIntervenantTap;
  final double? width;

  const ReportCard({
    super.key,
    required this.data,
    this.onTap,
    this.onTakeCharge,
    this.onContact,
    this.onIntervenantTap,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardPhotoSection(data: data),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CliinAppConstants.pagePadding,
                CliinAppConstants.pagePadding,
                CliinAppConstants.pagePadding,
                CliinAppConstants.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeaderSection(data: data),
                  const SizedBox(height: CliinAppConstants.spacingM),
                  ReportActionZone(
                    data: data,
                    compact: true,
                    onTakeCharge: onTakeCharge,
                    onContact: onContact,
                    onIntervenantTap: onIntervenantTap,
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: CliinAppColors.divider),
            _CardFooter(data: data),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Affichage d'image universel — asset / réseau / fichier local
// ─────────────────────────────────────────────────────────────────
Widget buildReportImage(
  String imagePath, {
  required BoxFit fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (imagePath.startsWith('assets/')) {
    return Image.asset(imagePath, fit: fit, errorBuilder: errorBuilder);
  }
  if (imagePath.startsWith('http://') ||
      imagePath.startsWith('https://') ||
      imagePath.startsWith('blob:')) {
    return Image.network(imagePath, fit: fit, errorBuilder: errorBuilder);
  }
  if (!kIsWeb) {
    return Image.file(File(imagePath), fit: fit, errorBuilder: errorBuilder);
  }
  return Image.network(imagePath, fit: fit, errorBuilder: errorBuilder);
}

// ─────────────────────────────────────────────────────────────────
// Heure relative calculée dynamiquement
// ─────────────────────────────────────────────────────────────────
String reportTimeAgoLabel(DateTime? createdAt, String fallback) {
  if (createdAt == null) return fallback;
  final diff = DateTime.now().difference(createdAt);
  if (diff.inSeconds < 60) return 'À l\'instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
  if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
  return _fullDateLabel(createdAt);
}

const List<String> _shortMonths = [
  'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
  'juil', 'août', 'sep', 'oct', 'nov', 'déc',
];

String _fullDateLabel(DateTime date) =>
    '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';

// ─────────────────────────────────────────────────────────────────
// Distance calculée dynamiquement — SOURCE UNIQUE d'affichage de la
// distance dans toute l'app (accueil, carte, détails public/privé).
// N'affiche jamais de valeur inventée : "..." tant que le GPS n'a pas
// résolu de position, jamais un tiret ni une chaîne mock figée.
// ─────────────────────────────────────────────────────────────────
class DynamicDistanceLabel extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final TextStyle? style;
  // true (défaut) : contexte compact (badge/chip) → "Imprécis".
  // false : contexte avec plus de place → "Position imprécise" en entier.
  final bool compact;
  // Texte ajouté après la distance (ex: " de votre position") — masqué
  // quand aucune distance fiable n'est disponible, pour éviter un texte
  // du type "Position imprécise de votre position".
  final String? suffix;

  const DynamicDistanceLabel({
    super.key,
    required this.latitude,
    required this.longitude,
    this.style,
    this.compact = true,
    this.suffix,
  });

  @override
  State<DynamicDistanceLabel> createState() => _DynamicDistanceLabelState();
}

class _DynamicDistanceLabelState extends State<DynamicDistanceLabel> {
  // Stabilité déjà garantie en amont par UserLocationService (position
  // initiale instantanée, flux filtré à 50m, rejet des sauts aberrants) —
  // ce widget affiche simplement la distance calculée à partir du cache.
  DistanceInfo? _info;

  @override
  void initState() {
    super.initState();
    UserLocationService.instance.addListener(_onLocationChanged);
    _resolveDistance();
  }

  @override
  void dispose() {
    UserLocationService.instance.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() => _resolveDistance();

  Future<void> _resolveDistance() async {
    if (widget.latitude == null || widget.longitude == null) return;
    if (UserLocationService.instance.lastKnownPosition == null) {
      await UserLocationService.instance.getCurrentPosition();
    }
    final info = UserLocationService.instance
        .distanceInfoTo(widget.latitude, widget.longitude);
    if (mounted && info != null && info != _info) {
      setState(() => _info = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    String text;
    if (_info == null) {
      text = '...';
    } else if (_info!.confidence == DistanceConfidence.unknown) {
      text = widget.compact ? 'Imprécis' : 'Position imprécise';
    } else {
      text = widget.suffix != null
          ? '${_info!.label}${widget.suffix}'
          : _info!.label!;
    }
    return Text(text,
        style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

// ─────────────────────────────────────────────────────────────────
// Copie du code signalement dans le presse-papiers
// ─────────────────────────────────────────────────────────────────
Future<void> copyReportCode(BuildContext context, String reference) async {
  await copyTextToClipboard(reference);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Copié'),
    duration: Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
  ));
}

// ─────────────────────────────────────────────────────────────────
// SECTION PHOTO
// ─────────────────────────────────────────────────────────────────

void _openPhoto(BuildContext context, String imagePath) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => _PhotoFullScreen(imagePath: imagePath),
  ));
}

class _PhotoFullScreen extends StatelessWidget {
  final String imagePath;
  const _PhotoFullScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(children: [
            Center(
              child: buildReportImage(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white38,
                    size: 64),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _CardPhotoSection extends StatelessWidget {
  final HomeReportModel data;
  const _CardPhotoSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final isTraite = data.status == ReportStatus.traite;
    return SizedBox(
      height: 200,
      child: Stack(fit: StackFit.expand, children: [
        isTraite
            ? _BeforeAfterPhotos(data: data)
            : _SinglePhoto(imageAsset: data.imageAsset),
        if (!isTraite)
          Positioned(
              top: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _SeverityBadge(severity: data.severity)),
        if (isTraite)
          Positioned(
              top: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _TraiteBadge()),
        Positioned(
            top: CliinAppConstants.spacingS,
            right: CliinAppConstants.spacingS,
            child: _IdBadge(reference: data.reference)),
        if (!isTraite)
          Positioned(
              bottom: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _DistanceTimeBadge(data: data)),
        // Zoom sur la photo principale (états non-traité)
        if (!isTraite)
          Positioned(
              bottom: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _ZoomButton(
                  onTap: () => _openPhoto(context, data.imageAsset))),
      ]),
    );
  }
}

class _SinglePhoto extends StatelessWidget {
  final String imageAsset;
  const _SinglePhoto({required this.imageAsset});
  @override
  Widget build(BuildContext context) => buildReportImage(
        imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
            color: CliinAppColors.background,
            child: const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: Color.fromARGB(255, 45, 103, 219), size: 40))),
      );
}

class _BeforeAfterPhotos extends StatelessWidget {
  final HomeReportModel data;
  const _BeforeAfterPhotos({required this.data});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Photo AVANT
      Expanded(
        child: Stack(fit: StackFit.expand, children: [
          buildReportImage(data.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: CliinAppColors.background)),
          Positioned(
              bottom: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _PhotoLabel(label: 'AVANT', dark: true)),
          Positioned(
              top: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _ZoomButton(
                  onTap: () => _openPhoto(context, data.imageAsset))),
        ]),
      ),
      // Séparateur fin 2px (remplace l'ancien rond avec flèche)
      Container(width: 2, color: CliinAppColors.background),
      // Photo APRÈS
      Expanded(
        child: Stack(fit: StackFit.expand, children: [
          data.imageAfterAsset != null
              ? buildReportImage(data.imageAfterAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: CliinAppColors.background))
              : Container(color: CliinAppColors.background),
          Positioned(
              bottom: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _PhotoLabel(label: 'APRÈS', dark: false)),
          Positioned(
              top: CliinAppConstants.spacingS,
              left: CliinAppConstants.spacingS,
              child: _ZoomButton(
                  onTap: data.imageAfterAsset != null
                      ? () => _openPhoto(context, data.imageAfterAsset!)
                      : null)),
        ]),
      ),
    ]);
  }
}

class _PhotoLabel extends StatelessWidget {
  final String label;
  final bool dark;
  const _PhotoLabel({required this.label, required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: dark
              ? Colors.black.withValues(alpha: 0.75)
              : CliinAppColors.primary,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusSmall),
        ),
        child: Text(label,
            style: CliinAppTextStyles.badge.copyWith(
                color: CliinAppColors.textWhite,
                fontWeight: FontWeight.w700)),
      );
}

class _ZoomButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ZoomButton({this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle),
          child: const Icon(Icons.zoom_in_rounded,
              color: CliinAppColors.textWhite, size: 15),
        ),
      );
}

class _SeverityBadge extends StatelessWidget {
  final ReportSeverity severity;
  const _SeverityBadge({required this.severity});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: severity.color,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(severity.icon, color: CliinAppColors.textWhite, size: 13),
          const SizedBox(width: 4),
          Text(severity.label.toUpperCase(),
              style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.textWhite,
                  fontWeight: FontWeight.w800)),
        ]),
      );
}

class _TraiteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: CliinAppColors.alertRed,
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded,
              color: CliinAppColors.textWhite, size: 13),
          const SizedBox(width: 4),
          Text('TRAITÉ',
              style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.textWhite,
                  fontWeight: FontWeight.w800)),
        ]),
      );
}

class _IdBadge extends StatelessWidget {
  final String reference;
  const _IdBadge({required this.reference});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => copyReportCode(context, reference),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius:
                  BorderRadius.circular(CliinAppConstants.radiusSmall)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(reference,
                style: CliinAppTextStyles.badge.copyWith(
                    color: CliinAppColors.textWhite,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 5),
            const Icon(Icons.copy_rounded,
                color: CliinAppColors.textWhite, size: 12),
          ]),
        ),
      );
}

// Cartes factices "accroche" (accueil, id préfixé 'demo_') : distance
// figée et plausible plutôt que calculée en direct — une donnée de
// démonstration ne doit jamais afficher "Imprécis"/"..." selon l'état GPS
// réel de l'appareil qui teste l'app, ce qui donnerait l'impression d'un
// bug plutôt que d'un aperçu engageant.
bool _isFakeReport(HomeReportModel r) => r.id.startsWith('demo_');

class _DistanceTimeBadge extends StatelessWidget {
  final HomeReportModel data;
  const _DistanceTimeBadge({required this.data});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius:
                BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_rounded,
              color: CliinAppColors.textWhite, size: 12),
          const SizedBox(width: 4),
          _isFakeReport(data)
              ? Text(data.distance,
                  style: CliinAppTextStyles.badge
                      .copyWith(color: CliinAppColors.textWhite))
              : DynamicDistanceLabel(
                  latitude: data.latitude,
                  longitude: data.longitude,
                  style: CliinAppTextStyles.badge
                      .copyWith(color: CliinAppColors.textWhite),
                ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1,
              height: 10,
              color: Colors.white38),
          const Icon(Icons.access_time_rounded,
              color: CliinAppColors.textWhite, size: 12),
          const SizedBox(width: 4),
          Text(reportTimeAgoLabel(data.createdAt, data.timeAgo),
              style: CliinAppTextStyles.badge
                  .copyWith(color: CliinAppColors.textWhite)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────

class _CardHeaderSection extends StatelessWidget {
  final HomeReportModel data;
  const _CardHeaderSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final isTraite = data.status == ReportStatus.traite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Text(data.title,
                style: CliinAppTextStyles.headingSmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: CliinAppConstants.spacingS),
          if (isTraite) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: CliinAppConstants.spacingXS),
              decoration: BoxDecoration(
                color: data.severity.bgColor,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
                border:
                    Border.all(color: data.severity.color, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(data.severity.icon,
                    color: data.severity.color, size: 11),
                const SizedBox(width: 3),
                Text(data.severity.label,
                    style: CliinAppTextStyles.badge.copyWith(
                        color: data.severity.color, fontSize: 10)),
              ]),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: CliinAppConstants.spacingXS),
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded,
                    color: CliinAppColors.primary, size: 11),
                const SizedBox(width: 3),
                DynamicDistanceLabel(
                  latitude: data.latitude,
                  longitude: data.longitude,
                  style: CliinAppTextStyles.badge
                      .copyWith(color: CliinAppColors.primary, fontSize: 10),
                ),
              ]),
            ),
          ] else
            _StatusBadge(status: data.status),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_rounded,
              color: CliinAppColors.primary, size: 13),
          const SizedBox(width: 3),
          Expanded(
            child: Text(data.location,
                style: CliinAppTextStyles.bodySmall.copyWith(
                    color: CliinAppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        const SizedBox(height: 4),
        Text(data.description,
            style: CliinAppTextStyles.bodySmall.copyWith(
                color: CliinAppColors.textSecondary,
                fontSize: 12,
                height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: CliinAppConstants.spacingM,
            vertical: CliinAppConstants.spacingXS + 2),
        decoration: BoxDecoration(
          color: status.bgColor,
          borderRadius:
              BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: status.color, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(status.icon, color: status.color, size: 10),
          const SizedBox(width: 4),
          Text(status.label,
              style:
                  CliinAppTextStyles.badge.copyWith(color: status.color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  final HomeReportModel data;
  const _CardFooter({required this.data});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            vertical: CliinAppConstants.spacingM,
            horizontal: CliinAppConstants.pagePadding),
        child: Row(children: [
          _FooterStat(
              icon: Icons.remove_red_eye_outlined,
              value: data.views,
              label: 'Vues'),
          _FooterDivider(),
          _FooterStat(
              icon: Icons.chat_bubble_outline_rounded,
              value: data.comments,
              label:
                  data.comments > 1 ? 'Commentaires' : 'Commentaire'),
          _FooterDivider(),
          _FooterStat(
              icon: Icons.reply_rounded,
              value: data.shares,
              label: 'Partages',
              mirror: true),
        ]),
      );
}

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final bool mirror;
  const _FooterStat(
      {required this.icon,
      required this.value,
      required this.label,
      this.mirror = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Transform(
              alignment: Alignment.center,
              transform: mirror
                  ? (Matrix4.identity()
                    ..scaleByDouble(-1.0, 1.0, 1.0, 1.0))
                  : Matrix4.identity(),
              child:
                  Icon(icon, size: 18, color: CliinAppColors.textDark),
            ),
            const SizedBox(width: 5),
            Text('$value',
                style: CliinAppTextStyles.bodySmall.copyWith(
                    color: CliinAppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 2),
          Text(label,
              style: CliinAppTextStyles.bodySmall
                  .copyWith(color: CliinAppColors.textSecondary)),
        ]),
      );
}

class _FooterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 32, width: 1, color: CliinAppColors.divider);
}
