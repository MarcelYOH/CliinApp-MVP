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

class ReportCard extends StatelessWidget {
  final HomeReportModel data;
  final VoidCallback? onTap;
  final VoidCallback? onTakeCharge;
  final VoidCallback? onContact;
  final VoidCallback? onViewDetails;
  final VoidCallback? onIntervenantTap;
  final double? width;

  const ReportCard({
    super.key,
    required this.data,
    this.onTap,
    this.onTakeCharge,
    this.onContact,
    this.onViewDetails,
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
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium + 2),
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
                  _CardActionZone(
                    data: data,
                    onTakeCharge: onTakeCharge,
                    onContact: onContact,
                    onViewDetails: onViewDetails,
                    onIntervenantTap: onIntervenantTap,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: CliinAppColors.divider),
            _CardFooter(data: data),
          ],
        ),
      ),
    );
  }
}

const double _kActionHeight = 72.0;
const double _kBottomHeight = 48.0;
const double _kSpacing = 8.0;

// ─────────────────────────────────────────────────────────────────
// CORRECTION — Affichage d'image universel
// ─────────────────────────────────────────────────────────────────
// Avant : Image.asset(imageAsset) partout, ce qui ne fonctionne que
// pour les images factices embarquées dans le bundle (assets/images/...).
// Une vraie photo prise par l'utilisateur (camera / image_picker) est :
//   - un chemin de fichier local sur mobile,
//   - une URL blob: ou network sur Flutter Web,
// et NE PEUT PAS être chargée avec Image.asset.
// Cette fonction détecte le type de chemin et choisit le bon loader.
Widget buildReportImage(
  String imagePath, {
  required BoxFit fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  // 1) Asset interne du bundle (données factices / démo)
  if (imagePath.startsWith('assets/')) {
    return Image.asset(imagePath, fit: fit, errorBuilder: errorBuilder);
  }

  // 2) URL réseau classique ou blob (Flutter Web : image_picker/camera
  //    renvoient un chemin blob: sur le web, géré comme une URL réseau)
  if (imagePath.startsWith('http://') ||
      imagePath.startsWith('https://') ||
      imagePath.startsWith('blob:')) {
    return Image.network(imagePath, fit: fit, errorBuilder: errorBuilder);
  }

  // 3) Fichier local réel (mobile natif uniquement — dart:io indisponible
  //    en pratique sur le web pour File, donc on protège avec kIsWeb)
  if (!kIsWeb) {
    return Image.file(File(imagePath), fit: fit, errorBuilder: errorBuilder);
  }

  // 4) Filet de sécurité — chemin inattendu sur le web
  return Image.network(imagePath, fit: fit, errorBuilder: errorBuilder);
}

// ─────────────────────────────────────────────────────────────────
// CORRECTION — Heure relative calculée dynamiquement
// ─────────────────────────────────────────────────────────────────
// Avant : data.timeAgo était une chaîne figée pour toujours ("À l'instant").
// Maintenant : si createdAt est disponible, on calcule l'écart avec
// l'heure actuelle à chaque affichage. Sinon, on retombe sur la valeur
// stockée (fallback de sécurité, ne devrait pas arriver en pratique).
String reportTimeAgoLabel(DateTime? createdAt, String fallback) {
  if (createdAt == null) return fallback;

  final diff = DateTime.now().difference(createdAt);

  if (diff.inSeconds < 60) return 'À l\'instant';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'Il y a $m min';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'Il y a ${h}h';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return 'Il y a $d j';
  }
  final weeks = (diff.inDays / 7).floor();
  return 'Il y a $weeks sem';
}

// ─────────────────────────────────────────────────────────────────
// CORRECTION — Distance calculée dynamiquement
// ─────────────────────────────────────────────────────────────────
// Avant : data.distance était une chaîne figée à la création ('< 1 km'),
// ce qui n'a pas de sens — la distance dépend de la position de QUI
// REGARDE la carte au moment de l'affichage, pas de la création.
// Ce widget récupère la position actuelle (via UserLocationService, avec
// cache 30s pour éviter de multiplier les appels GPS) et calcule la vraie
// distance jusqu'au signalement. Tant que la position n'est pas encore
// connue, affiche la valeur de repli (fallback) sans bloquer l'affichage.
class _DynamicDistanceLabel extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String fallback;
  final TextStyle? style;

  const _DynamicDistanceLabel({
    required this.latitude,
    required this.longitude,
    required this.fallback,
    this.style,
  });

  @override
  State<_DynamicDistanceLabel> createState() => _DynamicDistanceLabelState();
}

class _DynamicDistanceLabelState extends State<_DynamicDistanceLabel> {
  String? _label;

  @override
  void initState() {
    super.initState();
    // ✅ CORRECTION — écoute le service : si une position arrive plus tard
    // (récupérée par un autre écran, ex: report_form_page.dart), cette
    // carte se met à jour automatiquement au lieu de rester figée sur son
    // tout premier essai (souvent un échec si le GPS n'a pas encore eu le
    // temps de répondre au moment où la carte s'est affichée).
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
    // Ne déclenche une nouvelle mesure GPS que si aucune position n'est
    // encore connue ; sinon on utilise directement le cache (déjà à jour
    // grâce à la notification reçue via _onLocationChanged).
    if (UserLocationService.instance.lastKnownPosition == null) {
      await UserLocationService.instance.getCurrentPosition();
    }
    final label = UserLocationService.instance
        .distanceLabelTo(widget.latitude, widget.longitude);
    if (mounted && label != null && label != _label) {
      setState(() => _label = label);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Text(_label ?? widget.fallback, style: widget.style);
}

class _CardActionZone extends StatelessWidget {
  final HomeReportModel data;
  final VoidCallback? onTakeCharge;
  final VoidCallback? onContact;
  final VoidCallback? onViewDetails;
  final VoidCallback? onIntervenantTap;

  const _CardActionZone({
    required this.data,
    this.onTakeCharge,
    this.onContact,
    this.onViewDetails,
    this.onIntervenantTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTraite = data.status == ReportStatus.traite;
    final isDisponible = data.status == ReportStatus.disponible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: isDisponible ? _kBottomHeight : _kActionHeight,
          child: _buildAction(),
        ),
        const SizedBox(height: _kSpacing),
        SizedBox(
          height: _kBottomHeight,
          child: isTraite
              ? _ViewDetailsButton(onTap: onViewDetails)
              : _CardInfoBanner(data: data),
        ),
      ],
    );
  }

  Widget _buildAction() {
    switch (data.status) {
      case ReportStatus.disponible:
        return _TakeChargeButton(onTap: onTakeCharge);
      case ReportStatus.enCours:
        return _IntervenantBlock(
            data: data,
            onContact: onContact,
            onIntervenantTap: onIntervenantTap);
      case ReportStatus.traite:
        return _ResolutionBlock(
            data: data, onIntervenantTap: onIntervenantTap);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION PHOTO
// ─────────────────────────────────────────────────────────────────

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
              bottom: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _ZoomButton()),
        ]),
      ),
      Container(
        width: 28,
        color: CliinAppColors.cardWhite,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: CliinAppColors.cardWhite,
              shape: BoxShape.circle,
              border: Border.all(color: CliinAppColors.primary, width: 1.5),
            ),
            child: const Icon(Icons.compare_arrows_rounded,
                color: CliinAppColors.primary, size: 14),
          ),
        ),
      ),
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
              left: CliinAppConstants.spacingS,
              child: _ZoomButton()),
          Positioned(
              bottom: CliinAppConstants.spacingS,
              right: CliinAppConstants.spacingS,
              child: _PhotoLabel(label: 'APRÈS', dark: false)),
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
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall),
        ),
        child: Text(label,
            style: CliinAppTextStyles.badge.copyWith(
                color: CliinAppColors.textWhite, fontWeight: FontWeight.w700)),
      );
}

class _ZoomButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle),
        child: const Icon(Icons.zoom_in_rounded,
            color: CliinAppColors.textWhite, size: 15),
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
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(severity.icon, color: CliinAppColors.textWhite, size: 13),
          const SizedBox(width: 4),
          Text(severity.label.toUpperCase(),
              style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.textWhite, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _TraiteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: CliinAppColors.alertRed,
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded,
              color: CliinAppColors.textWhite, size: 13),
          const SizedBox(width: 4),
          Text('TRAITÉ',
              style: CliinAppTextStyles.badge.copyWith(
                  color: CliinAppColors.textWhite, fontWeight: FontWeight.w800)),
        ]),
      );
}

// ✅ CORRECTION — copie réellement fonctionnelle, sans message d'échec
// ─────────────────────────────────────────────────────────────────
// Avant : Clipboard.setData() seul échouait silencieusement sur Flutter
// Web en contexte HTTP non sécurisé (navigator.clipboard.writeText()
// exige HTTPS), et un dialogue d'erreur apparaissait à la place.
// Maintenant : copyTextToClipboard() (lib/core/utils/clipboard_helper.dart)
// retombe automatiquement sur l'ancienne méthode execCommand('copy'),
// qui fonctionne même en HTTP classique — donc la copie réussit
// réellement, plus besoin d'afficher un message d'échec.
Future<void> copyReportCode(BuildContext context, String reference) async {
  await copyTextToClipboard(reference);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: const Text('Copié'),
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
  ));
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
              borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall)),
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

class _DistanceTimeBadge extends StatelessWidget {
  final HomeReportModel data;
  const _DistanceTimeBadge({required this.data});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(CliinAppConstants.radiusSmall)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_rounded,
              color: CliinAppColors.textWhite, size: 12),
          const SizedBox(width: 4),
          // ✅ CORRECTION — distance calculée dynamiquement (position
          // actuelle de qui regarde ↔ position du signalement), au lieu
          // de la valeur figée à la création.
          _DynamicDistanceLabel(
            latitude: data.latitude,
            longitude: data.longitude,
            fallback: data.distance,
            style: CliinAppTextStyles.badge.copyWith(color: CliinAppColors.textWhite),
          ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1, height: 10,
              color: Colors.white38),
          const Icon(Icons.access_time_rounded,
              color: CliinAppColors.textWhite, size: 12),
          const SizedBox(width: 4),
          // ✅ CORRECTION — heure relative recalculée à chaque affichage
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: CliinAppConstants.spacingS),
          if (isTraite) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: CliinAppConstants.spacingXS),
              decoration: BoxDecoration(
                color: data.severity.bgColor,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
                border: Border.all(color: data.severity.color, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(data.severity.icon, color: data.severity.color, size: 11),
                const SizedBox(width: 3),
                Text(data.severity.label,
                    style: CliinAppTextStyles.badge
                        .copyWith(color: data.severity.color, fontSize: 10)),
              ]),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: CliinAppConstants.spacingXS),
              decoration: BoxDecoration(
                color: CliinAppColors.primaryLight,
                borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded,
                    color: CliinAppColors.primary, size: 11),
                const SizedBox(width: 3),
                // ✅ CORRECTION — distance calculée dynamiquement
                _DynamicDistanceLabel(
                  latitude: data.latitude,
                  longitude: data.longitude,
                  fallback: data.distance,
                  style: CliinAppTextStyles.badge.copyWith(
                      color: CliinAppColors.primary, fontSize: 10),
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
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: status.color, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(status.icon, color: status.color, size: 10),
          const SizedBox(width: 4),
          Text(status.label,
              style: CliinAppTextStyles.badge.copyWith(color: status.color)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────
// BOUTON PRENDRE EN CHARGE
// ─────────────────────────────────────────────────────────────────

class _TakeChargeButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _TakeChargeButton({this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
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
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium)),
            elevation: 0,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// BLOC INTERVENANT — En cours
// ─────────────────────────────────────────────────────────────────

class _IntervenantBlock extends StatelessWidget {
  final HomeReportModel data;
  final VoidCallback? onContact;
  final VoidCallback? onIntervenantTap;
  const _IntervenantBlock(
      {required this.data, this.onContact, this.onIntervenantTap});

  @override
  Widget build(BuildContext context) {
    final intervenant = data.intervenant;
    if (intervenant == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(
            color: CliinAppColors.alertOrange.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        _IntervenantAvatar(intervenant: intervenant, size: 38),
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
                onTap: onIntervenantTap,
                // Carte publique : affiche le groupe si intervention au nom
                // d'un groupe, sinon le nom du user
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
                          color: CliinAppColors.textSecondary, fontSize: 10),
                      maxLines: 1),
                ]),
            ],
          ),
        ),

        // ── ÉCRAN 3 : bouton Contacter conditionnel ──────────────
        // Règle : allowContact = true ET whatsAppNumber != null
        // isContactable encapsule cette logique dans IntervenantModel
        if (intervenant.isContactable && onContact != null) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                size: 13, color: CliinAppColors.alertOrange),
            label: Text('Contacter',
                style: CliinAppTextStyles.badge
                    .copyWith(color: CliinAppColors.alertOrange, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: const BorderSide(color: CliinAppColors.alertOrange),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(CliinAppConstants.radiusMedium)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _IntervenantAvatar extends StatelessWidget {
  final IntervenantModel intervenant;
  final double size;
  const _IntervenantAvatar({required this.intervenant, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CliinAppColors.primaryLight,
          border: Border.all(color: CliinAppColors.primary, width: 1.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: intervenant.logoAsset != null
            ? Image.asset(intervenant.logoAsset!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback())
            : _fallback(),
      );

  Widget _fallback() => Center(
        child: Text(
          intervenant.name.isNotEmpty ? intervenant.name[0].toUpperCase() : '?',
          style: TextStyle(
              color: CliinAppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// BLOC RÉSOLUTION — Traité
// ─────────────────────────────────────────────────────────────────

class _ResolutionBlock extends StatelessWidget {
  final HomeReportModel data;
  final VoidCallback? onIntervenantTap;
  const _ResolutionBlock({required this.data, this.onIntervenantTap});

  String _formatDate(DateTime dt) {
    const months = ['Jan','Fév','Mar','Avr','Mai','Juin',
        'Juil','Août','Sep','Oct','Nov','Déc'];
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
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 32, height: 32,
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
                maxLines: 1, overflow: TextOverflow.ellipsis,
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
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOUTON VOIR LES DÉTAILS
// ─────────────────────────────────────────────────────────────────

class _ViewDetailsButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ViewDetailsButton({this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.remove_red_eye_outlined,
              color: CliinAppColors.primary, size: 16),
          label: Text('Voir les détails',
              style: CliinAppTextStyles.button
                  .copyWith(color: CliinAppColors.primary)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: CliinAppColors.primary),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(CliinAppConstants.radiusMedium)),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// BANDEAU INFO
// ─────────────────────────────────────────────────────────────────

class _CardInfoBanner extends StatelessWidget {
  final HomeReportModel data;
  const _CardInfoBanner({required this.data});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: data.status.bannerBgColor,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
                color: data.status.bannerIconColor, shape: BoxShape.circle),
            child: Icon(data.status.bannerIcon,
                color: CliinAppColors.textWhite, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.status == ReportStatus.disponible
                  ? "Cas disponible, tout utilisateur peut le prendre en charge."
                  : "Ce cas est déjà pris en charge. Merci pour votre engagement !",
              style: CliinAppTextStyles.bodySmall.copyWith(
                  color: CliinAppColors.textDark, fontSize: 11, height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ),
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
              value: data.views, label: 'Vues'),
          _FooterDivider(),
          _FooterStat(
              icon: Icons.chat_bubble_outline_rounded,
              value: data.comments,
              label: data.comments > 1 ? 'Commentaires' : 'Commentaire'),
          _FooterDivider(),
          _FooterStat(
              icon: Icons.reply_rounded,
              value: data.shares, label: 'Partages', mirror: true),
        ]),
      );
}

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final bool mirror;
  const _FooterStat(
      {required this.icon, required this.value,
       required this.label, this.mirror = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Transform(
              alignment: Alignment.center,
              transform: mirror
                  ? (Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0))
                  : Matrix4.identity(),
              child: Icon(icon, size: 18, color: CliinAppColors.textDark),
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