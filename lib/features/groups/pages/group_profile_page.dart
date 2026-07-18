// lib/features/groups/pages/group_profile_page.dart
//
// Placeholder — le profil complet du groupe (À propos, Notre équipe, Notre
// impact, onglets, Espace gestion...) sera construit au Lot 3. Ce squelette
// minimal existe uniquement pour que la navigation du Lot 1 (GroupCard,
// création d'un groupe) ait une destination réelle en attendant.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/store/group_store.dart';

class GroupProfilePage extends StatelessWidget {
  final String groupId;

  const GroupProfilePage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final group = GroupStore.instance.groupById(groupId);

    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                CliinAppConstants.pagePadding,
                MediaQuery.of(context).padding.top + 12,
                CliinAppConstants.pagePadding,
                12,
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_rounded,
                    color: CliinAppColors.textDark, size: 24),
              ),
            ),
            Expanded(
              child: group == null
                  ? Center(
                      child: Text('Groupe introuvable',
                          style: CliinAppTextStyles.bodyMedium),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: CliinAppConstants.pagePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.nom,
                              style: CliinAppTextStyles.headingLarge),
                          const SizedBox(height: CliinAppConstants.spacingS),
                          Text(group.zone,
                              style: CliinAppTextStyles.bodySmall),
                          const SizedBox(height: CliinAppConstants.spacingL),
                          Text('Qui sommes-nous',
                              style: CliinAppTextStyles.headingSmall),
                          const SizedBox(height: CliinAppConstants.spacingXS),
                          Text(group.description,
                              style: CliinAppTextStyles.bodyMedium),
                          const SizedBox(height: CliinAppConstants.spacingXL),
                          Text(
                            'Le profil complet du groupe (équipe, impact, '
                            'besoins...) arrive au Lot 3.',
                            style: CliinAppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
