import 'package:flutter/material.dart';

class CliinAppColors {
  CliinAppColors._();

  // Verts principaux
  static const Color primaryDark    = Color(0xFF1A6B2F); // vert foncé bouton
  static const Color primary        = Color(0xFF2DB84B); // vert logo principal
  static const Color primaryMedium  = Color(0xFF2DB84B); // même vert vif
  static const Color primaryLight   = Color(0xFFE6F7EB); // vert très clair fond badge

  // Alertes
  static const Color alertRed       = Color(0xFFE53935);
  static const Color alertRedBg     = Color(0xFFFFEBEE);
  static const Color alertOrange    = Color(0xFFFF9800);
  static const Color alertCritical  = Color(0xFFF44336);

  // Niveaux de badge groupe (Engagé / Impact / Officiel)
  static const Color levelEngage    = Color(0xFF7C3AED); // violet vif
  static const Color levelOfficiel  = Color(0xFF1565C0); // bleu vif
  // Impact réutilise primary (vert) — pas de nouvelle constante nécessaire.

  // Podium "Nos contributeurs" (Correction 1) — 1er/2e/3e rang.
  static const Color podiumGold     = Color(0xFFD4A017);
  static const Color podiumSilver   = Color(0xFF9AA3AC);
  static const Color podiumBronze   = Color(0xFFB2723D);

  // Textes
  static const Color textDark       = Color(0xFF1A1A2E);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textWhite      = Color(0xFFFFFFFF);

  // Fonds
  static const Color background     = Color(0xFFF4F4F2);
  static const Color cardWhite      = Color(0xFFFFFFFF);

  // Séparateur
  static const Color divider        = Color(0xFFE0E0E0);
}