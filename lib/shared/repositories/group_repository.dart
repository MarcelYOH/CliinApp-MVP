// lib/shared/repositories/group_repository.dart

import '../../features/groups/models/group_model.dart';

abstract class GroupRepository {
  Future<List<GroupModel>> fetchAllGroups();
  Future<GroupModel?> fetchGroupById(String id);
  Future<List<GroupMemberModel>> fetchMembers(String groupId);

  // Sympathisants du groupe éligibles à une promotion administrateur (donc
  // hors administrateurs déjà en poste). Alimente la recherche de la sheet
  // "Ajouter un administrateur" — mock aujourd'hui (pas d'annuaire
  // multi-utilisateurs réel dans l'app), remplacé par un vrai annuaire
  // Firebase plus tard sans toucher aux widgets qui l'utilisent.
  Future<List<GroupMemberModel>> fetchSympathisants(String groupId);

  Future<GroupModel> addGroup(GroupModel group, GroupMemberModel createur);
  Future<GroupModel> updateGroup(GroupModel group);
  Future<void> deleteGroup(String groupId);

  Future<void> addMember(String groupId, GroupMemberModel member);
  Future<void> removeMember(String groupId, String memberId);
}
