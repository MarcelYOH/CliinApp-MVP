// lib/core/utils/clipboard_helper_web.dart
// Implémentation web — utilisée uniquement quand la cible est Flutter Web.
//
// Stratégie en deux temps :
//   1) Tente l'API moderne (Clipboard.setData / navigator.clipboard) —
//      fonctionnera normalement une fois l'app servie en HTTPS.
//   2) Si ça échoue (contexte HTTP non sécurisé, ce qui est le cas en
//      test local via IP), bascule sur l'ancienne méthode
//      document.execCommand('copy') via un <textarea> caché — cette
//      méthode n'a PAS la restriction de contexte sécurisé et fonctionne
//      donc même en HTTP classique.

import 'package:web/web.dart' as web;
import 'package:flutter/services.dart';

Future<bool> copyTextToClipboard(String text) async {
  // 1) API moderne
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } catch (_) {
    // on continue vers le repli ci-dessous
  }

  // 2) Repli — execCommand('copy'), fonctionne en HTTP classique
  try {
    final textarea = web.HTMLTextAreaElement()
      ..value = text
      ..readOnly = true;
    textarea.style.setProperty('position', 'fixed');
    textarea.style.setProperty('left', '-9999px');
    textarea.style.setProperty('top', '0');
    web.document.body?.append(textarea);
    textarea.focus();
    textarea.select();
    textarea.setSelectionRange(0, text.length);

    final success = web.document.execCommand('copy');
    textarea.remove();
    return success;
  } catch (_) {
    return false;
  }
}
