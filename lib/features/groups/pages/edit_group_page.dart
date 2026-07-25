// lib/features/groups/pages/edit_group_page.dart
// Modification d'un groupe existant — délègue à GroupFormPage (correction 5 :
// formulaire partagé création/modification, voir group_form_page.dart).
// Accessible uniquement depuis les Paramètres du groupe, réservé aux
// administrateurs.

import 'package:flutter/material.dart';
import 'group_form_page.dart';

class EditGroupPage extends StatelessWidget {
  final String groupId;

  const EditGroupPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) => GroupFormPage(groupId: groupId);
}
