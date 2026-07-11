// lib/core/utils/user_location_service.dart
// Service centralisé de géolocalisation — CliinApp
//
// Objectif : fournir la position actuelle de l'utilisateur (avec mise en
// cache courte durée pour éviter de multiplier les appels GPS quand
// plusieurs cartes de signalement s'affichent en même temps), et calculer
// la distance réelle vers un signalement donné.
//
// Stratégie de stabilité en 4 étapes (contre le bruit GPS et les valeurs
// aberrantes) :
//   1. Position initiale instantanée — Geolocator.getLastKnownPosition()
//      (pas d'attente), repli sur getCurrentPosition(LocationAccuracy.high)
//      si aucune position récente n'est connue du système.
//   2. Mise à jour contrôlée — getPositionStream() avec distanceFilter: 8
//      et accuracy: high (fix satellite GPS, pas une position réseau/
//      cellulaire à ±300m qui fait "sauter" la distance affichée).
//   3. Filtre anti-aberration — si une nouvelle position s'écarte de plus
//      de 500m de la précédente en moins de 10 secondes, elle est ignorée
//      (typiquement un rebond GPS/réseau, pas un vrai déplacement).
//   4. Lissage (filtre de Kalman) — même un fix GPS haute précision
//      "gigote" de quelques mètres d'une mesure à l'autre. Chaque nouvelle
//      mesure est fusionnée avec l'estimation précédente, pondérée par sa
//      précision annoncée (Position.accuracy) : une mesure imprécise ne
//      fait quasiment pas bouger l'estimation, une mesure précise la
//      recale rapidement. C'est le même principe que le "point bleu"
//      stable de Google Maps / Uber.
//
// ✅ ChangeNotifier — dès qu'une position est acceptée, TOUTES les cartes
// affichées à l'écran sont notifiées et recalculent leur distance.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Filtre de Kalman 1D appliqué indépendamment à la latitude et à la
/// longitude. But : produire une position stable pour l'affichage de
/// distance à partir d'une suite de mesures GPS bruitées, sans lag
/// perceptible sur un vrai déplacement.
class _LocationKalmanFilter {
  double? _lat;
  double? _lng;
  double _variance = -1;
  DateTime? _lastTimestamp;

  // Bruit de processus : vitesse de déplacement plausible (m/s), au carré.
  // ~5 m/s couvre la marche rapide et le vélo urbain sans réintroduire le
  // bruit GPS qu'on cherche justement à lisser.
  static const double _processNoiseMetersPerSecond = 5.0;

  ({double lat, double lng}) filter({
    required double lat,
    required double lng,
    required double accuracyMeters,
    required DateTime timestamp,
  }) {
    // Précision annoncée absente ou nulle (arrive sur certains devices) →
    // valeur prudente par défaut pour ne pas sur-pondérer la mesure.
    final safeAccuracy = accuracyMeters <= 0 ? 30.0 : accuracyMeters;

    if (_lat == null || _lng == null || _variance < 0) {
      _lat = lat;
      _lng = lng;
      _variance = safeAccuracy * safeAccuracy;
      _lastTimestamp = timestamp;
      return (lat: _lat!, lng: _lng!);
    }

    final elapsedSeconds =
        timestamp.difference(_lastTimestamp!).inMilliseconds / 1000;
    if (elapsedSeconds > 0) {
      _variance += elapsedSeconds *
          _processNoiseMetersPerSecond *
          _processNoiseMetersPerSecond;
    }
    _lastTimestamp = timestamp;

    // Gain de Kalman : proportion de confiance accordée à la nouvelle
    // mesure par rapport à l'estimation courante.
    final k = _variance / (_variance + safeAccuracy * safeAccuracy);
    _lat = _lat! + k * (lat - _lat!);
    _lng = _lng! + k * (lng - _lng!);
    _variance = (1 - k) * _variance;

    return (lat: _lat!, lng: _lng!);
  }
}

class UserLocationService extends ChangeNotifier {
  UserLocationService._();
  static final UserLocationService instance = UserLocationService._();

  Position? _cachedPosition;
  DateTime? _cachedAt;
  static const Duration _cacheDuration = Duration(seconds: 30);

  StreamSubscription<Position>? _positionSub;

  // ── Étape 4 — position lissée, utilisée pour tout calcul de distance ──
  final _LocationKalmanFilter _kalman = _LocationKalmanFilter();
  double? _smoothedLat;
  double? _smoothedLng;

  // ── Étape 3 — filtre anti-aberration ──────────────────────────
  static const double _aberrationThresholdMeters = 500;
  static const Duration _aberrationWindow = Duration(seconds: 10);

  /// Point d'entrée unique pour toute nouvelle mesure GPS (fix initial,
  /// flux continu, ou position partagée par un autre écran). Rejette les
  /// sauts aberrants, puis fusionne la mesure acceptée dans le filtre de
  /// lissage avant de mettre à jour le cache.
  void _acceptPosition(Position pos) {
    final previous = _cachedPosition;
    final previousAt = _cachedAt;
    if (previous != null && previousAt != null) {
      final elapsed = DateTime.now().difference(previousAt);
      if (elapsed < _aberrationWindow) {
        final jump = Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          pos.latitude,
          pos.longitude,
        );
        if (jump > _aberrationThresholdMeters) {
          // Saut invraisemblable en si peu de temps → probable rebond
          // GPS/réseau. On garde l'ancienne position.
          return;
        }
      }
    }
    final smoothed = _kalman.filter(
      lat: pos.latitude,
      lng: pos.longitude,
      accuracyMeters: pos.accuracy,
      timestamp: DateTime.now(),
    );
    _smoothedLat = smoothed.lat;
    _smoothedLng = smoothed.lng;
    _cachedPosition = pos;
    _cachedAt = DateTime.now();
    notifyListeners();
  }

  /// Étape 2 — flux de mise à jour contrôlé : précision GPS haute (fix
  /// satellite, pas une position réseau/cellulaire imprécise), seulement
  /// si déplacement réel d'au moins 8m — le lissage (étape 4) absorbe le
  /// bruit résiduel d'une mesure à l'autre.
  void _startWatching() {
    if (_positionSub != null) return;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen(_acceptPosition, onError: (_) {});
  }

  /// Étape 1 — position initiale instantanée, sans attendre un fix GPS.
  Future<Position?> _resolveInitialPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
    } catch (_) {
      // ignoré — on retombe sur getCurrentPosition ci-dessous
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Position actuelle, depuis le cache si encore fraîche, sinon nouvelle
  /// résolution (étape 1). Retourne null si la géolocalisation échoue et
  /// qu'aucune position n'a jamais été récupérée.
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

      final pos = await _resolveInitialPosition();
      if (pos != null) {
        _acceptPosition(pos);
        _startWatching();
      }
      return _cachedPosition;
    } catch (_) {
      // GPS indisponible / refusé → on retombe sur le dernier cache connu
      // (peut être null si jamais récupéré avec succès).
      return _cachedPosition;
    }
  }

  /// Position en cache, sans déclencher de nouvelle mesure GPS.
  Position? get lastKnownPosition => _cachedPosition;

  /// Permet à un autre écran (ex: report_form_page.dart, qui fait son
  /// propre appel Geolocator pour combiner position + adresse via
  /// geocoding) de partager une position déjà obtenue avec succès —
  /// passe par le même filtre anti-aberration que les autres sources.
  void setKnownPosition(Position position) {
    _acceptPosition(position);
    _startWatching();
  }

  // ── Format d'affichage — règle stricte et définitive ──────────────
  // < 20m           → "Sur place"
  // 20m à 999m      → "X m"
  // ≥ 1000m         → "X.X km"
  // Jamais un tiret, jamais une valeur inventée — l'appelant affiche
  // "..." tant qu'aucune position n'est disponible (distanceLabelTo
  // retourne null dans ce cas).
  String formatMeters(double meters) {
    if (meters < 20) return 'Sur place';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Distance brute en mètres entre la position lissée (étape 4) et le
  /// point donné. Utilisée pour le filtrage par rayon (ex: 2km autour de
  /// l'utilisateur) et pour l'affichage — c'est la position lissée, pas
  /// le fix GPS brut, qui évite les sauts de quelques dizaines/centaines
  /// de mètres d'un rafraîchissement à l'autre alors que l'utilisateur
  /// est immobile.
  /// Retourne null si la position actuelle ou le point cible est inconnu.
  double? distanceMetersTo(double? targetLat, double? targetLng) {
    if (targetLat == null || targetLng == null) return null;
    if (_smoothedLat == null || _smoothedLng == null) return null;
    return Geolocator.distanceBetween(
      _smoothedLat!,
      _smoothedLng!,
      targetLat,
      targetLng,
    );
  }

  /// Distance formatée entre la position en cache et le point donné.
  /// Retourne null si la position actuelle ou le point cible est inconnu
  /// (l'appelant doit alors afficher "...").
  String? distanceLabelTo(double? targetLat, double? targetLng) {
    final meters = distanceMetersTo(targetLat, targetLng);
    if (meters == null) return null;
    return formatMeters(meters);
  }
}
