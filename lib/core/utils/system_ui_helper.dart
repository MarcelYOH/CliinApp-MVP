import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Style plein écran commun à toute l'app (main.dart, et à chaque retour au
// premier plan via CliinApp._CliinAppState). Les pages caméra basculent
// temporairement en SystemUiMode.immersiveSticky puis reviennent à
// edgeToEdge sans réappliquer ce style — il faut donc le réaffirmer
// explicitement à chaque fois.
//
// Barres système TRANSPARENTES (statut ET navigation) — comportement
// d'origine, inchangé. Cette valeur est appliquée GLOBALEMENT (un seul
// appel dans main.dart, pas par page) et de nombreuses pages (profil
// groupe, détail action, création de signalement, écrans d'inscription...)
// s'appuient dessus pour laisser leur propre contenu (photo de couverture,
// fond blanc...) s'étendre sous ces barres ; les rendre opaques casse ce
// plein écran partout (régression déjà constatée une fois — ne pas
// reproduire).
//
// Bandeau noir sous la bottom bar au démarrage/reprise (diagnostic
// confirmé par logs + captures d'écran réelles, appareil à RAM très
// contrainte) : la vraie cause n'est PAS la transparence de ces barres
// (AppBottomNav peint déjà lui-même un fond blanc opaque jusque sous la
// barre de navigation, voir shared/widgets/app_bottom_nav.dart) mais le
// thème natif Android affiché AVANT que Flutter ne peigne sa première
// frame (NormalTheme héritait de Theme.Black.NoTitleBar → fond de fenêtre
// noir visible à travers des barres transparentes tant que rien n'est
// encore peint). Fix appliqué côté natif uniquement — voir
// android/app/src/main/res/values/styles.xml (NormalTheme : thème clair +
// windowBackground opaque clair) — sans toucher à la transparence des
// barres système elles-mêmes.
class SystemUiHelper {
  const SystemUiHelper._();

  static const SystemUiOverlayStyle edgeToEdgeStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static Future<void> restoreEdgeToEdge() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(edgeToEdgeStyle);
  }
}
