// lib/shared/navigation/home_route_observer.dart
//
// Permet à HomePage de savoir quand une autre page est poussée par-dessus
// elle / quand elle redevient visible (didPushNext/didPopNext), pour
// mettre en pause/reprendre le flux de position dédié au nom de ville
// affiché dans le message d'accueil — actif UNIQUEMENT tant que cette page
// est réellement visible, jamais en arrière-plan. Fichier séparé (plutôt
// que déclaré dans main.dart) pour éviter un import circulaire avec
// home_page.dart, qui a besoin de s'y abonner.

import 'package:flutter/material.dart';

class HomeRouteObserver extends RouteObserver<ModalRoute<void>> {
  HomeRouteObserver._();
  static final HomeRouteObserver instance = HomeRouteObserver._();
}
