// lib/shared/navigation/tab_navigation.dart
// Navigation directe entre les onglets de la bottom bar — CliinApp
//
// Chaque page qui affiche AppBottomNav doit déléguer son onTap à
// navigateToTab() plutôt que d'improviser son propre Navigator.push /
// popUntil. Garantit que, depuis N'IMPORTE QUELLE page, un onglet mène
// DIRECTEMENT à sa destination, sans jamais transiter par une page
// intermédiaire (ex: Accueil) au passage.
//
// Stratégie : Accueil (index 0) est toujours la racine de la pile de
// navigation (voir AuthGate / main.dart). Pour rejoindre un autre onglet,
// on réduit la pile à cette racine puis on empile directement la page
// cible — un seul saut visible, jamais deux.

import 'package:flutter/material.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/map/pages/map_page.dart';
import '../widgets/more_menu_sheet.dart';

void navigateToTab(
  BuildContext context, {
  required int currentIndex,
  required int targetIndex,
}) {
  if (targetIndex == currentIndex) return;

  // "Plus" n'est pas une destination — un modal bottom sheet s'ouvre
  // par-dessus la page courante, sans toucher à la pile de navigation.
  if (targetIndex == 4) {
    showMoreMenuSheet(context);
    return;
  }

  // Accueil, et Groupes (la section "Groupes actifs" vit sur l'accueil —
  // pas encore de page dédiée) : retour direct à la racine.
  if (targetIndex == 0 || targetIndex == 3) {
    Navigator.popUntil(context, (route) => route.isFirst);
    return;
  }

  final Widget page = switch (targetIndex) {
    1 => const MapPage(),
    _ => const HomePage(),
  };

  // pushAndRemoveUntil (et non popUntil() + push() séparés) : un pop suivi
  // d'un push juste après joue deux transitions animées à la suite (le
  // reverse de la page quittée, puis le forward de la page ciblée), ce qui
  // produit un tremblement visible — particulièrement depuis Profil, elle-
  // même empilée par-dessus Accueil. pushAndRemoveUntil empile la nouvelle
  // page et retire les anciennes en une seule transaction : une seule
  // transition, fluide.
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => route.isFirst,
  );
}
