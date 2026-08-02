import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

// Style plein écran commun à toute l'app (main.dart, et à chaque retour au
// premier plan via CliinApp._CliinAppState). Les pages caméra basculent
// temporairement en SystemUiMode.immersiveSticky puis reviennent à
// edgeToEdge sans réappliquer ce style — il faut donc le réaffirmer
// explicitement à chaque fois.
//
// Bandeau noir sous la bottom bar (diagnostic confirmé par logs + captures
// d'écran réelles, sur un appareil à RAM très contrainte) : une barre de
// navigation TRANSPARENTE laisse apparaître un fond noir tant que Flutter
// n'a pas encore peint de contenu derrière — au premier lancement ET après
// un retour au premier plan (l'OS tue souvent le process en arrière-plan
// faute de RAM, ce qui relance un démarrage à froid plutôt qu'une vraie
// reprise, donc la même course contre le rendu se reproduit). Couleur
// opaque (CliinAppColors.background, identique à @color/app_background côté
// Android natif — android/app/src/main/res/values/styles.xml) au lieu de
// transparente : n'a plus aucune dépendance au rendu Flutter ni au timing
// de cet appel.
class SystemUiHelper {
  const SystemUiHelper._();

  static const SystemUiOverlayStyle edgeToEdgeStyle = SystemUiOverlayStyle(
    statusBarColor: CliinAppColors.background,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: CliinAppColors.background,
    systemNavigationBarDividerColor: CliinAppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static Future<void> restoreEdgeToEdge() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(edgeToEdgeStyle);
  }
}
