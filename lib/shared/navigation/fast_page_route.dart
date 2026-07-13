// lib/shared/navigation/fast_page_route.dart
// Transition rapide et cohérente — remplace la transition par défaut de
// MaterialPageRoute (~300ms, slide/zoom) par un fondu court, pour que la
// navigation paraisse immédiate. À utiliser pour toute destination
// atteignable depuis plusieurs points de départ, afin qu'elle ne change
// pas d'apparence selon le chemin emprunté.

import 'package:flutter/material.dart';

PageRouteBuilder<T> fastFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}
