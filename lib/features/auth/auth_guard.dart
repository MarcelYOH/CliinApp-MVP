// lib/features/auth/auth_guard.dart
// Fonction utilitaire — vérifie si l'utilisateur est authentifié.
// Si non, affiche la gate sheet. Retourne true si l'auth est établie.

import 'package:flutter/material.dart';
import '../../shared/store/auth_store.dart';
import 'pages/auth_gate_sheet.dart';

Future<bool> requireAuth(BuildContext context) async {
  if (AuthStore.instance.isAuthenticated) return true;
  return showAuthGateSheet(context);
}
