// lib/shared/utils/report_search.dart
//
// Logique de recherche unifiée — réutilisée telle quelle par Mes cas
// signalés, Mes prises en charge, et la recherche globale Accueil -> Carte.
// Un seul et même critère de correspondance partout : seul le périmètre de
// cas interrogés change selon l'endroit d'appel.

import '../../features/home/models/home_report_model.dart';
import 'search_helper.dart';

// Correspondance insensible à la casse ET aux accents, partielle, sur le
// titre, la description, le lieu (adresse) et le code identifiant
// (reportCode) — via la fonction générique unique matchesSearch (Correction
// 6). Se COMBINE avec les filtres existants (ET) : appeler après eux,
// jamais à leur place.
bool matchesReportSearch(HomeReportModel report, String query) {
  return matchesSearch(query, [
    report.title,
    report.description,
    report.location,
    report.reference,
  ]);
}
