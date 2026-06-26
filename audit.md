# Audit technique — CliinApp (Flutter)
**Date :** 2026-06-23  
**Auteur :** Audit produit par Claude Code (Anthropic), ingénieur senior assigné au projet  
**Périmètre :** Dossier `lib/` complet, lecture seule — aucun fichier modifié  
**Destinataire futur :** Développeur backend senior qui reprendra le projet lors de la phase pilote

---

## Table des matières

1. [Architecture actuelle et propositions de réorganisation](#1-architecture-actuelle)
2. [Cycle de création de signalement — analyse de bout en bout](#2-cycle-création)
3. [Cycle de prise en charge — analyse de bout en bout](#3-cycle-prise-en-charge)
4. [Utilisateur factice codé en dur — inventaire complet](#4-utilisateur-factice)
5. [Modules futurs — visuels existants non branchés](#5-modules-futurs)
6. [État de la documentation](#6-documentation)
7. [Liste priorisée des corrections et réorganisations](#7-priorités)

---

## 1. Architecture actuelle

### 1.1 Vue d'ensemble

```
lib/
├── core/          → Design tokens (couleurs, constantes, styles) + services utilitaires
├── dev/           → Page de test temporaire (hors prod)
├── features/      → Modules fonctionnels organisés par feature
│   ├── auth/      → Vide (prévu, non implémenté)
│   ├── home/      → Écran accueil
│   ├── map/       → Carte exploratoire
│   └── reports/   → Création, suivi, preuve de signalement
└── shared/        → Code partagé entre features (models, repo, store, widgets)
```

**Pattern architectural utilisé :** Clean Architecture simplifiée à 3 couches :

```
Couche Présentation  →  Pages + Widgets (StatefulWidget / StatelessWidget)
        ↕  addListener / notifyListeners
Couche Métier        →  ReportStore (ChangeNotifier singleton)
        ↕  interface abstraite
Couche Données       →  MockReportRepository  →  données factices en mémoire
```

**State management :** ChangeNotifier + listeners manuels (pas de Provider widget, pas de Consumer — les pages appellent `ReportStore.instance` directement via le singleton).

**Navigation :** `Navigator.push()` impératif partout. Pas de GoRouter, pas de routes nommées.

---

### 1.2 Problème structurel majeur : deux modèles pour un même concept

Il existe deux classes qui représentent un signalement :

| Classe | Fichier | Rôle déclaré | Champs notables |
|---|---|---|---|
| `ReportModel` | `features/reports/models/report_model.dart` | Modèle de création (flow form → upload) | `imagePath`, `imageUrl`, `userId`, `ReportWorkflowStatus` |
| `HomeReportModel` | `features/home/models/report_model.dart` | Modèle d'affichage (store, cartes, carte) | `imageAsset`, `distance`, `timeAgo`, `signalePar`, `history`, `intervenant` |

Ces deux classes ne partagent pas de classe parente commune. La conversion entre les deux est faite manuellement dans `ReportSuccessPage._addToStore()` (lignes 57–87), ce qui crée une zone de risque : tout nouveau champ ajouté à `ReportModel` doit être mappé manuellement vers `HomeReportModel`, sinon il est perdu silencieusement.

**Proposition :** Quand le backend sera branché, unifier ces deux modèles en un seul `ReportModel` avec des champs optionnels selon le contexte, ou introduire une classe `ReportEntity` partagée dont les deux héritent.

---

### 1.3 Nommage trompeur du fichier de réexports

`lib/features/home/models/report_model.dart` n'est **pas** un modèle — c'est uniquement un fichier de réexports :

```dart
// Ce fichier réexporte depuis 4 sources différentes :
export 'package:cliinapp/shared/models/report_category.dart';
export 'package:cliinapp/features/reports/models/report_model.dart' show ReportSeverity, ...;
export 'package:cliinapp/shared/models/report_status.dart';
export 'package:cliinapp/shared/models/report_history_entry.dart';
export 'package:cliinapp/shared/models/intervenant_model.dart';
// Et contient la définition de HomeReportModel
```

Un développeur externe qui cherche `HomeReportModel` trouvera ce fichier mais ne saura pas si c'est là que vit vraiment la classe ou si c'est un proxy. Ce fichier devrait s'appeler `home_report_barrel.dart` ou `home_report_model.dart` avec un commentaire d'en-tête explicite.

---

### 1.4 Double initialisation du store

`ReportStore.instance.init()` est appelé à deux endroits :

- `lib/main.dart` ligne 11 : `await ReportStore.instance.init();` (bloquant, avec await)
- `lib/features/home/pages/home_page.dart` ligne 41 : `ReportStore.instance.init();` (non bloquant, dans `initState`)

Le deuxième appel relance un chargement complet (reset de `_isLoading`, rechargement des données) chaque fois que `HomePage` est recréée. En pratique, `HomePage` est la racine et ne se recrée qu'au démarrage, donc l'impact est limité — mais ce pattern est fragile et doit être documenté.

**Proposition :** Ajouter un flag `_initialized` dans `ReportStore.init()` pour rendre l'appel idempotent, ou supprimer l'appel dans `home_page.dart` et ne conserver que celui dans `main.dart`.

---

### 1.5 Deux enums de statut dont la distinction n'est pas évidente

| Enum | Fichier | Valeurs | Usage |
|---|---|---|---|
| `ReportStatus` | `shared/models/report_status.dart` | `disponible`, `enCours`, `traite` | Statut visible sur les cartes, dans le store, dans les filtres |
| `ReportWorkflowStatus` | `features/reports/models/report_model.dart` | `enAttente`, `enCours`, `traite`, `rejete` | Statut du flow d'upload (simulé), stocké dans `ReportModel` temporaire |

Le champ `rejete` de `ReportWorkflowStatus` n'a pas d'équivalent dans `ReportStatus`. La valeur `enCours` existe dans les deux avec la même sémantique apparente. Un développeur backend devra décider si ces deux concepts fusionnent ou restent séparés (logique distincte : état réseau vs état métier).

**Proposition :** Documenter explicitement la distinction dans un commentaire d'en-tête dans chaque fichier.

---

### 1.6 `IntervenantModel.copyWith()` — champ `groupName` manquant

`IntervenantModel.copyWith()` (ligne 34, `shared/models/intervenant_model.dart`) implémente tous les champs sauf `groupName`. Conséquence directe dans `mock_report_repository.dart` :

```dart
// toggleWhatsApp() et updateWhatsAppNumber() reconstituent l'intervenant
// sans passer groupName → le nom du groupe est perdu silencieusement
// à chaque toggle WhatsApp ou mise à jour de numéro.
final updated = report.copyWith(
  intervenant: IntervenantModel(
    id: report.intervenant!.id,
    name: report.intervenant!.name,
    // groupName: manquant → null implicite
    ...
  ),
);
```

Ce bug est actuellement invisible en MVP car `groupName` n'est affiché nulle part dans l'UI après la prise en charge, mais il sera un problème dès que la page "détail intervenant groupe" sera implémentée.

---

### 1.7 `HomeReportModel.copyWith()` — `imageAfterAsset` ne peut pas être effacé

Le pattern `??` dans `copyWith()` empêche de passer explicitement `null` pour effacer un champ optionnel. C'est le comportement Dart standard, mais pour `imageAfterAsset`, si l'on souhaite un jour "annuler" une preuve, ce sera impossible sans refactorer. À documenter.

---

### 1.8 Calcul de distance en doublon

La formule de Haversine est implémentée deux fois :

- `lib/core/utils/user_location_service.dart` : `distanceMetersTo()`
- `lib/shared/repositories/mock_report_repository.dart` : `_distanceMeters()`

Lors du passage à Firebase, il faudra décider quelle implémentation devient la référence. Actuellement, elles donnent le même résultat mais elles ne se connaissent pas.

---

### 1.9 Dossiers vides

| Dossier | Statut |
|---|---|
| `features/auth/{data,models,pages,store,widgets}/` | Tous vides — MVP sans auth |
| `core/theme/` | Vide — thématisation non implémentée |
| `features/map/models/map_report_model.dart` | Fichier vide (0 octets) |

Les dossiers vides de `auth/` sont intentionnels (prévu pour phase suivante) mais doivent être signalés au développeur entrant. Le fichier `map_report_model.dart` vide doit être supprimé ou renseigné.

---

## 2. Cycle de création de signalement

### 2.1 Flux complet

```
ReportCameraPage (étape 1)
    → [photo capturée] → ReportPreviewPage (étape 2) [si existant]
    → ReportFormPage (étape 3, reçoit imagePath + address)
        → [_publish()] → ReportUploadPage (étape 4, reçoit ReportModel)
            → [_simulateUpload()] → ReportSuccessPage (étape 5)
                → [_addToStore()] → ReportStore.addReport(HomeReportModel)
                    → MockReportRepository.addReport()
```

### 2.2 Génération du code signalement en doublon

`_generateReportCode()` est définie deux fois, avec le même code :

- `lib/features/reports/pages/report_form_page.dart` lignes 25–28
- `lib/features/reports/pages/report_upload_page.dart` lignes 19–22

**Séquence réelle :**
1. `report_form_page.dart._publish()` génère un code et le passe dans `ReportModel.copyWith(reportCode: _generateReportCode())`
2. `report_upload_page.dart._simulateUpload()` utilise `widget.report.reportCode ?? _generateReportCode()` — le `??` garantit qu'un deuxième code n'est généré qu'en fallback

La logique est correcte mais fragile : si quelqu'un supprime la génération dans `_publish()`, tous les signalements auront le même code hérité de `ReportDummyData.publishedReport` (`#CLN-6589`).

**Proposition :** Centraliser `generateReportCode()` dans `ReportDummyData` ou dans un fichier utilitaire `lib/core/utils/code_generator.dart`, et n'en avoir qu'un seul point d'appel (dans le repository, au moment de `addReport()`).

---

### 2.3 `ReportDummyData.publishedReport` — template factice utilisé comme base

Dans `report_form_page.dart._publish()` (ligne 162) :

```dart
final report = ReportDummyData.publishedReport.copyWith(
  imagePath: widget.imagePath,
  reportCode: _generateReportCode(),
  title: _selectedCategory.label,
  category: _selectedCategory,
  severity: _selectedSeverity,
  description: _descController.text.trim(),
  address: _addressController.text.trim(),
  latitude: _latitude,
  longitude: _longitude,
);
```

Les champs suivants de `publishedReport` **ne sont jamais réécrit** par ce `copyWith()` et transitent tels quels jusqu'au store :

| Champ | Valeur dummy | Impact |
|---|---|---|
| `viewsCount` | 0 | Neutre pour l'instant |
| `commentsCount` | 0 | Neutre pour l'instant |
| `sharesCount` | 0 | Neutre pour l'instant |
| `userId` | `'user_001'` | **Critique** — devra être l'ID réel de l'utilisateur connecté |
| `imageUrl` | `null` | Neutre (sera l'URL backend) |

`userId: 'user_001'` sera un problème dès que l'authentification sera branchée : tous les signalements créés seront attribués au même utilisateur fictif si ce champ n'est pas mis à jour.

---

### 2.4 Coordonnées factices affichées pendant le chargement GPS

Dans `report_form_page.dart.initState()` (lignes 69–70) :

```dart
_latitude = ReportDummyData.detectedLatitude;   // 5.4010 (Cocody)
_longitude = ReportDummyData.detectedLongitude; // -3.9570 (Cocody)
```

Ces valeurs sont affichées à l'utilisateur avant que le GPS ne réponde. Si le GPS échoue, elles restent **sans indication** (bug corrigé dans le code actuel avec `_gpsFailed`). Mais si le GPS échoue silencieusement après timeout, `_latitude/_longitude` restent sur Cocody et sont envoyés au store comme coordonnées réelles.

---

### 2.5 `report_form_page.dart` appelle directement `Geolocator` au lieu de `UserLocationService`

`_refreshLocation()` (ligne 98) appelle `Geolocator.getCurrentPosition()` directement, bypasse le cache centralisé de `UserLocationService`. La correction partielle existe : après succès, `UserLocationService.instance.setKnownPosition(position)` est appelé (ligne 123). Mais l'appel initial ne passe pas par le service centralisé, ce qui peut déclencher deux requêtes GPS simultanées si `ReportStore.init()` est aussi en train de récupérer la position.

**Proposition :** Remplacer l'appel direct à `Geolocator` par `UserLocationService.instance.getCurrentPosition()`.

---

### 2.6 `signalePar` jamais renseigné dans le flow de création

Dans `_publish()`, `ReportDummyData.publishedReport` a `signalePar` à null (non défini dans la classe `ReportModel`). Dans `ReportSuccessPage._addToStore()` (ligne 83), `signalePar: 'Vous'` est codé en dur. Ce n'est pas un bug pour le MVP, mais c'est le point exact à remplacer par `currentUser.name` ou l'ID auth.

---

### 2.7 `ReportFormPage` — message d'erreur GPS technique exposé à l'utilisateur

Ligne 62, variable `_gpsErrorMessage` : le message d'erreur brut de la plateforme (`e.toString()`) est affiché dans l'UI (lignes 407–415). Un commentaire `// 🔍 TEMPORAIRE` indique que c'est à supprimer — mais ce code est actuellement en production. À retirer avant le lancement pilote.

---

### 2.8 Gestion des erreurs absente sur les boutons d'action de succès

Dans `ReportSuccessPage._buildNextActionsRow()` (lignes 389–427) :

- "Partager le signalement" : `onTap: null` — bouton visuellement actif mais sans action
- "Voir mon signalement" : `onTap: null` — idem

Ces boutons sont présents dans l'UI mais non fonctionnels. L'utilisateur peut croire à un bug.

---

## 3. Cycle de prise en charge

### 3.1 Flux complet

```
ReportCard → bouton "Prendre en charge"
    → showTakeChargeFlow() [take_charge_flow.dart]
        → _Step1Sheet : sélection type (individuel / groupe)
        → _Step2Sheet : saisie numéro WhatsApp (optionnel)
        → [_submit()] → ReportStore.takeCharge()
            → MockReportRepository.takeCharge()
                → HomeReportModel.copyWith(status: enCours, intervenant: ...)
        → _Step3Sheet : confirmation + "72 heures"
            → [_onConfirmClose()] → Navigator.pop() + onSuccess(updated)
                → IntervenantDetailPage(report: updated)
```

### 3.2 `IntervenantModel.groupName` perdu après toggle WhatsApp

Comme décrit en 1.6, `mock_report_repository.dart.toggleWhatsApp()` (lignes 140–155) reconstruit `IntervenantModel` sans `groupName`. Même problème dans `updateWhatsAppNumber()` (lignes 169–179).

Exemple concret : un groupe "Clean Riviera" prend en charge un signalement. L'intervenant ouvre `IntervenantDetailPage`, bascule la visibilité WhatsApp. Après la mise à jour, `intervenant.groupName` est null — la mention du groupe disparaît de l'UI si elle était affichée.

**Correction requise :** Utiliser `IntervenantModel.copyWith()` après avoir ajouté `groupName` dans ses paramètres, au lieu de reconstruire manuellement l'objet.

---

### 3.3 Groupes disponibles à la prise en charge : liste hardcodée

Dans `take_charge_flow.dart` (lignes 79–83) :

```dart
static const List<String> _mockGroups = [
  'Clean Riviera',
  'Green City',
  'Eco Jeunes',
];
```

Ces groupes ne sont pas liés au store ni aux `HomeDummyData.groups`. Un utilisateur réel ne verra jamais ses vrais groupes dans cette liste. Quand le module Groupes sera implémenté, cette liste devra être remplacée par un appel au store ou repository.

---

### 3.4 Délai de 72h et distance de 50m hardcodés

```dart
// intervenant_detail_page.dart ligne 44
final deadline = takenAt.add(const Duration(hours: 72));

// mock_report_repository.dart ligne 209
isValid = distance <= 50.0;
```

Ces deux constantes métier critiques sont dispersées dans le code. Elles doivent être extraites dans `AppConstants` ou dans une classe `BusinessRules` dédiée pour être facilement reconfigurables et documentées.

---

### 3.5 Aucune validation du numéro WhatsApp

`_Step2Sheet` accepte n'importe quelle saisie dans le champ téléphone, y compris vide (si consentement activé). `_fullPhoneNumber` retourne une string vide si `phoneController.text.trim().isEmpty`. Cette string vide est ensuite conditionnée par `fullNumber?.isNotEmpty == true ? fullNumber : null` dans `_submit()` — le null est donc propagé correctement. Mais aucun message d'erreur n'est affiché à l'utilisateur si le consentement est activé mais le numéro vide.

---

### 3.6 Bouton "Accéder à mon tableau de bord" sans destination

Dans `_Step3Sheet` (ligne 844) :

```dart
child: Text('Accéder à mon tableau de bord', ...),
```

Ce bouton ferme simplement la modal (`Navigator.pop`). Il n'existe pas de tableau de bord. C'est normal pour le MVP mais doit être documenté : ce CTA est prévu pour pointer vers la page de profil/mes signalements.

---

### 3.7 `_whatsAppVisible` dans `IntervenantDetailPage` — état local désynchronisé du store

`IntervenantDetailPage` maintient `_whatsAppVisible` en état local (ligne 25) et `_report` en copie locale (ligne 22). Quand un autre écran modifie le même signalement dans le store, cette page ne se met pas à jour — elle n'est pas abonnée aux changements du `ReportStore`. Si l'utilisateur revient en arrière et revient sur cette page, il verra les données à jour. Mais pendant que la page est ouverte, elle peut afficher des données périmées.

---

### 3.8 Preuve d'intervention — flux `ProofResultPage` non visible dans le code analysé

Les pages `proof_result_page.dart` et `proof_upload_page.dart` ne figuraient pas dans les fichiers directement analysés. Il convient de vérifier leur connexion au store et leur gestion d'erreurs dans un audit complémentaire.

---

## 4. Utilisateur factice codé en dur — inventaire complet

Voici tous les endroits où un utilisateur fictif est utilisé et qui devront être remplacés par l'authentification réelle :

| # | Fichier | Ligne(s) | Valeur factice | À remplacer par |
|---|---|---|---|---|
| 1 | `lib/shared/data/dummy_user.dart` | entier | `UserModel(id:'1', name:'Marcel Yoh', avatarUrl:'assets/images/profile.jpg', notificationCount:3)` | `AuthService.currentUser` |
| 2 | `lib/features/home/pages/home_page.dart` | 193 | `AppHeader(user: DummyUser.currentUser, ...)` | Utilisateur authentifié |
| 3 | `lib/features/home/pages/home_page.dart` | 193 | `onNotificationTap: () {}` | Navigation vers Notifications |
| 4 | `lib/features/home/pages/home_page.dart` | 193 | `onAvatarTap: () {}` | Navigation vers Profil |
| 5 | `lib/features/reports/widgets/take_charge_flow.dart` | 130 | `final user = DummyUser.currentUser;` | Utilisateur authentifié |
| 6 | `lib/features/reports/widgets/take_charge_flow.dart` | 133 | `IntervenantModel(id: user.id, name: user.name, ...)` | ID et nom de l'utilisateur authentifié |
| 7 | `lib/features/reports/pages/report_success_page.dart` | 83 | `signalePar: 'Vous'` | `currentUser.name` |
| 8 | `lib/shared/repositories/mock_report_repository.dart` | 81 | `actorName: report.signalePar ?? 'Vous'` | `currentUser.name` |
| 9 | `lib/features/reports/pages/report_form_page.dart` | 162 | Héritage de `ReportDummyData.publishedReport.userId` = `'user_001'` | `currentUser.id` |
| 10 | `lib/features/reports/data/report_dummy_data.dart` | 27 | `userId: 'user_001'` dans le template | Non applicable (template à supprimer) |

**Point d'intégration auth — séquence recommandée pour le développeur backend :**

1. Implémenter un `AuthRepository` (interface) + `FirebaseAuthRepository` dans `features/auth/`
2. Créer un `AuthStore` (ChangeNotifier) qui expose `currentUser`
3. Remplacer `DummyUser.currentUser` par `AuthStore.instance.currentUser` dans les points 2, 5, 6
4. Passer `currentUser.name` dans `signalePar` au moment de `_publish()` dans `report_form_page.dart`
5. Passer `currentUser.id` dans `userId` du `ReportModel` créé

---

## 5. Modules futurs — visuels existants non branchés

### 5.1 Module Groupes (partiellement implémenté visuellement)

`lib/features/home/widgets/home_groups.dart` — widget complet et visuellement finalisé avec :
- Carte groupe avec bannière, logo, compteurs (membres, actions, localisation)
- Bouton "Suivre / Suivi" (animé) → `_toggleFollow()` = snackbar uniquement, pas de persistence
- Avatar stack des membres (hardcodés à 4 copies de `profile.jpg`)

Callbacks non branchés dans `home_page.dart` (ligne 165–167) :
```dart
HomeGroups(
  groups: HomeDummyData.groups,
  onVoirTout: () {},      // → Page "Tous les groupes" non créée
  onCardTap: (_) {},      // → Page "Détail groupe" non créée
),
```

`HomeDummyData.groups` = données factices (3 groupes : Clean City, Eco San-Pedro, Jeunes Verts).

### 5.2 Module Notifications (icône présente, logique absente)

`AppHeader` affiche un badge avec `user.notificationCount` (valeur = 3 depuis `DummyUser`).
`onNotificationTap: () {}` — aucune page de notifications n'existe.

### 5.3 Module Profil utilisateur (avatar cliquable sans destination)

`AppHeader.onAvatarTap: () {}` — avatar affiché mais aucune page profil n'existe.
La photo `assets/images/profile.jpg` est hardcodée dans `DummyUser`.

### 5.4 Module Actions communautaires (section "Signalement rapide")

`HomeQuickReport` affiche une rangée de catégories rapides issues de `HomeDummyData.quickReport.categories`. Le tap sur le bouton `+` lance la caméra (`_openCamera()`), correctement branché. Mais les chips de catégories dans `HomeQuickReport` n'ont pas de logique — elles sont affichées mais ne présélectionnent rien dans le formulaire.

### 5.5 Actions post-succès non branchées (ReportSuccessPage)

Dans `_buildNextActionsRow()` :

```dart
_ActionItem(icon: Icons.share_outlined,    label: 'Partager\nle signalement'),  // onTap: null
_ActionItem(icon: Icons.visibility_outlined, label: 'Voir mon\nsignalement'),   // onTap: null
_ActionItem(icon: Icons.home_outlined, label: 'Retour à\nl\'accueil',
    onTap: () => _goHome(context)),  // seul bouton branché
```

### 5.6 Bannière d'action (HomeActionBanner)

`HomeActionBanner(data: HomeDummyData.actionBanner, onTap: () {})` — CTA visible dans l'UI mais sans destination.

### 5.7 Bouton "Accéder à mon tableau de bord" (Step3 prise en charge)

Comme décrit en 3.6 — visuellement présent, ne navigue nulle part.

### 5.8 Fonctions de recherche (AppHeader)

`AppHeader.onSearch: (_) {}` — barre de recherche affichée mais non fonctionnelle depuis l'accueil. Elle est fonctionnelle côté Map (`map_search_header.dart`).

---

## 6. État de la documentation

### 6.1 Ce qui existe

| Élément | Qualité | Remarques |
|---|---|---|
| Commentaires inline | Bonne à très bonne | Explications détaillées sur les décisions de correction (ex : `✅ CORRECTION`, `✅ NOUVEAU`) |
| En-têtes de fichiers | Partiels | Présents dans certains fichiers (`// lib/...`), absents dans d'autres |
| `pubspec.yaml` | Insuffisant | `description: "A new Flutter project."` — non mis à jour |
| README.md | Non audité | Probablement le template Flutter standard |
| ARCHITECTURE.md | Absent | Aucun document d'architecture existant |
| Commentaires de modèles | Partiels | `IntervenantModel` a des commentaires utiles ; `HomeReportModel` n'en a pas |

### 6.2 Problème avec les commentaires de correction

Les commentaires du style `// ✅ CORRECTION — avant, X faisait Y...` sont utiles pour comprendre l'évolution, mais ils documentent **l'histoire** plutôt que **l'intention**. Un développeur entrant doit comprendre ce que le code fait maintenant, pas ce qu'il faisait avant. Ces commentaires devraient migrer vers les messages de commit ou vers une section CHANGELOG.md.

Exemple problématique (`report_form_page.dart` lignes 19–28) :
```dart
// ✅ CORRECTION — génération réelle du code, ici, à la source.
// ReportDummyData.publishedReport contient un reportCode factice figé
// (probablement '#CLN-6589') qui n'était jamais réécrit dans _publish(),
// donc TOUS les signalements créés héritaient du même code dummy — le
// fallback ajouté dans report_upload_page.dart ne se déclenchait jamais
// puisque le champ n'était jamais null à ce stade.
```

Ce commentaire de 6 lignes décrit un bug corrigé. Il devrait être : `// Code unique généré ici pour garantir la cohérence entre form et upload.`

### 6.3 Ce qui manque pour la transmission au développeur backend

Pour qu'un développeur backend senior externe reprenne ce projet efficacement, il manque :

1. **`README.md` complet** comprenant :
   - Description du produit (CliinApp, civic-tech, San-Pedro, Côte d'Ivoire)
   - Prérequis de développement (Flutter SDK version, émulateurs, etc.)
   - Commandes de démarrage
   - Structure du projet et conventions
   - Points d'intégration backend (où brancher Firebase)

2. **`ARCHITECTURE.md`** comprenant :
   - Schéma des couches (Présentation → Store → Repository)
   - Explication du swap Repository (comment remplacer Mock par Firebase)
   - Explication de `HomeReportModel` vs `ReportModel`
   - Convention de nommage (pourquoi deux modèles)

3. **`INTEGRATION_GUIDE.md`** (ou section dans README) comprenant :
   - Liste de tous les points d'intégration backend (authentification, upload image, signalements, push notifications)
   - Ordre recommandé d'intégration
   - Schéma de données proposé (collections Firestore ou tables SQL)

4. **Commentaires de classe manquants** sur `HomeReportModel`, `ReportStore`, `UserLocationService`

5. **Suppression des commentaires d'historique** qui nuisent à la lisibilité

---

## 7. Liste priorisée des corrections et réorganisations

### 🔴 BLOQUANT — À corriger avant tout lancement pilote

| # | Problème | Fichier(s) concerné(s) | Action requise |
|---|---|---|---|
| B1 | Message d'erreur GPS technique affiché à l'utilisateur | `report_form_page.dart` lignes 407–415 | Supprimer `_gpsErrorMessage` et son affichage ; remplacer par un message générique |
| B2 | Page de test en production | `lib/dev/report_card_test_page.dart` | Supprimer ce fichier et son dossier `dev/` |
| B3 | `userId: 'user_001'` propagé dans tous les signalements créés | `report_dummy_data.dart` / `report_form_page.dart` | Brancher sur l'ID utilisateur réel (ou documenter clairement comme limitation MVP) |
| B4 | Boutons "Partager" et "Voir mon signalement" cliquables mais sans action | `report_success_page.dart` lignes 390–391 | Griser visuellement (désactiver) ou implémenter la navigation |
| B5 | Double appel `ReportStore.init()` | `main.dart` + `home_page.dart` | Rendre `init()` idempotent ou supprimer l'appel dans `home_page.dart` |

---

### 🟠 IMPORTANT — À corriger avant d'embarquer le développeur backend

| # | Problème | Fichier(s) concerné(s) | Action requise |
|---|---|---|---|
| I1 | `IntervenantModel.copyWith()` manque `groupName` → perte silencieuse de données | `shared/models/intervenant_model.dart` + `mock_report_repository.dart` | Ajouter `groupName` dans `copyWith()` ; utiliser `copyWith()` dans `toggleWhatsApp` et `updateWhatsAppNumber` |
| I2 | Génération du code signalement dupliquée | `report_form_page.dart` + `report_upload_page.dart` | Centraliser dans `MockReportRepository.addReport()` uniquement ; supprimer les fonctions locales |
| I3 | `ReportDummyData.publishedReport` utilisé comme template mutable | `report_form_page.dart` | Créer un constructeur `ReportModel.empty()` ou utiliser un factory propre sans dépendance aux données factices |
| I4 | Calcul de distance Haversine dupliqué | `user_location_service.dart` + `mock_report_repository.dart` | Utiliser uniquement `UserLocationService.instance.distanceMetersTo()` dans le repository |
| I5 | `_refreshLocation()` bypass `UserLocationService` | `report_form_page.dart` | Remplacer l'appel direct à `Geolocator` par `UserLocationService.instance.getCurrentPosition()` |
| I6 | Constantes métier hardcodées (72h, 50m, 2km) | `intervenant_detail_page.dart`, `mock_report_repository.dart`, `report_store.dart` | Les centraliser dans une classe `AppBusinessRules` ou dans `AppConstants` |
| I7 | Deux enums de statut non documentés (`ReportStatus` vs `ReportWorkflowStatus`) | `shared/models/report_status.dart`, `features/reports/models/report_model.dart` | Ajouter commentaires d'en-tête explicitant la distinction cycle de vie vs upload |
| I8 | `map_report_model.dart` — fichier vide | `features/map/models/map_report_model.dart` | Supprimer le fichier ou documenter l'intention |
| I9 | `signalePar: 'Vous'` hardcodé dans la création | `report_success_page.dart` ligne 83 | Documenter comme point d'intégration auth ; créer un commentaire `// TODO(auth): remplacer par currentUser.name` |
| I10 | Navigation sans router — pas de deep linking | Toutes les pages | Documenter la dette technique ; planifier migration GoRouter avant phase 2 |

---

### 🟡 MINEUR — Améliorations de qualité code / maintenabilité

| # | Problème | Fichier(s) concerné(s) | Action requise |
|---|---|---|---|
| M1 | `features/home/models/report_model.dart` nom trompeur | `features/home/models/report_model.dart` | Renommer en `home_report_model.dart` ou ajouter commentaire d'en-tête clair |
| M2 | Commentaires de correction historiques longs | Multiple | Remplacer par commentaires d'intention ; déplacer l'historique dans CHANGELOG |
| M3 | `pubspec.yaml` description générique | `pubspec.yaml` | Mettre à jour avec description CliinApp |
| M4 | `_mockGroups` dans `take_charge_flow.dart` déconnecté du store | `take_charge_flow.dart` lignes 79–83 | Marquer `// TODO(groups): remplacer par GroupStore.instance.userGroups` |
| M5 | Double init non documentée | `main.dart` + `home_page.dart` | Ajouter commentaire expliquant pourquoi les deux existent |
| M6 | `features/auth/` dossiers vides non documentés | `features/auth/` | Ajouter un fichier `README.md` dans `auth/` expliquant ce qui est prévu |
| M7 | `HomeReportModel` n'a pas de commentaire de classe | `features/home/models/report_model.dart` | Ajouter docstring expliquant la distinction avec `ReportModel` |
| M8 | `core/theme/` vide | `core/theme/` | Supprimer ou ajouter un fichier `app_theme.dart` même minimal |
| M9 | Aucune validation numéro WhatsApp | `take_charge_flow.dart` | Ajouter validation longueur minimale si consentement activé |
| M10 | `IntervenantDetailPage` non abonnée au store | `intervenant_detail_page.dart` | Ajouter `ReportStore.instance.addListener()` ou migrer vers `ListenableBuilder` |

---

## Résumé pour le développeur backend entrant

**CliinApp** est une application Flutter civic-tech de signalement d'insalubrité, développée pour la ville pilote de San-Pedro (Côte d'Ivoire). Le MVP est fonctionnel avec un backend simulé en mémoire.

**Ce qui fonctionne parfaitement :**
- Architecture feature-first propre et prévisible
- Repository pattern prêt pour le swap Firebase (remplacer `MockReportRepository` par `FirebaseReportRepository` sans toucher aux widgets)
- Modèles typés avec `copyWith()`, `toJson()`, `fromJson()` sur les modèles critiques (`IntervenantModel`, `ReportModel`)
- Gestion GPS centralisée (`UserLocationService`)
- Workflow signalement end-to-end fonctionnel

**Ce qui doit être fait en priorité avant l'intégration backend :**
1. Corriger les 5 points BLOQUANTS (B1–B5)
2. Implémenter `features/auth/` avec Firebase Auth
3. Remplacer `DummyUser.currentUser` dans les 10 points identifiés en section 4
4. Corriger `IntervenantModel.copyWith()` (I1) — bug silencieux
5. Centraliser les constantes métier (I6)

**Point d'entrée recommandé pour le swap backend :**
```dart
// lib/shared/repositories/report_repository.dart
// Interface à implémenter dans FirebaseReportRepository
// Injectée dans :
// lib/shared/store/report_store.dart ligne 26
//   ReportRepository _repository = MockReportRepository.instance;
//   → À remplacer par : FirebaseReportRepository.instance
```

---

*Fin de l'audit — document généré le 2026-06-23*
