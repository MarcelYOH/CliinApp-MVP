// lib/core/utils/clipboard_helper_io.dart
// Implémentation native (Android / iOS / desktop) — utilisée quand
// dart:html n'est PAS disponible (donc jamais en pratique sur Flutter Web).
//
// Sur ces plateformes, Clipboard.setData() utilise le presse-papier
// natif de l'OS, sans la restriction de "contexte sécurisé" propre aux
// navigateurs web — fonctionne donc normalement dans tous les cas.

import 'package:flutter/services.dart';

Future<bool> copyTextToClipboard(String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } catch (_) {
    return false;
  }
}