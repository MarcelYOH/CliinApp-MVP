# Point de vigilance — Responsive design (adaptation multi-écrans)

**Statut :** À auditer une fois les fonctionnalités principales stabilisées — pas urgent
**Priorité :** Mineure / qualité
**Date de rédaction :** 2026-06-26

---

## Contexte

CliinApp est testée sur un appareil d'entrée de gamme (itel P651W), ce qui
est représentatif d'une partie réelle du parc d'appareils en Côte d'Ivoire.
Cependant, les utilisateurs finaux utiliseront des téléphones très variés :
tailles d'écran différentes, résolutions différentes, proportions
(largeur/hauteur) différentes, et marques diverses (Samsung, Tecno,
Infinix, itel, etc.).

## Risque si non traité

Sans vérification du responsive, l'interface conçue et validée sur
l'appareil de test pourrait :
- déborder de l'écran sur un téléphone à petit écran,
- laisser des espaces vides disproportionnés sur un grand écran,
- provoquer un chevauchement ou une coupure de texte,
- rendre certains boutons trop petits ou mal positionnés pour être touchés
  facilement.

Ceci concerne en particulier les composants à largeur fixe ou aux
dimensions codées en dur (ex : largeur des cartes de signalement dans le
scroll horizontal "À proximité").

## Exigence

Avant le lancement de la phase pilote, tester l'application sur au moins
2 à 3 tailles d'écran différentes (par exemple : un petit écran, un écran
de taille moyenne comme l'appareil de test actuel, et un grand écran),
afin de vérifier que :
- aucun élément ne déborde ou n'est coupé,
- le texte reste lisible et correctement positionné,
- les zones tactiles (boutons, chips) restent confortables à utiliser sur
  les petits écrans.

## Hors périmètre de ce point

- L'orientation horizontale (paysage) n'est pas un objectif prioritaire
  pour une application principalement utilisée en usage rapide, debout,
  en orientation verticale — à confirmer si un besoin spécifique émerge.
- Le support tablette n'est pas un objectif identifié à ce stade.

## Quand traiter ceci

Une fois les fonctionnalités principales du MVP stabilisées (signalement,
prise en charge, suivi), avant le lancement de la phase pilote — pas à
chaque modification individuelle, pour éviter de fragmenter l'effort.
