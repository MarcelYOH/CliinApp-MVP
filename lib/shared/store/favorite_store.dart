// lib/shared/store/favorite_store.dart
// Store central — ChangeNotifier
// "Mes favoris" (Profil) — pour l'instant uniquement des actions terrain
// (seul module qui expose un bouton Bookmark, Lot 2 Actions Terrain).
// Signalements et profils de groupe recevront la même logique dans un
// prompt dédié séparé (voir action_detail_page.dart) — étendre alors ce
// store plutôt que de le dupliquer.

import 'package:flutter/foundation.dart';

class FavoriteStore extends ChangeNotifier {
  FavoriteStore._();
  static final FavoriteStore instance = FavoriteStore._();

  // Bookkeeping interne, même logique que GroupStore._followerIds : pas de
  // repository dédié pour l'instant (favoris = préférence locale à la
  // session, comme le suivi de groupe).
  final Map<String, Set<String>> _favoriteActionIds = {};

  bool isActionFavorite(String userId, String actionId) =>
      _favoriteActionIds[userId]?.contains(actionId) ?? false;

  void toggleActionFavorite(String userId, String actionId) {
    final favorites = _favoriteActionIds.putIfAbsent(userId, () => {});
    if (!favorites.remove(actionId)) {
      favorites.add(actionId);
    }
    notifyListeners();
  }

  List<String> favoriteActionIds(String userId) =>
      List.unmodifiable(_favoriteActionIds[userId] ?? const <String>{});
}
