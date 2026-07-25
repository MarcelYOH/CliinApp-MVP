// lib/features/groups/pages/create_group_page.dart
// Création d'un groupe — délègue à GroupFormPage (correction 5 : formulaire
// partagé création/modification, voir group_form_page.dart).

import 'package:flutter/material.dart';
import 'group_form_page.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) => const GroupFormPage();
}
