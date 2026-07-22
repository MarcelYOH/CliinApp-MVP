// lib/shared/repositories/mock_group_repository.dart

import 'dart:math';
import '../../features/groups/models/group_model.dart';
import 'group_repository.dart';

class MockGroupRepository implements GroupRepository {
  MockGroupRepository._() {
    _seed();
  }
  static final MockGroupRepository instance = MockGroupRepository._();

  final List<GroupModel> _groups = <GroupModel>[];
  final Map<String, List<GroupMemberModel>> _members = {};

  String _generateGroupId() {
    final rand = Random();
    return 'grp_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(9999)}';
  }

  void _seed() {
    GroupModel group({
      required String id,
      required String nom,
      String? photoPath,
      String? bannerPath,
      required String description,
      required GroupType type,
      required String zone,
      double? latitude,
      double? longitude,
      required int casSignales,
      required int casTraites,
      required int actions,
      required int sympathisants,
      required DateTime createdAt,
    }) {
      return GroupModel(
        id: id,
        nom: nom,
        photoPath: photoPath,
        bannerPath: bannerPath,
        description: description,
        type: type,
        zone: zone,
        latitude: latitude,
        longitude: longitude,
        badges: calculateGroupBadges(
          casSignalesCount: casSignales,
          casTraitesCount: casTraites,
          actionsCount: actions,
        ),
        createdAt: createdAt,
        createurId: 'seed_$id',
        casSignalesCount: casSignales,
        casTraitesCount: casTraites,
        actionsCount: actions,
        sympathisantsCount: sympathisants,
      );
    }

    final now = DateTime.now();

    _groups.addAll([
      group(
        id: 'grp_clean_riviera',
        nom: 'Clean Riviera',
        // Logo (cercle) et bannière (rectangle) — images dédiées déjà
        // présentes dans les assets du module Groupes.
        photoPath: 'assets/images/cleanriviera.png',
        bannerPath: 'assets/images/group_banner1.jpg',
        description:
            'Collectif de riverains mobilisé pour la propreté de Riviera 2 : '
            'nettoyage hebdomadaire des rues et sensibilisation au tri sélectif.',
        type: GroupType.benevoles,
        zone: 'Riviera 2, Cocody',
        latitude: 5.3700,
        longitude: -3.9800,
        casSignales: 250,
        casTraites: 120,
        actions: 25,
        sympathisants: 340,
        createdAt: now.subtract(const Duration(days: 420)),
      ),
      group(
        id: 'grp_green_city',
        nom: 'Green City',
        photoPath: 'assets/images/greencity.png',
        bannerPath: 'assets/images/group_banner2.jpg',
        description:
            'Association pour un cadre de vie plus vert au Plateau : '
            'reboisement urbain, compostage communautaire et propreté des espaces publics.',
        type: GroupType.association,
        zone: 'Plateau, Abidjan',
        latitude: 5.3197,
        longitude: -4.0201,
        casSignales: 220,
        casTraites: 110,
        actions: 22,
        sympathisants: 280,
        createdAt: now.subtract(const Duration(days: 380)),
      ),
      group(
        id: 'grp_eco_jeunes',
        nom: 'Eco Jeunes',
        photoPath: 'assets/images/ecojeunes.png',
        bannerPath: 'assets/images/group_banner3.jpg',
        description:
            'Mobilisation des jeunes de Yopougon autour des enjeux environnementaux '
            'locaux : ateliers de sensibilisation et actions terrain.',
        type: GroupType.benevoles,
        zone: 'Yopougon, Abidjan',
        latitude: 5.3450,
        longitude: -4.0854,
        casSignales: 210,
        casTraites: 105,
        actions: 21,
        sympathisants: 310,
        createdAt: now.subtract(const Duration(days: 350)),
      ),
      group(
        id: 'grp_quartier_propre',
        nom: 'Quartier Propre',
        description:
            'Groupe de résidents de Marcory engagés dans la salubrité de leur '
            'quartier au quotidien.',
        type: GroupType.benevoles,
        zone: 'Marcory, Abidjan',
        latitude: 5.2846,
        longitude: -3.9836,
        casSignales: 65,
        casTraites: 38,
        actions: 7,
        sympathisants: 95,
        createdAt: now.subtract(const Duration(days: 150)),
      ),
      group(
        id: 'grp_benevoles_solidaires',
        nom: 'Bénévoles Solidaires',
        description:
            'Petit collectif de bénévoles de Koumassi qui débute ses actions de '
            'salubrité de proximité.',
        type: GroupType.benevoles,
        zone: 'Koumassi, Abidjan',
        latitude: 5.2926,
        longitude: -3.9435,
        casSignales: 18,
        casTraites: 7,
        actions: 1,
        sympathisants: 40,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      group(
        id: 'grp_nouveau_collectif',
        nom: 'Nouveau Collectif',
        description:
            'Collectif tout juste créé à Cocody, encore en phase de démarrage.',
        type: GroupType.autre,
        zone: 'Cocody, Abidjan',
        latitude: 5.3599,
        longitude: -3.9646,
        casSignales: 1,
        casTraites: 0,
        actions: 0,
        sympathisants: 6,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);

    _members.addAll({
      // Groupes de démo "seed_*" (vrais groupes suivables/cliquables,
      // distincts des cartes factices non-interactives de
      // GroupsDummyData) : exactement 5 avatars d'équipe dirigeante, tous
      // avatar.png (donnée factice — répétition à l'identique acceptée).
      // Logique pour les vraies données futures (voir
      // GroupStore.leaderAvatars) : le 1er membre
      // correspond au créateur/président du groupe, les suivants aux
      // membres du bureau exécutif ajoutés depuis l'Espace gestion, dans
      // leur ordre d'ajout, jusqu'à 5 max affichés (mécanisme "+N" au-delà).
      'grp_clean_riviera': const [
        GroupMemberModel(
            id: 'mbr_cr_1',
            nom: 'Aïcha Koné',
            avatarPath: 'assets/images/avatar.png',
            role: 'Présidente',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_cr_2',
            nom: 'Yannick Bamba',
            avatarPath: 'assets/images/avatar.png',
            role: 'Trésorier',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_cr_3',
            nom: 'Fatou Diarra',
            avatarPath: 'assets/images/avatar.png',
            role: 'Secrétaire générale',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_cr_4',
            nom: 'Serge Kouadio',
            avatarPath: 'assets/images/avatar.png',
            role: 'Chargé des opérations',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_cr_5',
            nom: 'Nina Assouan',
            avatarPath: 'assets/images/avatar.png',
            role: 'Chargée de communication',
            estBureauExecutif: true),
      ],
      'grp_green_city': const [
        GroupMemberModel(
            id: 'mbr_gc_1',
            nom: 'Marc Adou',
            avatarPath: 'assets/images/avatar.png',
            role: 'Président',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_gc_2',
            nom: 'Diane Yao',
            avatarPath: 'assets/images/avatar.png',
            role: 'Vice-présidente',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_gc_3',
            nom: 'Paul N\'Guessan',
            avatarPath: 'assets/images/avatar.png',
            role: 'Secrétaire général',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_gc_4',
            nom: 'Sarah Kouamé',
            avatarPath: 'assets/images/avatar.png',
            role: 'Trésorière',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_gc_5',
            nom: 'Éric Bailly',
            avatarPath: 'assets/images/avatar.png',
            role: 'Chargé des opérations',
            estBureauExecutif: true),
      ],
      'grp_eco_jeunes': const [
        GroupMemberModel(
            id: 'mbr_ej_1',
            nom: 'Grace Tanoh',
            avatarPath: 'assets/images/avatar.png',
            role: 'Présidente',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_ej_2',
            nom: 'Ibrahim Traoré',
            avatarPath: 'assets/images/avatar.png',
            role: 'Trésorier',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_ej_3',
            nom: 'Nadège Assi',
            avatarPath: 'assets/images/avatar.png',
            role: 'Chargée des opérations',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_ej_4',
            nom: 'Junior Kacou',
            avatarPath: 'assets/images/avatar.png',
            role: 'Secrétaire général',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_ej_5',
            nom: 'Aminata Cissé',
            avatarPath: 'assets/images/avatar.png',
            role: 'Chargée de communication',
            estBureauExecutif: true),
      ],
      'grp_quartier_propre': const [
        GroupMemberModel(
            id: 'mbr_qp_1',
            nom: 'Christian Boa',
            role: 'Président',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_qp_2',
            nom: 'Aya Brou',
            estAdmin: true,
            estBureauExecutif: false),
      ],
      'grp_benevoles_solidaires': const [
        GroupMemberModel(
            id: 'mbr_bs_1',
            nom: 'Kader Ouattara',
            role: 'Président',
            estBureauExecutif: true),
      ],
      'grp_nouveau_collectif': const [
        GroupMemberModel(
            id: 'mbr_nc_1',
            nom: 'Ella Kacou',
            role: 'Présidente',
            estBureauExecutif: true),
      ],
    });
  }

  @override
  Future<List<GroupModel>> fetchAllGroups() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.of(_groups);
  }

  @override
  Future<GroupModel?> fetchGroupById(String id) async {
    await Future.delayed(const Duration(milliseconds: 60));
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<GroupMemberModel>> fetchMembers(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 60));
    return List.of(_members[groupId] ?? const []);
  }

  // Pool factice de membres (annuaire multi-utilisateurs réel
  // inexistant dans ce mock — l'app ne connaît qu'un seul utilisateur
  // courant) — permet de faire fonctionner la recherche "Ajouter un
  // administrateur" (Lot 3) en attendant un vrai annuaire Firebase.
  static const List<String> _sympathisantNames = [
    'Aline Kouassi',
    'Bakary Sanogo',
    'Chantal Yao',
    'David Kra',
    'Estelle N\'Dri',
    'Franck Ehouman',
  ];

  @override
  Future<List<GroupMemberModel>> fetchSympathisants(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final existingIds =
        (_members[groupId] ?? const []).map((m) => m.id).toSet();
    return [
      for (var i = 0; i < _sympathisantNames.length; i++)
        GroupMemberModel(
          id: 'symp_${groupId}_$i',
          nom: _sympathisantNames[i],
          estAdmin: false,
        ),
    ].where((m) => !existingIds.contains(m.id)).toList();
  }

  @override
  Future<GroupModel> addGroup(GroupModel group, GroupMemberModel createur) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final enriched = group.id.isEmpty
        ? group.copyWith(id: _generateGroupId())
        : group;
    _groups.insert(0, enriched);
    _members[enriched.id] = [createur];
    return enriched;
  }

  @override
  Future<GroupModel> updateGroup(GroupModel group) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
    }
    return group;
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _groups.removeWhere((g) => g.id == groupId);
    _members.remove(groupId);
  }

  @override
  Future<void> addMember(String groupId, GroupMemberModel member) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _members.putIfAbsent(groupId, () => []);
    list.removeWhere((m) => m.id == member.id);
    list.add(member);
  }

  @override
  Future<void> removeMember(String groupId, String memberId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _members[groupId]?.removeWhere((m) => m.id == memberId);
  }
}
