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
//   4. Verrouillage de position ("ancre") — un filtre de lissage classique
//      (Kalman) continue de suivre chaque nouvelle mesure, même bruitée,
//      dès lors que le téléphone annonce une précision qu'on ne peut pas
//      toujours prendre pour argent comptant (appareils d'entrée de
//      gamme, ou A-GPS lent à converger en zone de réseau faible où le
//      téléchargement des éphémérides satellites est lent). On verrouille
//      donc une position "ancre" : tant que les nouvelles mesures restent
//      dans un rayon de bruit plausible autour de l'ancre, elles sont
//      ignorées et la distance affichée ne bouge pas. Un déplacement
//      n'est confirmé (et l'ancre déplacée) qu'après 2 mesures
//      consécutives cohérentes au-delà de ce rayon.
//
// ✅ ChangeNotifier — dès que l'ancre bouge, TOUTES les cartes affichées
// à l'écran sont notifiées et recalculent leur distance.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Verrouillage de position — élimine le bruit GPS quand l'utilisateur est
/// immobile, au lieu de le lisser mathématiquement.
///
/// Démarrage : les 3 premiers fix sont collectés, le plus précis (accuracy
/// la plus faible) devient l'ancre initiale — évite de partir sur le tout
/// premier fix, souvent le moins bon (démarrage à froid de l'A-GPS).
///
/// Verrouillage : tant qu'un nouveau fix reste à moins de
/// [lockRadiusMeters] de l'ancre, il est ignoré — c'est du bruit, pas un
/// déplacement.
///
/// Déverrouillage : un déplacement n'est confirmé (et l'ancre déplacée)
/// qu'après 2 fix consécutifs cohérents au-delà du rayon de verrouillage —
/// une seule mesure aberrante ne suffit pas à faire "sauter" l'ancre.
class _PositionAnchor {
  static const double lockRadiusMeters = 30;
  static const int _startupSampleTarget = 3;

  double? lat;
  double? lng;

  final List<({double lat, double lng, double accuracy})> _startupFixes = [];
  ({double lat, double lng})? _pending;
  int _pendingConfirmations = 0;

  bool get isLocked => lat != null;

  /// Traite un nouveau fix accepté. Retourne true si l'ancre vient d'être
  /// (re)positionnée — démarrage terminé ou déplacement confirmé — auquel
  /// cas la distance affichée doit être recalculée.
  bool accept(double fixLat, double fixLng, double accuracyMeters) {
    final safeAccuracy = accuracyMeters <= 0 ? 9999.0 : accuracyMeters;

    if (lat == null) {
      _startupFixes.add((lat: fixLat, lng: fixLng, accuracy: safeAccuracy));
      if (_startupFixes.length < _startupSampleTarget) return false;
      _finalizeStartup();
      return true;
    }

    final drift = Geolocator.distanceBetween(lat!, lng!, fixLat, fixLng);
    if (drift <= lockRadiusMeters) {
      // Bruit — l'ancre ne bouge pas.
      _pendingConfirmations = 0;
      _pending = null;
      return false;
    }

    // Déplacement potentiel : n'est confirmé qu'après 2 fix cohérents
    // entre eux (pas juste 2 fix qui s'écartent chacun dans une direction
    // différente, ce qui resterait du bruit).
    final pending = _pending;
    if (pending != null &&
        Geolocator.distanceBetween(pending.lat, pending.lng, fixLat, fixLng) <=
            lockRadiusMeters) {
      _pendingConfirmations++;
    } else {
      _pendingConfirmations = 1;
    }
    _pending = (lat: fixLat, lng: fixLng);

    if (_pendingConfirmations >= 2) {
      lat = fixLat;
      lng = fixLng;
      _pendingConfirmations = 0;
      _pending = null;
      return true;
    }
    return false;
  }

  /// Filet de sécurité : si le flux GPS ne délivre pas assez de mesures
  /// pour compléter l'échantillon de démarrage (utilisateur parfaitement
  /// immobile — certains téléphones cessent d'émettre des mises à jour
  /// une fois le filtre de déplacement du flux satisfait), on verrouille
  /// avec ce qu'on a plutôt que d'afficher "..." indéfiniment.
  bool finalizeStartupIfPending() {
    if (lat != null || _startupFixes.isEmpty) return false;
    _finalizeStartup();
    return true;
  }

  void _finalizeStartup() {
    final best =
        _startupFixes.reduce((a, b) => a.accuracy <= b.accuracy ? a : b);
    lat = best.lat;
    lng = best.lng;
    _startupFixes.clear();
  }
}

class UserLocationService extends ChangeNotifier {
  UserLocationService._();
  static final UserLocationService instance = UserLocationService._();

  Position? _cachedPosition;
  DateTime? _cachedAt;
  static const Duration _cacheDuration = Duration(seconds: 30);

  StreamSubscription<Position>? _positionSub;

  // ── Étape 4 — ancre de position, utilisée pour tout calcul de distance ──
  final _PositionAnchor _anchor = _PositionAnchor();
  Timer? _anchorTimeoutTimer;
  static const Duration _anchorStartupTimeout = Duration(seconds: 6);

  // ── Étape 3 — filtre anti-aberration ──────────────────────────
  static const double _aberrationThresholdMeters = 500;
  static const Duration _aberrationWindow = Duration(seconds: 10);

  /// Point d'entrée unique pour toute nouvelle mesure GPS (fix initial,
  /// flux continu, ou position partagée par un autre écran). Rejette les
  /// sauts aberrants, puis transmet la mesure acceptée à l'ancre de
  /// position avant de mettre à jour le cache.
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

    final hadNoPositionBefore = _cachedPosition == null;
    final anchorMoved = _anchor.accept(pos.latitude, pos.longitude, pos.accuracy);

    if (!_anchor.isLocked) {
      // Toujours en phase de démarrage — programme le filet de sécurité
      // une seule fois (annulé dès que l'ancre se verrouille).
      _anchorTimeoutTimer ??= Timer(_anchorStartupTimeout, () {
        if (_anchor.finalizeStartupIfPending()) notifyListeners();
      });
    } else {
      _anchorTimeoutTimer?.cancel();
      _anchorTimeoutTimer = null;
    }

    _cachedPosition = pos;
    _cachedAt = DateTime.now();

    if (hadNoPositionBefore || anchorMoved) {
      notifyListeners();
    }
  }

  /// Étape 2 — flux de mise à jour contrôlé : précision GPS haute (fix
  /// satellite, pas une position réseau/cellulaire imprécise), seulement
  /// si déplacement réel d'au moins 8m — le verrouillage (étape 4) absorbe
  /// le bruit résiduel d'une mesure à l'autre.
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

  /// Distance brute en mètres entre l'ancre de position (étape 4) et le
  /// point donné. Utilisée pour le filtrage par rayon (ex: 2km autour de
  /// l'utilisateur) et pour l'affichage — c'est la position ancrée, pas
  /// le fix GPS brut, qui évite les sauts de quelques dizaines/centaines
  /// de mètres d'un rafraîchissement à l'autre alors que l'utilisateur
  /// est immobile.
  /// Retourne null si l'ancre n'est pas encore verrouillée ou si le point
  /// cible est inconnu.
  double? distanceMetersTo(double? targetLat, double? targetLng) {
    if (targetLat == null || targetLng == null) return null;
    if (_anchor.lat == null || _anchor.lng == null) return null;
    return Geolocator.distanceBetween(
      _anchor.lat!,
      _anchor.lng!,
      targetLat,
      targetLng,
    );
  }

  /// Distance formatée entre l'ancre de position et le point donné.
  /// Retourne null si l'ancre n'est pas encore verrouillée ou si le point
  /// cible est inconnu (l'appelant doit alors afficher "...").
  String? distanceLabelTo(double? targetLat, double? targetLng) {
    final meters = distanceMetersTo(targetLat, targetLng);
    if (meters == null) return null;
    return formatMeters(meters);
  }
}
