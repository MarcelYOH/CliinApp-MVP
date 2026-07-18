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
      required String description,
      required GroupType type,
      required String zone,
      required bool estActif,
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
        description: description,
        type: type,
        zone: zone,
        badges: calculateGroupBadges(
          casSignalesCount: casSignales,
          casTraitesCount: casTraites,
          actionsCount: actions,
        ),
        estActif: estActif,
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
        description:
            'Collectif de riverains mobilisé pour la propreté de Riviera 2 : '
            'nettoyage hebdomadaire des rues et sensibilisation au tri sélectif.',
        type: GroupType.benevoles,
        zone: 'Riviera 2, Cocody',
        estActif: true,
        casSignales: 250,
        casTraites: 120,
        actions: 25,
        sympathisants: 340,
        createdAt: now.subtract(const Duration(days: 420)),
      ),
      group(
        id: 'grp_green_city',
        nom: 'Green City',
        description:
            'Association pour un cadre de vie plus vert au Plateau : '
            'reboisement urbain, compostage communautaire et propreté des espaces publics.',
        type: GroupType.association,
        zone: 'Plateau, Abidjan',
        estActif: true,
        casSignales: 220,
        casTraites: 110,
        actions: 22,
        sympathisants: 280,
        createdAt: now.subtract(const Duration(days: 380)),
      ),
      group(
        id: 'grp_eco_jeunes',
        nom: 'Eco Jeunes',
        description:
            'Mobilisation des jeunes de Yopougon autour des enjeux environnementaux '
            'locaux : ateliers de sensibilisation et actions terrain.',
        type: GroupType.benevoles,
        zone: 'Yopougon, Abidjan',
        estActif: true,
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
        estActif: true,
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
        estActif: false,
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
        estActif: false,
        casSignales: 1,
        casTraites: 0,
        actions: 0,
        sympathisants: 6,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);

    _members.addAll({
      'grp_clean_riviera': const [
        GroupMemberModel(
            id: 'mbr_cr_1',
            nom: 'Aïcha Koné',
            role: 'Présidente',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_cr_2',
            nom: 'Yannick Bamba',
            role: 'Trésorier',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_cr_3',
            nom: 'Fatou Diarra',
            role: 'Secrétaire générale',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_cr_4',
            nom: 'Serge Kouadio',
            role: 'Chargé des opérations',
            estBureauExecutif: true),
      ],
      'grp_green_city': const [
        GroupMemberModel(
            id: 'mbr_gc_1',
            nom: 'Marc Adou',
            role: 'Président',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_gc_2',
            nom: 'Diane Yao',
            role: 'Vice-présidente',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_gc_3',
            nom: 'Paul N\'Guessan',
            estAdmin: true,
            estBureauExecutif: false),
      ],
      'grp_eco_jeunes': const [
        GroupMemberModel(
            id: 'mbr_ej_1',
            nom: 'Grace Tanoh',
            role: 'Présidente',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_ej_2',
            nom: 'Ibrahim Traoré',
            role: 'Trésorier',
            estBureauExecutif: true),
        GroupMemberModel(
            id: 'mbr_ej_3',
            nom: 'Nadège Assi',
            role: 'Chargée des opérations',
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
