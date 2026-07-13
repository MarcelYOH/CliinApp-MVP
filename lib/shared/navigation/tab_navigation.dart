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
import 'fast_page_route.dart';

// Onglet à surligner sur HomePage après un retour à la racine via
// popUntil (Accueil/Groupes). HomePage n'est jamais reconstruite lors de
// ce pop — son State persiste depuis le tout premier affichage — donc
// son propre _currentNavIndex ne peut pas suivre tout seul le clic
// déclenché depuis une page enfant (ex: Profil, détail d'un cas) sans ce
// canal explicite. HomePage écoute cette valeur et l'applique dès qu'elle
// change (voir home_page.dart, _onPendingTabIndex).
final ValueNotifier<int?> pendingHomeTabIndex = ValueNotifier<int?>(null);

Future<void> navigateToTab(
  BuildContext context, {
  required int currentIndex,
  required int targetIndex,
}) async {
  if (targetIndex == currentIndex) return;

  // Accueil, et Groupes (la section "Groupes actifs" vit sur l'accueil —
  // pas encore de page dédiée) : retour direct à la racine.
  if (targetIndex == 0 || targetIndex == 3) {
    pendingHomeTabIndex.value = targetIndex;
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
  // transition, fluide. fastFadeRoute (et non MaterialPageRoute) : pour que
  // la Carte ait la même apparence peu importe le point de départ (voir
  // home_page.dart._goToMap, qui utilise la même transition).
  await Navigator.of(context).pushAndRemoveUntil(
    fastFadeRoute<void>(page),
    (route) => route.isFirst,
  );
}
