// lib/shared/navigation/more_menu_state.dart
// État partagé "menu Plus ouvert" — CliinApp
//
// Chaque page affiche sa propre instance d'AppBottomNav (Accueil, Carte,
// Profil, détail d'un cas, ...) avec son propre State local. Un booléen
// local à AppBottomNav ne suffit pas à garantir que "Plus" reste vert tant
// que son bottom sheet est affiché : ce notifier global sert de source de
// vérité unique, lue par toutes les instances via ValueListenableBuilder,
// pour que l'icône reflète l'état réel même si l'instance qui a ouvert le
// sheet est reconstruite entre-temps.
import 'package:flutter/foundation.dart';

final ValueNotifier<bool> isMoreMenuOpen = ValueNotifier<bool>(false);
