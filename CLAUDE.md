**RÈGLE PERMANENTE — NE JAMAIS COMPILER EN LOCAL** : toujours passer par le workflow GitHub Actions existant (`.github/workflows/build_apk.yml`) pour compiler. Une fois l'APK généré par GitHub Actions, le télécharger et l'installer sur le téléphone connecté via `adb install` — c'est la SEULE méthode autorisée désormais.

> Raison : le PC de développement dispose de seulement 4 Go de RAM, insuffisant pour Gradle. Toute tentative de compilation locale (`flutter build`, `flutter run`) est interdite.
