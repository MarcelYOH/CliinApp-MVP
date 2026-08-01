import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Style plein écran transparent commun à toute l'app (main.dart, et à
// chaque retour au premier plan via CliinApp._CliinAppState). Les pages
// caméra basculent temporairement en SystemUiMode.immersiveSticky puis
// reviennent à edgeToEdge sans réappliquer ce style — sur Android, ce
// basculement remet la status bar / nav bar système en noir opaque tant que
// le style transparent n'est pas réaffirmé explicitement.
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
