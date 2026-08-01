// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/system_ui_helper.dart';
import 'shared/store/report_store.dart';
import 'shared/store/auth_store.dart';
import 'shared/store/group_store.dart';
import 'shared/store/action_store.dart';
import 'shared/store/notification_store.dart';
import 'features/home/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Affichage plein écran : l'app s'étend derrière la status bar et la nav
  // bar. Attendu (pas fire-and-forget), mais l'await seul ne suffit pas à
  // garantir que le rendu système Android soit terminé avant la 1re frame
  // Flutter (diagnostic confirmé par logs+captures d'écran réelles) — voir
  // _CliinAppState.didChangeAppLifecycleState ci-dessous, qui réapplique ce
  // même style à chaque retour au premier plan (y compris le tout premier,
  // juste après ce lancement), ce qui couvre ce cas comme les suivants.
  await SystemUiHelper.restoreEdgeToEdge();

  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialise les stores au démarrage
  await ReportStore.instance.init();
  await AuthStore.instance.init();
  await GroupStore.instance.init();
  await ActionStore.instance.init();
  await NotificationStore.instance.init();

  runApp(const CliinApp());
}

class CliinApp extends StatefulWidget {
  const CliinApp({super.key});

  @override
  State<CliinApp> createState() => _CliinAppState();
}

// Bandeau noir sous la bottom bar (diagnostic par logs + captures d'écran
// réelles) : SystemUiHelper.restoreEdgeToEdge() n'était appelé qu'au tout
// premier lancement (ci-dessus) et dans ReportCameraPage.dispose() — jamais
// réappliqué par ailleurs, alors qu'Android réinitialise l'apparence de la
// barre système à chaque retour au premier plan. Un unique observateur au
// niveau de l'app entière (et non d'une page précise) couvre les deux
// symptômes observés (premier lancement ET reprise après mise en veille)
// par le même mécanisme, sans dépendre de la page affichée à ce moment-là.
// Sans effet sur ReportCameraPage : son propre WidgetsBindingObserver est
// enregistré plus tard (à l'ouverture de la caméra, après celui-ci) et Flutter
// notifie les observateurs dans leur ordre d'enregistrement — son propre
// SystemUiMode.immersiveSticky est donc réappliqué juste après, sans
// changement de comportement pour ce flux.
class _CliinAppState extends State<CliinApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemUiHelper.restoreEdgeToEdge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CliinApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CliinAppColors.primary,
          surface: CliinAppColors.background,
        ),
        scaffoldBackgroundColor: CliinAppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}