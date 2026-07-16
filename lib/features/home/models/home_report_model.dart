// lib/features/home/models/home_report_model.dart

// ── Réexports — sources de vérité uniques ─────────────────
export 'package:cliinapp/shared/models/report_category.dart';
export 'package:cliinapp/shared/models/report_origin.dart';
export 'package:cliinapp/features/reports/models/report_model.dart'
    show ReportSeverity, ReportSeverityExtension;
export 'package:cliinapp/shared/models/report_status.dart';
export 'package:cliinapp/shared/models/report_history_entry.dart';
export 'package:cliinapp/shared/models/intervenant_model.dart';
export 'package:cliinapp/shared/models/report_comment_model.dart';

import 'package:cliinapp/shared/models/report_category.dart';
import 'package:cliinapp/shared/models/report_origin.dart';
import 'package:cliinapp/features/reports/models/report_model.dart'
    show ReportSeverity;
import 'package:cliinapp/shared/models/report_status.dart';
import 'package:cliinapp/shared/models/report_history_entry.dart';
import 'package:cliinapp/shared/models/intervenant_model.dart';
import 'package:cliinapp/shared/models/report_comment_model.dart';

// Sentinelle pour distinguer "paramètre non fourni" de "paramètre fourni
// à null" dans copyWith() — un simple `IntervenantModel? intervenant`
// avec repli `??` ne permet jamais d'effacer explicitement l'intervenant
// (ex: preuve rejetée -> cas libéré). Voir copyWith() ci-dessous.
class _Unset {
  const _Unset();
}

const _unset = _Unset();

/// Modèle d'AFFICHAGE d'un signalement sur l'accueil et la carte.
///
/// Distinct de [ReportModel] (features/reports/models/report_model.dart) qui est
/// le modèle de CRÉATION utilisé dans le flow de soumission (formulaire → upload).
/// HomeReportModel est produit par le Repository et consommé par les widgets ;
/// il contient des champs pré-formatés pour l'UI (distance, timeAgo, imageAsset)
/// que ReportModel ne connaît pas.
class HomeReportModel {
  final String id;
  final String reference;
  final String title;
  final String location;
  final String description;
  final ReportSeverity severity;
  final ReportCategory category;
  final String imageAsset;
  final String? imageAfterAsset;
  final String distance;
  final double? latitude;
  final double? longitude;
  final String timeAgo;
  final DateTime? createdAt;
  final ReportStatus status;
  final IntervenantModel? intervenant;
  final int views;
  final int comments;
  final int shares;
  final List<ReportComment> commentsList;
  final List<ReportHistoryEntry> history;
  final String? signalePar;
  final String? signaleParId;
  final String? groupId;
  final bool isAnonyme;
  final String? gpsCoords;
  final ReportOrigin origin;
  // Position enregistrée avec une accuracy GPS mauvaise (> 100m) au moment
  // de la publication, sans correction manuelle de l'adresse — permet
  // d'identifier après coup les signalements dont la position est peu
  // fiable (cf. UserLocationService.approximateAccuracyMeters).
  final bool positionApproximative;

  const HomeReportModel({
    required this.id,
    required this.reference,
    required this.title,
    required this.location,
    required this.description,
    required this.severity,
    required this.category,
    required this.imageAsset,
    this.imageAfterAsset,
    required this.distance,
    this.latitude,
    this.longitude,
    required this.timeAgo,
    this.createdAt,
    this.status = ReportStatus.disponible,
    this.intervenant,
    required this.views,
    required this.comments,
    required this.shares,
    this.commentsList = const [],
    this.history = const [],
    this.signalePar,
    this.signaleParId,
    this.groupId,
    this.isAnonyme = false,
    this.gpsCoords,
    this.origin = ReportOrigin.espacePublic,
    this.positionApproximative = false,
  });

  HomeReportModel copyWith({
    String? id,
    String? reference,
    String? title,
    String? location,
    String? description,
    ReportSeverity? severity,
    ReportCategory? category,
    String? imageAsset,
    String? imageAfterAsset,
    String? distance,
    double? latitude,
    double? longitude,
    String? timeAgo,
    DateTime? createdAt,
    ReportStatus? status,
    // Object? + sentinelle : omettre ce paramètre garde l'intervenant
    // actuel ; passer explicitement `intervenant: null` l'efface (cas
    // libéré après rejet de preuve) ; passer un IntervenantModel le
    // remplace normalement.
    Object? intervenant = _unset,
    int? views,
    int? comments,
    int? shares,
    List<ReportComment>? commentsList,
    List<ReportHistoryEntry>? history,
    String? signalePar,
    String? signaleParId,
    String? groupId,
    bool? isAnonyme,
    String? gpsCoords,
    ReportOrigin? origin,
    bool? positionApproximative,
  }) {
    return HomeReportModel(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      title: title ?? this.title,
      location: location ?? this.location,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      imageAsset: imageAsset ?? this.imageAsset,
      imageAfterAsset: imageAfterAsset ?? this.imageAfterAsset,
      distance: distance ?? this.distance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      intervenant: identical(intervenant, _unset)
          ? this.intervenant
          : intervenant as IntervenantModel?,
      views: views ?? this.views,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      commentsList: commentsList ?? this.commentsList,
      history: history ?? this.history,
      signalePar: signalePar ?? this.signalePar,
      signaleParId: signaleParId ?? this.signaleParId,
      groupId: groupId ?? this.groupId,
      isAnonyme: isAnonyme ?? this.isAnonyme,
      gpsCoords: gpsCoords ?? this.gpsCoords,
      origin: origin ?? this.origin,
      positionApproximative: positionApproximative ?? this.positionApproximative,
    );
  }
}