// lib/shared/data/mock_groups.dart
// Groupes fictifs dont l'utilisateur courant est membre — en attendant le
// module Groupes. Utilisé pour la prise en charge (take_charge_flow) et pour
// l'attribution "Au nom d'un groupe" à la publication d'un cas.

const List<String> kMockUserGroups = [
  'Clean Riviera',
  'Green City',
  'Eco Jeunes',
];

String mockGroupId(String groupName) {
  return groupName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
