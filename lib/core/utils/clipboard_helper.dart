// lib/core/utils/clipboard_helper.dart
//
// Point d'entrée unique pour copier du texte dans le presse-papier,
// quelle que soit la plateforme. N'importer QUE ce fichier — jamais
// directement les fichiers _io / _web ci-dessous.
//
// Pourquoi ce fichier existe : sur Flutter Web, l'API moderne
// navigator.clipboard.writeText() (utilisée par Clipboard.setData())
// exige un contexte sécurisé (HTTPS). En test local via une IP HTTP,
// elle échoue silencieusement. L'ancienne méthode execCommand('copy')
// n'a PAS cette restriction et fonctionne en HTTP classique.
//
// L'import conditionnel ci-dessous sélectionne automatiquement :
//   - clipboard_helper_web.dart  → si on compile pour le web
//   - clipboard_helper_io.dart   → sinon (Android/iOS/desktop natif)
export 'clipboard_helper_io.dart'
    if (dart.library.html) 'clipboard_helper_web.dart';