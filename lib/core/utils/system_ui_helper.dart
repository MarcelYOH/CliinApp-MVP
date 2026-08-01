import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Style plein écran transparent commun à toute l'app (main.dart). Les pages
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
    // DEBUG TEMPORAIRE (diagnostic bandeau noir sous la bottom bar) — à
    // retirer seulement après validation du diagnostic par l'utilisateur.
    debugPrint('[SYSUI-DEBUG] restoreEdgeToEdge() appelé — avant setEnabledSystemUIMode');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(edgeToEdgeStyle);
    debugPrint('[SYSUI-DEBUG] restoreEdgeToEdge() terminé — edgeToEdge + style transparent appliqués');
  }
}
