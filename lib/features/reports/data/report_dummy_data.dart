// lib/features/reports/data/report_dummy_data.dart
// Données factices — Feature Report — CliinApp

import '../models/report_model.dart';

class ReportDummyData {
  ReportDummyData._();

  // ── Signalement publié (ReportSuccessPage) ──
  static final ReportModel publishedReport = ReportModel(
    id: 'report_001',
    reportCode: '#CLN-6589',
    title: 'Dépôt sauvage Cocody',
    description:
        'Accumulation importante de déchets sur la voie publique, devant le mur de clôture. Présence de sacs plastiques et déchets ménagers non collectés depuis plusieurs jours.',
    imageUrl: null,
    imagePath: null,
    category: ReportCategory.depotsSauvages,
    severity: ReportSeverity.moyen,
    address: 'Cocody, Angré 8e tranche',
    latitude: 5.4010,
    longitude: -3.9570,
    createdAt: DateTime(2026, 5, 21, 14, 32),
    viewsCount: 0,
    commentsCount: 0,
    sharesCount: 0,
    userId: 'user_001',
    // ✅ ReportWorkflowStatus — évite le conflit avec shared/report_status.dart
    status: ReportWorkflowStatus.enAttente,
  );

  static const String detectedAddress   = 'Cocody, Angré 8e tranche';
  static const double detectedLatitude  = 5.4010;
  static const double detectedLongitude = -3.9570;

  static final List<ReportUploadStepModel> uploadSteps = [
    const ReportUploadStepModel(
      step: ReportUploadStep.compressionImage,
      status: UploadStepStatus.termine,
    ),
    const ReportUploadStepModel(
      step: ReportUploadStep.envoiImage,
      status: UploadStepStatus.termine,
    ),
    const ReportUploadStepModel(
      step: ReportUploadStep.enregistrementInfos,
      status: UploadStepStatus.enCours,
    ),
    const ReportUploadStepModel(
      step: ReportUploadStep.generationCode,
      status: UploadStepStatus.enAttente,
    ),
    const ReportUploadStepModel(
      step: ReportUploadStep.finalisation,
      status: UploadStepStatus.enAttente,
    ),
  ];

  static const List<String> stepperLabels = [
    'Photo', 'Aperçu', 'Infos', 'Publication', 'Confirmation',
  ];

  static const String cameraTipText =
      'Prenez une photo claire du problème d\'insalubrité que vous souhaitez signaler.';
  static const String cameraHighlightWord  = 'photo claire';
  static const String cameraBottomText =
      'Assurez-vous que le problème est bien visible.';
  static const String cameraBottomHighlight = 'la communauté à agir.';
  static const String previewVerifyTitle    = 'Vérifiez votre photo';
  static const String previewVerifySubtitle =
      'Assurez-vous que le problème est bien visible.';
  static const String previewBottomText =
      'Vos signalements nous aident à garder notre environnement propre.';
  static const String formInfoBannerText =
      'Complétez les informations pour publier votre signalement.';
  static const String formDescriptionHint =
      'Décrivez brièvement le problème...';
  static const int formDescriptionMaxLength = 250;
  static const String formImportantInfoTitle = 'Informations importantes';
  static const String formImportantInfoText =
      'Votre signalement sera visible par toute la communauté.\nNe partagez pas d\'informations personnelles.';
  static const String uploadTitle =
      'Publication du signalement...';
  static const String uploadSubtitle =
      'Merci de patienter, votre signalement est en cours de traitement.';
  static const String uploadMotivationText =
      'Vos signalements nous aident à garder notre environnement propre et sain.';
  static const String uploadDidYouKnowTitle = 'Le saviez-vous ?';
  static const String uploadDidYouKnowText =
      'Plus votre signalement est précis, plus il peut être traité rapidement par les autorités compétentes.';
  static const String successTitle    = 'Merci !';
  static const String successSubtitle =
      'Votre signalement a été publié avec succès.\nIl sera visible par toute la communauté.';
  static const String successMotivationTitle = 'Vos actions comptent !';
  static const String successMotivationText =
      'En signalant, vous contribuez à garder notre environnement propre et sain.';
  static const String successNextActionTitle =
      'Que souhaitez-vous faire maintenant ?';
}