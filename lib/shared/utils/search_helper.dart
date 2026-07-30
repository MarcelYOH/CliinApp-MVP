// lib/shared/utils/search_helper.dart
//
// Fonction de recherche textuelle UNIQUE et réutilisable — toute barre de
// recherche de l'application (Carte, Groupes, Actions, Mes cas signalés,
// Mes prises en charge, et tout futur emplacement) doit appeler
// `matchesSearch` avec ses propres champs pertinents plutôt que de
// dupliquer une logique de correspondance locale (Correction 6).
// Correspondance insensible à la casse ET aux accents, partielle
// (contains), jamais une égalité stricte.

const Map<String, String> _diacriticsMap = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ç': 'c', 'ñ': 'n',
  'œ': 'oe', 'æ': 'ae',
};

/// Minuscules + accents retirés — base de comparaison commune à
/// `matchesSearch`. Exposée séparément pour les rares cas où seule la
/// normalisation (sans le test de correspondance) est utile.
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacriticsMap[char] ?? char);
  }
  return buffer.toString();
}

/// Correspondance partielle insensible à la casse et aux accents entre
/// [query] et n'importe lequel des [fields] fournis (champs nuls ignorés).
/// Une [query] vide correspond à tout (aucun filtre actif) — au lieu
/// d'exclure les éléments, cela permet d'appeler cette fonction
/// inconditionnellement, sans test `isNotEmpty` séparé chez l'appelant.
bool matchesSearch(String query, Iterable<String?> fields) {
  final q = normalizeForSearch(query.trim());
  if (q.isEmpty) return true;
  return fields.any((f) => f != null && normalizeForSearch(f).contains(q));
}
