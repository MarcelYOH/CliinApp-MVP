// lib/core/utils/whatsapp_launcher.dart
// Utilitaire centralisé pour ouvrir WhatsApp
// Utilisé depuis report_card, home_page, map_page, reports_bottom_sheet

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/models/intervenant_model.dart';
import '../../shared/store/auth_store.dart';
import '../constants/app_colors.dart';

/// Ouvre WhatsApp avec le numéro de l'intervenant.
/// Affiche un SnackBar si le numéro est absent ou si WhatsApp est indisponible.
Future<void> openWhatsApp({
  required BuildContext context,
  required IntervenantModel? intervenant,
}) async {
  // Un intervenant ne peut pas se contacter lui-même — même principe déjà
  // appliqué au bouton "Suivre" (ReportActionZone._toggleFollow). Ne devrait
  // normalement jamais être atteignable (le bouton Contacter n'apparaît pas
  // dans le tableau de bord privé de l'intervenant), mais ce garde-fou
  // centralisé sécurise TOUS les points d'entrée publics (accueil, carte,
  // détail) par précaution.
  final currentUserId = AuthStore.instance.currentUser?.id;
  if (currentUserId != null && currentUserId == intervenant?.id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vous ne pouvez pas contacter votre propre prise en charge.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  final number = intervenant?.whatsAppNumber;

  if (number == null || number.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('L\'intervenant n\'est pas joignable.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  // Nettoyer le numéro : supprimer espaces, tirets, parenthèses
  final cleaned = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  // Le numéro est déjà en format international (+225XXXXXXXXXX)
  // Supprimer uniquement le + pour l'URL wa.me
  final digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
  final uri = Uri.parse('https://wa.me/$digits');

  try {
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback navigateur
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir WhatsApp.'),
          backgroundColor: CliinAppColors.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}