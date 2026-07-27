// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/system_ui_helper.dart';
import 'shared/store/report_store.dart';
import 'shared/store/auth_store.dart';
import 'shared/store/group_store.dart';
import 'shared/store/action_store.dart';
import 'features/home/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Affichage plein écran : l'app s'étend derrière la status bar et la nav
  // bar. Attendu (pas fire-and-forget) — Correction 6.2 : sans await, le
  // tout premier frame pouvait être peint avant que l'OS n'applique le mode
  // edge-to-edge/la barre système transparente, laissant un bandeau noir
  // résiduel sous la bottom bar jusqu'à ce qu'un rebuild ultérieur (ex. une
  // action de l'utilisateur) coïncide avec l'application effective du style.
  await SystemUiHelper.restoreEdgeToEdge();

  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialise les stores au démarrage
  await ReportStore.instance.init();
  await AuthStore.instance.init();
  await GroupStore.instance.init();
  await ActionStore.instance.init();

  runApp(const CliinApp());
}

class CliinApp extends StatelessWidget {
  const CliinApp({super.key});

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