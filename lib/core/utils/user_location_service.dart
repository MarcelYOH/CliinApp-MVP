// lib/core/utils/user_location_service.dart
// Service centralisé de géolocalisation — CliinApp
//
// Objectif : fournir la position actuelle de l'utilisateur (avec mise en
// cache courte durée pour éviter de multiplier les appels GPS quand
// plusieurs cartes de signalement s'affichent en même temps), et calculer
// la distance réelle vers un signalement donné.
//
// ✅ ChangeNotifier — dès qu'une position arrive (au démarrage de l'app,
// pendant la création d'un signalement, ou via une carte qui réussit son
// propre appel GPS), TOUTES les cartes déjà affichées à l'écran sont
// notifiées et recalculent leur distance. Avant, une carte qui échouait
// son premier essai GPS restait figée sur le repli pour toujours, même
// après qu'une position soit obtenue ailleurs dans l'app — la page
// d'accueil reste "vivante" en mémoire entre les onglets et ne
// réessayait jamais spontanément.
//
// Remplace l'ancienne approche où 'distance' était une chaîne figée
// ('< 1 km') stockée dans HomeReportModel à la création — la distance
// dépend de QUI regarde la carte, pas de la création du signalement.

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class UserLocationService extends ChangeNotifier {
  UserLocationService._();
  static final UserLocationService instance = UserLocationService._();

  Position? _cachedPosition;
  DateTime? _cachedAt;
  static const Duration _cacheDuration = Duration(seconds: 30);

  /// Position actuelle, depuis le cache si encore fraîche, sinon nouvelle
  /// mesure GPS. Retourne null si la géolocalisation échoue et qu'aucune
  /// position n'a jamais été récupérée.
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    final isFresh = _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheDuration;
    if (!forceRefresh && isFresh && _cachedPosition != null) {
      return _cachedPosition;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _cachedPosition;
      }

      // Pas de timeLimit : en zone rurale un premier fix GPS dépasse
      // souvent 5s, ce qui faisait échouer la mesure et enregistrer une
      // position null (donc plus aucun calcul de distance possible).
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _cachedPosition = pos;
      _cachedAt = DateTime.now();
      notifyListeners(); // ✅ prévient toutes les cartes affichées
      return pos;
    } catch (_) {
      // GPS indisponible / refusé / timeout → on retombe sur le dernier
      // cache connu (peut être null si jamais récupéré avec succès).
      return _cachedPosition;
    }
  }

  /// Position en cache, sans déclencher de nouvelle mesure GPS.
  Position? get lastKnownPosition => _cachedPosition;

  /// ✅ NOUVEAU — permet à un autre écran (ex: report_form_page.dart, qui
  /// fait son propre appel Geolocator pour combiner position + adresse
  /// via geocoding) de partager une position déjà obtenue avec succès,
  /// plutôt que de laisser deux caches de géolocalisation déconnectés
  /// dans l'app. Sans ça, un succès GPS sur un écran ne profitait jamais
  /// au calcul de distance affiché sur les cartes ailleurs dans l'app.
  void setKnownPosition(Position position) {
    _cachedPosition = position;
    _cachedAt = DateTime.now();
    notifyListeners(); // ✅ prévient toutes les cartes affichées
  }

  String _formatMeters(double meters) {
    if (meters < 50) return 'Sur place';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Distance brute en mètres entre la position en cache et le point donné.
  /// Utilisée pour le filtrage par rayon (ex: 2km autour de l'utilisateur).
  /// Retourne null si la position actuelle ou le point cible est inconnu.
  double? distanceMetersTo(double? targetLat, double? targetLng) {
    if (targetLat == null || targetLng == null) return null;
    if (_cachedPosition == null) return null;
    return Geolocator.distanceBetween(
      _cachedPosition!.latitude,
      _cachedPosition!.longitude,
      targetLat,
      targetLng,
    );
  }

  /// Distance formatée entre la position en cache et le point donné.
  /// Retourne null si la position actuelle ou le point cible est inconnu
  /// (l'appelant doit alors afficher une valeur de repli).
  String? distanceLabelTo(double? targetLat, double? targetLng) {
    final meters = distanceMetersTo(targetLat, targetLng);
    if (meters == null) return null;
    return _formatMeters(meters);
  }
}