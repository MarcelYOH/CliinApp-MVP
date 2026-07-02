**RÈGLE PERMANENTE — NE JAMAIS COMPILER EN LOCAL** : toujours passer par le workflow GitHub Actions existant (`.github/workflows/build_apk.yml`) pour compiler. Une fois l'APK généré par GitHub Actions, le télécharger et l'installer sur le téléphone connecté via `adb install` — c'est la SEULE méthode autorisée désormais.

> Raison : le PC de développement dispose de seulement 4 Go de RAM, insuffisant pour Gradle. Toute tentative de compilation locale (`flutter build`, `flutter run`) est interdite.

---

**RÉPARTITION DES RÔLES — NON NÉGOCIABLE**

- Le chef produit (utilisateur) : conçoit les fonctionnalités, décide de l'expérience utilisateur, donne les instructions.
- L'exécutant technique (Claude) : implémente le code, pousse sur GitHub, surveille la compilation GitHub Actions, télécharge l'APK généré, et lance l'installation sur le téléphone connecté (`adb install`) — de bout en bout, sans aucune intervention de l'utilisateur.

L'utilisateur ne doit jamais avoir à télécharger un fichier lui-même, ni à taper une commande dans un terminal.

Si un blocage réel nécessite une action de l'utilisateur (ex. : authentification sur un compte tiers), l'expliquer clairement en 1-2 phrases simples avant de le demander. Ne jamais déléguer une tâche technique par défaut ou par facilité.
