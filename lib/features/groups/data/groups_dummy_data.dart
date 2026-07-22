// lib/features/groups/data/groups_dummy_data.dart

import '../models/group_model.dart';

/// Cartes factices "accroche" — page d'accueil du module Groupes (3
/// sections : "Groupes actifs", "Mes groupes", "Découvrir") et pages
/// dédiées correspondantes. Même principe que HomeDummyData côté
/// signalements : ces groupes n'existent PAS dans GroupStore, ne sont
/// JAMAIS suivables/cliquables (voir GroupCard, qui intercepte tout id
/// 'demo_*' pour afficher un message explicatif plutôt qu'une navigation
/// ou une action réelle) — aucun risque d'interférence avec une vraie
/// donnée créée par un utilisateur (règle 3.5).
///
/// Bascule totale, jamais un remplacement carte par carte : chaque section
/// affiche EXACTEMENT ces 3 cartes tant qu'aucune vraie donnée équivalente
/// n'existe pour elle, puis elles disparaissent TOUTES ensemble dès qu'au
/// moins une vraie donnée existe.
class GroupsDummyData {
  GroupsDummyData._();

  static final DateTime _now = DateTime.now();

  static GroupModel _entry({
    required String id,
    required String nom,
    required String photoPath,
    required String bannerPath,
    required String description,
    required GroupType type,
    required String zone,
  }) {
    return GroupModel(
      id: id,
      nom: nom,
      photoPath: photoPath,
      bannerPath: bannerPath,
      description: description,
      type: type,
      zone: zone,
      // 3 badges pour une vitrine convaincante quelle que soit la section
      // qui les affiche — le nombre de badges n'a pas d'incidence sur
      // "Mes groupes"/"Découvrir" (4.1/5.1) et correspond exactement à la
      // règle de la vitrine "Groupes actifs" (1.1).
      badges: const ['engage', 'impact', 'officiel'],
      createdAt: _now,
      createurId: 'demo_createur',
      casSignalesCount: 220,
      casTraitesCount: 110,
      actionsCount: 22,
      sympathisantsCount: 300,
    );
  }

  // [section] distingue uniquement les id (ex: 'actifs', 'mesgroupes',
  // 'decouvrir') pour que les 3 cartes factices d'une section n'entrent
  // jamais en conflit avec celles d'une autre section affichée par
  // ailleurs dans la même page.
  static List<GroupModel> forSection(String section) => [
        _entry(
          id: 'demo_${section}_1',
          nom: 'Clean Riviera',
          photoPath: 'assets/images/cleanriviera.png',
          bannerPath: 'assets/images/group_banner1.jpg',
          description:
              'Collectif de riverains mobilisé pour la propreté de '
              'Riviera 2 : nettoyage hebdomadaire et sensibilisation au '
              'tri sélectif.',
          type: GroupType.benevoles,
          zone: 'Riviera 2, Cocody',
        ),
        _entry(
          id: 'demo_${section}_2',
          nom: 'Green City',
          photoPath: 'assets/images/greencity.png',
          bannerPath: 'assets/images/group_banner2.jpg',
          description:
              'Association pour un cadre de vie plus vert au Plateau : '
              'reboisement urbain et compostage communautaire.',
          type: GroupType.association,
          zone: 'Plateau, Abidjan',
        ),
        _entry(
          id: 'demo_${section}_3',
          nom: 'Eco Jeunes',
          photoPath: 'assets/images/ecojeunes.png',
          bannerPath: 'assets/images/group_banner3.jpg',
          description:
              'Mobilisation des jeunes de Yopougon autour des enjeux '
              'environnementaux locaux.',
          type: GroupType.benevoles,
          zone: 'Yopougon, Abidjan',
        ),
      ];

  // Préfixe distinctif — utilisé partout où une carte factice doit être
  // traitée différemment d'un vrai groupe (pas de navigation, pas de
  // suivre/ne plus suivre réel).
  static bool isFakeGroup(GroupModel g) => g.id.startsWith('demo_');
}
