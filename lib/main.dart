// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'shared/store/report_store.dart';
import 'features/home/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise le store mock au démarrage
  await ReportStore.instance.init();

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