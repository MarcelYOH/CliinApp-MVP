# RECAP — Réorganisation catégories + champ Provenance

## Ce qui a été fait

### 1. Réorganisation des catégories (`shared/models/report_category.dart`)
- Renommé `bacDechetsSature` → `bacPoubelleSature` (label : "Bac/Poubelle saturée")
- Renommé `eauxStagnantes` → `eauxUsees` (label : "Eaux usées")
- Nouvel ordre de l'enum (ménages en premier) :
  1. bacPoubelleSature
  2. depotsSauvages
  3. caniveauxBouches
  4. eauxUsees
  5. conteneurSature
  6. zoneInsalubre
  7. brulageDesDechets
  8. dechetsIndustriels
  9. dechetsMedicaux

### 2. Nouveau modèle Provenance (`shared/models/report_origin.dart`)
Enum `ReportOrigin` créé avec même pattern que `ReportCategory` (label, icon) :
1. domicile — Domicile / Ménage
2. commerce — Commerce
3. espacePublic — Espace public
4. etablissementScolaire — Établissement scolaire
5. industrie — Industrie
6. etablissementSante — Établissement de santé

### 3. Propagation du champ `origin` dans toutes les couches
- `features/reports/models/report_model.dart` : champ `origin` ajouté (défaut : `espacePublic`)
- `features/home/models/home_report_model.dart` : champ `origin` ajouté (défaut : `espacePublic`)
- Les deux modèles ont `copyWith`, `toJson`, `fromJson` mis à jour
- Branchement Firebase futur : même pattern que `category` et `severity`

### 4. Formulaire (`features/reports/pages/report_form_page.dart`)
- Section "Provenance" ajoutée entre Catégorie et Niveau d'urgence
- Chips horizontaux scrollables, même style que les catégories
- Pré-sélection automatique sur "Espace public" à l'ouverture
- Badge vert "pré-sélectionné" à côté du titre
- Texte d'aide : "Déjà rempli — modifiable en 1 tap si besoin, sinon rien à faire."
- Jamais bloquant pour la publication (valeur par défaut toujours présente)

### 5. Données fictives mises à jour
- `features/home/data/home_dummy_data.dart` : références `eauxStagnantes` → `eauxUsees`, liste CategoryModel réordonnée
- `features/map/data/map_dummy_data.dart` : références `eauxStagnantes` → `eauxUsees` et `bacDechetsSature` → `bacPoubelleSature`
- `features/home/pages/home_page.dart` : map `_labelToCategory` mise à jour

### 6. Page succès (`features/reports/pages/report_success_page.dart`)
- `origin: r.origin` propagé lors de la construction de `HomeReportModel`

### 7. Correction NDK Android (`android/app/build.gradle.kts`)
- `ndkVersion` mis à jour de `26.1.10909125` → `28.2.13676358`
- Correction du blocage CMake qui empêchait la compilation release

## Résultats de vérification
- `dart analyze lib/` → **No issues found!**
- Fichier `map_dummy_data.dart` : **présent et valide** (les erreurs IDE signalées venaient du cache build — `flutter clean` + `flutter pub get` les a résolues)
- `bacPoubelleSature` est bien **en premier** dans l'enum
- `_selectedOrigin = ReportOrigin.espacePublic` est bien la **valeur par défaut** dans le formulaire
- APK compilé par **GitHub Actions** (run `28325191830`, artifact `CliinApp-release-5`, commit `3800371`)
- Téléchargé depuis Azure Blob Storage (via API GitHub + token OAuth)
- Installé sur **itel P651W** (Android 10, API 29) via `adb install` à **17:57:59** le 28/06/2026
- Sortie adb : `Performing Streamed Install → Success` (aucune erreur de signature)
- **Vérifié par l'utilisateur** : nouvelles catégories et section Provenance s'affichent correctement

## Process de build validé pour la suite
1. `git push origin main` → déclenche GitHub Actions automatiquement
2. Attendre la fin du run (~20 min) sur `https://github.com/MarcelYOH/CliinApp-MVP/actions`
3. Télécharger l'artifact `CliinApp-release-*` via API GitHub
4. Dézipper et `adb install -r app-release.apk` sur le téléphone connecté
⚠️ Ne jamais compiler en local (PC 4 Go RAM insuffisant pour Gradle)
