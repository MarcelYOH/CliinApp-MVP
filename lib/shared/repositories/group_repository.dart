// lib/shared/repositories/group_repository.dart

import '../../features/groups/models/group_model.dart';

abstract class GroupRepository {
  Future<List<GroupModel>> fetchAllGroups();
  Future<GroupModel?> fetchGroupById(String id);
  Future<List<GroupMemberModel>> fetchMembers(String groupId);

  Future<GroupModel> addGroup(GroupModel group, GroupMemberModel createur);
  Future<GroupModel> updateGroup(GroupModel group);
  Future<void> deleteGroup(String groupId);

  Future<void> addMember(String groupId, GroupMemberModel member);
  Future<void> removeMember(String groupId, String memberId);
}
