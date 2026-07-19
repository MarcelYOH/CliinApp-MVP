// lib/features/groups/widgets/group_settings_sheet.dart
// Sheet "Paramètres du groupe" — réservé aux administrateurs, 2 options
// seulement. La navigation/suppression effective est gérée par l'appelant
// (group_profile_page.dart) à partir de l'action retournée.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

enum GroupSettingsAction { edit, delete }

Future<GroupSettingsAction?> showGroupSettingsSheet(BuildContext context) {
  return showModalBottomSheet<GroupSettingsAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GroupSettingsSheet(),
  );
}

class _GroupSettingsSheet extends StatelessWidget {
  const _GroupSettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(CliinAppConstants.radiusLarge),
          topRight: Radius.circular(CliinAppConstants.radiusLarge),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: CliinAppConstants.pagePadding),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: CliinAppConstants.spacingM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CliinAppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CliinAppConstants.spacingL),
            Text('Paramètres du groupe',
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 16)),
            const SizedBox(height: CliinAppConstants.spacingM),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined,
                  color: CliinAppColors.primary),
              title: Text('Modifier les informations du groupe',
                  style: CliinAppTextStyles.bodyMedium
                      .copyWith(color: CliinAppColors.textDark)),
              onTap: () => Navigator.pop(context, GroupSettingsAction.edit),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline_rounded,
                  color: CliinAppColors.alertRed),
              title: Text('Supprimer le groupe',
                  style: CliinAppTextStyles.bodyMedium
                      .copyWith(color: CliinAppColors.alertRed)),
              onTap: () => Navigator.pop(context, GroupSettingsAction.delete),
            ),
            const SizedBox(height: CliinAppConstants.spacingM),
          ],
        ),
      ),
    );
  }
}
