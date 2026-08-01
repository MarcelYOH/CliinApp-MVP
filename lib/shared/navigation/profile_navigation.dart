// lib/shared/navigation/profile_navigation.dart
// Navigation partagée vers le profil d'un auteur/intervenant (Correction 2)
// — un cas signalé/pris en charge au nom d'un groupe mène au profil du
// groupe (toujours public), sinon au profil individuel (soumis au réglage
// de confidentialité AuthStore.isProfilePublic). Point d'entrée unique :
// ne jamais réimplémenter cette logique ailleurs.

import 'package:flutter/material.dart';
import '../../features/actions/models/action_model.dart';
import '../../features/groups/pages/group_profile_page.dart';
import '../../features/home/models/home_report_model.dart';
import '../../features/profile/pages/public_profile_page.dart';
import '../store/auth_store.dart';
import '../store/group_store.dart';
import 'fast_page_route.dart';

void _openIndividualProfile(
  BuildContext context, {
  required String userId,
  required String displayName,
}) {
  if (!AuthStore.instance.isProfilePublic(userId)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cette personne n\'a pas autorisé l\'affichage public de son profil.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }
  Navigator.push(
    context,
    fastFadeRoute<void>(
      PublicProfilePage(userId: userId, displayName: displayName),
    ),
  );
}

/// Ouvre le profil de l'auteur d'un signalement — ne rien faire si
/// l'auteur est anonyme ou inconnu (l'appelant doit déjà filtrer ce cas
/// pour ne pas rendre le nom cliquable, ce guard n'est qu'une sécurité).
void openAuthorProfile(BuildContext context, HomeReportModel report) {
  if (report.isAnonyme || report.signaleParId == null) return;
  if (report.groupId != null) {
    Navigator.push(
      context,
      fastFadeRoute<void>(GroupProfilePage(groupId: report.groupId!)),
    );
    return;
  }
  _openIndividualProfile(
    context,
    userId: report.signaleParId!,
    displayName: report.signalePar ?? 'Utilisateur',
  );
}

/// Ouvre le profil de l'intervenant qui a pris en charge un cas — profil de
/// groupe si l'intervention a été faite au nom d'un groupe, sinon profil
/// individuel. Ne fait rien si l'intervenant est anonyme (Correction 5 —
/// l'appelant doit déjà filtrer ce cas pour ne pas rendre le nom cliquable,
/// ce guard n'est qu'une sécurité).
void openIntervenantProfile(BuildContext context, HomeReportModel report) {
  final intervenant = report.intervenant;
  if (intervenant == null) return;
  if (intervenant.isAnonyme) return;
  if (intervenant.groupName != null) {
    final group = GroupStore.instance.groupByName(intervenant.groupName!);
    if (group == null) return;
    Navigator.push(
      context,
      fastFadeRoute<void>(GroupProfilePage(groupId: group.id)),
    );
    return;
  }
  _openIndividualProfile(
    context,
    userId: intervenant.id,
    displayName: intervenant.name,
  );
}

/// Ouvre le profil de l'organisateur d'une action terrain — profil de
/// groupe si organisée au nom d'un groupe, sinon profil individuel. Ne fait
/// rien si l'organisateur est anonyme (l'appelant doit déjà filtrer ce cas
/// pour ne pas rendre le bloc "Organisé par" cliquable, ce guard n'est
/// qu'une sécurité).
void openActionOrganisateurProfile(BuildContext context, ActionModel action) {
  if (action.isAnonyme) return;
  if (action.organisateurEstGroupe) {
    Navigator.push(
      context,
      fastFadeRoute<void>(GroupProfilePage(groupId: action.organisateurId)),
    );
    return;
  }
  _openIndividualProfile(
    context,
    userId: action.organisateurId,
    displayName: action.organisateurNom,
  );
}
