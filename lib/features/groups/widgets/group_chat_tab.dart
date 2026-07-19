// lib/features/groups/widgets/group_chat_tab.dart
// Onglet "Chat" du profil groupe — "Bientôt disponible", aucune messagerie
// réelle dans ce lot.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

class GroupChatTab extends StatelessWidget {
  const GroupChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CliinAppConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                color: CliinAppColors.textSecondary, size: 44),
            const SizedBox(height: CliinAppConstants.spacingM),
            Text('Chat de groupe', style: CliinAppTextStyles.headingSmall),
            const SizedBox(height: 6),
            Text(
              'La messagerie de groupe sera disponible dans la prochaine '
              'version de CliinApp.',
              style: CliinAppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
