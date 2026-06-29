# Exigence — Persistance hors ligne (mode offline)

**Statut :** À implémenter lors de l'intégration backend (Firebase) — pas avant
**Priorité :** Importante
**Date de rédaction :** 2026-06-26

---

## Contexte

CliinApp est utilisée sur le terrain, dans des conditions de couverture réseau
variables en Côte d'Ivoire (zones urbaines denses, zones moins couvertes,
intérieur de bâtiments, déplacements en taxi/véhicule). L'architecture
actuelle (MVP, données factices en mémoire via `MockReportRepository`) ne
gère pas la perte de connexion : c'est une limitation connue et acceptée à
ce stade, car ces données seront entièrement remplacées lors du passage à
Firebase.

## Risque si non traité

Sans persistance hors ligne, un utilisateur qui perd sa connexion pendant la
création d'un signalement (photo, catégorie, provenance, urgence) risque de
**perdre entièrement son signalement**, sans pouvoir le récupérer — pas
seulement un désagrément visuel, mais une perte de donnée et de l'effort de
l'utilisateur.

## Exigence

Lors du branchement de Firebase (remplacement de `MockReportRepository` par
`FirebaseReportRepository`, déjà prévu dans l'architecture actuelle via
l'interface `ReportRepository`), activer la **persistance hors ligne native
de Firestore** :

- Un signalement créé sans connexion doit être accepté normalement par
  l'application (aucune différence d'expérience pour l'utilisateur).
- Il doit être mis en attente automatiquement sur l'appareil.
- Il doit être envoyé automatiquement dès que la connexion revient, sans
  action supplémentaire de l'utilisateur.
- Le comportement attendu est celui fourni nativement par Firestore
  (`Settings.persistenceEnabled` / cache local) — ne pas développer de
  mécanisme de file d'attente manuel si la fonctionnalité native suffit.

## Hors périmètre de cette exigence

- La consultation hors ligne des signalements d'autrui (flux "à proximité",
  carte) n'est pas couverte ici — à évaluer séparément si jugée nécessaire.
- La prise en charge et la soumission de preuve hors ligne suivent la même
  logique que la création, à vérifier au moment de l'implémentation.

## Point lié (séparé, priorité moindre)

Les polices (Poppins, Inter) sont actuellement chargées via le package
`google_fonts` avec téléchargement à la première utilisation. En conditions
de connectivité faible, ceci peut retarder l'affichage de la police prévue
au tout premier lancement. Recommandation : intégrer les fichiers de police
directement dans les assets de l'application avant la publication pilote,
pour un rendu visuel correct dès le premier lancement, même hors ligne.
Cette tâche est indépendante de la persistance hors ligne des données et
peut être traitée à tout moment, sans attendre Firebase.

## Quand traiter ceci

À intégrer dans le plan de travail du développeur backend senior, dès la
phase de branchement Firebase — avant le lancement de la phase pilote.
