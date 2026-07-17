// lib/shared/utils/report_search.dart
//
// Logique de recherche unifiée — réutilisée telle quelle par Mes cas
// signalés, Mes prises en charge, et la recherche globale Accueil -> Carte.
// Un seul et même critère de correspondance partout : seul le périmètre de
// cas interrogés change selon l'endroit d'appel.

import '../../features/home/models/home_report_model.dart';

// Correspondance insensible à la casse, partielle, sur le code
// identifiant, le libellé de catégorie, le lieu et la description. Se
// COMBINE avec les filtres existants (ET) : appeler après eux, jamais à
// leur place.
bool matchesReportSearch(HomeReportModel report, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return report.reference.toLowerCase().contains(q) ||
      report.category.label.toLowerCase().contains(q) ||
      report.location.toLowerCase().contains(q) ||
      report.description.toLowerCase().contains(q);
}
