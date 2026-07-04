// lib/features/reports/models/report_model.dart
// Modèle principal de signalement — CliinApp

import 'package:flutter/material.dart';

export '../../../shared/models/report_category.dart' show ReportCategory;
export '../../../shared/models/report_origin.dart' show ReportOrigin, ReportOriginExt;
import '../../../shared/models/report_category.dart' show ReportCategory;
import '../../../shared/models/report_origin.dart' show ReportOrigin;

// ─────────────────────────────────────────
// Enum — Niveau d'urgence
// ─────────────────────────────────────────
enum ReportSeverity { faible, moyen, eleve, critique }

extension ReportSeverityExtension on ReportSeverity {
  String get label {
    switch (this) {
      case ReportSeverity.faible:   return 'Faible';
      case ReportSeverity.moyen:    return 'Moyen';
      case ReportSeverity.eleve:    return 'Élevé';
      case ReportSeverity.critique: return 'Critique';
    }
  }

  Color get color {
    switch (this) {
      case ReportSeverity.faible:   return const Color(0xFF2DB84B);
      case ReportSeverity.moyen:    return const Color(0xFFFF9800);
      case ReportSeverity.eleve:    return const Color(0xFFFF5722);
      case ReportSeverity.critique: return const Color(0xFFE53935);
    }
  }

  Color get bgColor {
    switch (this) {
      case ReportSeverity.faible:   return const Color(0xFFE6F7EB);
      case ReportSeverity.moyen:    return const Color(0xFFFFF3E0);
      case ReportSeverity.eleve:    return const Color(0xFFFBE9E7);
      case ReportSeverity.critique: return const Color(0xFFFFEBEE);
    }
  }

  IconData get icon {
    switch (this) {
      case ReportSeverity.faible:   return Icons.shield_outlined;
      case ReportSeverity.moyen:    return Icons.error_outline;
      case ReportSeverity.eleve:    return Icons.warning_amber_outlined;
      case ReportSeverity.critique: return Icons.notification_important_outlined;
    }
  }
}

// ─────────────────────────────────────────
// Enum — Statut TECHNIQUE du flow d'upload côté client
// Représente l'avancement de la soumission d'un signalement (création uniquement).
// ≠ ReportStatus (shared/models/report_status.dart) qui représente le cycle
//   de vie métier du signalement sur la plateforme.
// ─────────────────────────────────────────
enum ReportWorkflowStatus { enAttente, enCours, traite, rejete }

extension ReportWorkflowStatusExtension on ReportWorkflowStatus {
  String get label {
    switch (this) {
      case ReportWorkflowStatus.enAttente: return 'En attente';
      case ReportWorkflowStatus.enCours:   return 'En cours';
      case ReportWorkflowStatus.traite:    return 'Traité';
      case ReportWorkflowStatus.rejete:    return 'Rejeté';
    }
  }
}

// ─────────────────────────────────────────
// Enum — Étapes du flow d'upload
// ─────────────────────────────────────────
enum ReportUploadStep {
  compressionImage,
  envoiImage,
  enregistrementInfos,
  generationCode,
  finalisation,
}

extension ReportUploadStepExtension on ReportUploadStep {
  String get label {
    switch (this) {
      case ReportUploadStep.compressionImage:    return 'Compression de l\'image';
      case ReportUploadStep.envoiImage:          return 'Envoi de l\'image';
      case ReportUploadStep.enregistrementInfos: return 'Enregistrement des informations';
      case ReportUploadStep.generationCode:      return 'Génération du code unique';
      case ReportUploadStep.finalisation:        return 'Finalisation';
    }
  }

  String get description {
    switch (this) {
      case ReportUploadStep.compressionImage:    return 'Image optimisée avec succès';
      case ReportUploadStep.envoiImage:          return 'Image envoyée sur le serveur';
      case ReportUploadStep.enregistrementInfos: return 'Création du signalement en base de données';
      case ReportUploadStep.generationCode:      return 'Attribution d\'un identifiant unique';
      case ReportUploadStep.finalisation:        return 'Votre signalement sera bientôt en ligne';
    }
  }
}

// ─────────────────────────────────────────
// Enum — Statut d'une étape d'upload
// ─────────────────────────────────────────
enum UploadStepStatus { enAttente, enCours, termine, erreur }

extension UploadStepStatusExtension on UploadStepStatus {
  String get label {
    switch (this) {
      case UploadStepStatus.enAttente: return 'En attente';
      case UploadStepStatus.enCours:   return 'En cours';
      case UploadStepStatus.termine:   return 'Terminé';
      case UploadStepStatus.erreur:    return 'Erreur';
    }
  }
}

// ─────────────────────────────────────────
// Model — Étape d'upload avec statut
// ─────────────────────────────────────────
class ReportUploadStepModel {
  final ReportUploadStep step;
  final UploadStepStatus status;

  const ReportUploadStepModel({
    required this.step,
    required this.status,
  });

  ReportUploadStepModel copyWith({UploadStepStatus? status}) {
    return ReportUploadStepModel(
      step: step,
      status: status ?? this.status,
    );
  }
}

// ─────────────────────────────────────────
// Model — Signalement principal
// ─────────────────────────────────────────
class ReportModel {
  final String? id;
  final String? reportCode;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? imagePath;
  final ReportCategory? category;
  final ReportSeverity? severity;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final int viewsCount;
  final int commentsCount;
  final int sharesCount;
  final String? userId;
  final ReportWorkflowStatus status;
  final ReportOrigin origin;
  final String? signaleParNom;
  final String? signaleParId;
  final String? groupId;
  final bool isAnonyme;

  const ReportModel({
    this.id,
    this.reportCode,
    this.title,
    this.description,
    this.imageUrl,
    this.imagePath,
    this.category,
    this.severity,
    this.address,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.viewsCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.userId,
    this.status = ReportWorkflowStatus.enAttente,
    this.origin = ReportOrigin.espacePublic,
    this.signaleParNom,
    this.signaleParId,
    this.groupId,
    this.isAnonyme = false,
  });

  ReportModel copyWith({
    String? id,
    String? reportCode,
    String? title,
    String? description,
    String? imageUrl,
    String? imagePath,
    ReportCategory? category,
    ReportSeverity? severity,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    int? viewsCount,
    int? commentsCount,
    int? sharesCount,
    String? userId,
    ReportWorkflowStatus? status,
    ReportOrigin? origin,
    String? signaleParNom,
    String? signaleParId,
    String? groupId,
    bool? isAnonyme,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reportCode: reportCode ?? this.reportCode,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      viewsCount: viewsCount ?? this.viewsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      signaleParNom: signaleParNom ?? this.signaleParNom,
      signaleParId: signaleParId ?? this.signaleParId,
      groupId: groupId ?? this.groupId,
      isAnonyme: isAnonyme ?? this.isAnonyme,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reportCode': reportCode,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'category': category?.name,
    'severity': severity?.name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt?.toIso8601String(),
    'viewsCount': viewsCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'userId': userId,
    'status': status.name,
    'origin': origin.name,
    'signaleParNom': signaleParNom,
    'signaleParId': signaleParId,
    'groupId': groupId,
    'isAnonyme': isAnonyme,
  };

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
    id: json['id'],
    reportCode: json['reportCode'],
    title: json['title'],
    description: json['description'],
    imageUrl: json['imageUrl'],
    category: json['category'] != null
        ? ReportCategory.values.firstWhere((e) => e.name == json['category'])
        : null,
    severity: json['severity'] != null
        ? ReportSeverity.values.firstWhere((e) => e.name == json['severity'])
        : null,
    address: json['address'],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    viewsCount: json['viewsCount'] ?? 0,
    commentsCount: json['commentsCount'] ?? 0,
    sharesCount: json['sharesCount'] ?? 0,
    userId: json['userId'],
    status: json['status'] != null
        ? ReportWorkflowStatus.values.firstWhere((e) => e.name == json['status'])
        : ReportWorkflowStatus.enAttente,
    origin: json['origin'] != null
        ? ReportOrigin.values.firstWhere((e) => e.name == json['origin'],
            orElse: () => ReportOrigin.espacePublic)
        : ReportOrigin.espacePublic,
    signaleParNom: json['signaleParNom'],
    signaleParId: json['signaleParId'],
    groupId: json['groupId'],
    isAnonyme: json['isAnonyme'] ?? false,
  );
}