# CliinApp — Périmètre complet du MVP

## Modules implémentés dans le code et fonctionnels

- **Signalement** : création (photo, GPS, catégorie, provenance, urgence), cycle complet (Disponible → En cours → Traité), preuve avant/après, vérification GPS anti-fraude (50m), flow de prise en charge (individu ou groupe, contact WhatsApp conditionnel).
- **Carte de signalement** : 3 états (Disponible/En cours/Traité), bouton Suivre, confirmation de résolution, contestation, zoom photo, page Détails publique (description complète, commentaires factices, zone d'action).
- **Page d'accueil** : sections "À proximité" et "Signalements récents", bannière d'alerte, bannière action.
- **Carte exploratoire** : filtres catégorie + statut, recherche par position, bottom sheet des résultats.
- **Authentification** (en cours de finalisation) : inscription par téléphone ou email (OTP 6 chiffres), gestion des erreurs, finalisation du profil (photo facultative, nom, zone), session persistée, mode exploration sans connexion. Bug de navigation (étape 3 → fermeture flow) en cours de correction.
- **Design System** : couleurs, typographies (Poppins/Inter en assets), constantes, composants réutilisables.
- **Architecture** : feature-first, Repository pattern (Mock → Firebase plus tard), ReportStore + AuthStore (ChangeNotifier), UserLocationService.

## Modules conçus et validés (design artefacts prêts), PAS ENCORE IMPLÉMENTÉS DANS LE CODE

- **Module Profil** : profil privé (stats, menu), profil public, Mes cas signalés, Mes prises en charge (filtres En cours/Traités/Abandonnés/Rejetés, indicateur délai restant), Page Détail Intervenant (4 états dynamiques).

## Modules restant à implémenter dans le MVP

### 1. Profil utilisateur complet
Prochaine étape après finalisation de l'authentification. Inclut :
- Page Profil (privée + publique).
- Mes cas signalés (liste filtrée).
- Mes prises en charge (liste filtrée, avec délai restant).
- Page Détail Intervenant (4 états : En cours/Traité/Abandonné/Rejeté).
- Cas suivis.

### 2. Module Groupes
- Création et gestion d'un groupe.
- Page du groupe : stats d'impact, membres, publications/activités.
- Exploration des groupes.
- Badges progressifs (Pro / Impact / Top Groupe).
- Attribution des signalements "au nom du groupe".

### 3. Module Actions communautaires
- Page dédiée aux actions terrain (nettoyage, sensibilisation, etc.).
- Création d'une publication d'action.
- Consultation des actions publiées.
- Lien avec les stats d'impact du groupe organisateur.

### 4. Module Notifications
- Notifications pour : cas pris en charge, preuve soumise, contestation, cas traité, nouveau commentaire.

### 5. Tableau de bord Vue d'ensemble (version MVP généraliste)
- Dashboard statistique pour partenaires (entreprises de collecte, municipalités, ONG, associations).
- Vue d'ensemble : cas signalés/pris en charge/traités, types de problèmes fréquents, zones impactées, activité des groupes.

## Ce qui sera branché AVANT le lancement du pilote à San-Pedro

Le MVP sera une application pleinement fonctionnelle, connectée à de vrais services :
- **Firebase** : authentification réelle, base de données Firestore, stockage des photos, persistance hors ligne.
- **Google Maps** : carte interactive réelle.
- **Notifications push** : Firebase Cloud Messaging.
- Les données fictives (Mock) sont uniquement utilisées pendant le développement en cours — elles seront entièrement remplacées par le backend réel AVANT le lancement pilote, pas après.

## Ce qui est prévu APRÈS la phase pilote (extensions futures)

- Tableau de bord avancé personnalisé par acteur.
- Marketplace économie circulaire.
- Plateforme e-learning.
- Modération automatisée.
- Déploiement multi-villes.
