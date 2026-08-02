// lib/features/home/utils/home_city_label_controller.dart
//
// Nom de ville affiché dans le message d'accueil ("Bonjour {Nom}, {Ville}
// · {N} cas à proximité") — recalculé EN CONTINU, tant que la page
// d'accueil est visible, au lieu d'une valeur figée depuis l'inscription.
//
// ⚠️ Portée strictement limitée à cet affichage : n'utilise ni ne modifie
// UserLocationService (calcul de distance des cas à proximité, déjà
// validé en test terrain réel — acquis à ne jamais perturber). Flux de
// position totalement indépendant, dédié uniquement à la résolution du
// nom de ville, via le même service de géocodage déjà utilisé ailleurs
// dans le projet (package geocoding, cf. profile_setup_page.dart).
//
// ⚠️ Vie privée : aucune position ni historique n'est jamais stocké (ni
// localement, ni prévu pour un futur envoi serveur) — chaque nouvelle
// mesure remplace simplement cityLabel en mémoire, sans laisser de trace.
// pause()/dispose() arrêtent immédiatement toute lecture GPS ; l'appelant
// (HomePage) est seul responsable de les appeler dès que la page n'est
// plus visible ou que l'application n'est plus au premier plan — jamais
// de lecture de position active en arrière-plan.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeCityLabelController extends ChangeNotifier {
  // Ni trop fréquent (coût réseau/GPS, sans intérêt : une ville ne change
  // pas en quelques secondes) ni trop rare (doit rester "en continu" tant
  // que l'app est ouverte, cf. correction demandée).
  static const Duration _refreshInterval = Duration(seconds: 45);

  String? _cityLabel;
  String? get cityLabel => _cityLabel;

  Timer? _timer;
  bool _resolving = false;

  /// Démarre (ou reprend) le flux — capture immédiatement une position
  /// fraîche (jamais une ancienne valeur mémorisée d'une session
  /// précédente), puis se répète toutes les [_refreshInterval].
  void start() {
    if (_timer != null) return;
    unawaited(_refresh());
    _timer = Timer.periodic(_refreshInterval, (_) => _refresh());
  }

  /// Arrête le flux sans effacer le dernier libellé affiché (évite un
  /// clignotement au retour) — utilisé quand la page d'accueil n'est plus
  /// visible ou que l'application passe en arrière-plan.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_resolving) return;
    _resolving = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLabel(null);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 5), onTimeout: () => const []);

      if (placemarks.isEmpty) {
        _setLabel(null);
        return;
      }

      final p = placemarks.first;
      // Niveau de précision actuel du projet — nom de ville uniquement
      // (pas de quartier), en repli sur la région si la ville est
      // indisponible. Sera enrichi une fois Google Maps Geocoding branché
      // (Phase 2).
      final label = (p.locality?.isNotEmpty == true)
          ? p.locality
          : (p.administrativeArea?.isNotEmpty == true
              ? p.administrativeArea
              : null);
      _setLabel(label);
    } catch (_) {
      // Échec ponctuel (GPS/réseau/géocodage) — on garde le dernier
      // libellé connu plutôt que d'effacer un texte correct pour un raté
      // temporaire ; si aucun n'a jamais été résolu, l'appelant affiche
      // déjà le texte de repli neutre (cityLabel reste null).
    } finally {
      _resolving = false;
    }
  }

  void _setLabel(String? label) {
    if (label == _cityLabel) return;
    _cityLabel = label;
    notifyListeners();
  }
}
