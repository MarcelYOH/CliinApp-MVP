// lib/shared/store/group_store.dart
// Store central — ChangeNotifier
// Consomme GroupRepository (mock aujourd'hui, Firebase demain)
// Pour brancher Firebase : remplacer MockGroupRepository par FirebaseGroupRepository
// sans toucher aux widgets ni aux pages

import 'package:flutter/foundation.dart';
import '../repositories/group_repository.dart';
import '../repositories/mock_group_repository.dart';
import '../../features/groups/models/group_model.dart';

class GroupStore extends ChangeNotifier {
  GroupStore._();
  static final GroupStore instance = GroupStore._();

  // ignore: prefer_final_fields
  GroupRepository _repository = MockGroupRepository.instance;

  // ignore: use_setters_to_change_properties
  void setRepository(GroupRepository repo) {
    _repository = repo;
  }

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  // Sympathisants par groupe — bookkeeping interne au store (le modèle ne
  // conserve que sympathisantsCount, un compteur agrégé). Nécessaire pour
  // déterminer si UN utilisateur donné suit déjà un groupe (getMesGroupes,
  // getGroupesADecouvrir, garde-fou d'addAdmin).
  final Map<String, Set<String>> _followerIds = {};

  // Cache synchrone des membres par groupe — alimenté à init() et tenu à
  // jour après chaque changement d'administrateurs. Permet à GroupCard
  // d'afficher les avatars de l'équipe dirigeante sans requête async par
  // carte (voir leaderAvatars ci-dessous).
  final Map<String, List<GroupMemberModel>> _membersCache = {};

  List<GroupModel> get allGroups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _setLoading(true);
    try {
      _groups = await _repository.fetchAllGroups();
      for (final g in _groups) {
        _membersCache[g.id] = await _repository.fetchMembers(g.id);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  GroupModel? groupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<GroupMemberModel>> membersOf(String groupId) {
    return _repository.fetchMembers(groupId);
  }

  // Membres en cache (synchrone) — équipe dirigeante (estBureauExecutif)
  // uniquement, jusqu'à 4, pour l'affichage compact de GroupCard.
  List<GroupMemberModel> leaderAvatars(String groupId) {
    final cached = _membersCache[groupId] ?? const [];
    return cached.where((m) => m.estBureauExecutif).take(4).toList();
  }

  // Tous les membres en cache (synchrone) — chaque élément est TOUJOURS un
  // administrateur (estAdmin == true), voir GroupMemberModel. Utilisé par
  // l'Espace gestion (avatars de tous les administrateurs).
  List<GroupMemberModel> cachedMembers(String groupId) =>
      List.unmodifiable(_membersCache[groupId] ?? const []);

  // Équipe dirigeante complète (estBureauExecutif), non plafonnée — "Notre
  // équipe" du profil. Les administrateurs délégués n'y apparaissent jamais.
  List<GroupMemberModel> bureauExecutifMembers(String groupId) =>
      cachedMembers(groupId).where((m) => m.estBureauExecutif).toList();

  bool isAdmin(String groupId, String userId) =>
      cachedMembers(groupId).any((m) => m.id == userId && m.estAdmin);

  // Sympathisants du groupe pouvant être promus administrateurs — exclut
  // ceux déjà administrateurs. Filtre par nom uniquement (voir
  // fetchSympathisants : pas d'annuaire téléphone réel dans ce mock).
  Future<List<GroupMemberModel>> searchSympathisants(
    String groupId,
    String query,
  ) async {
    final pool = await _repository.fetchSympathisants(groupId);
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return pool;
    return pool
        .where((m) => m.nom.toLowerCase().contains(normalized))
        .toList();
  }

  // ── Création ────────────────────────────────────────────────────
  // Le créateur devient automatiquement le premier administrateur (poste
  // "Président") ET le premier sympathisant (sympathisantsCount = 1).
  Future<GroupModel> createGroup({
    required String nom,
    required String description,
    required GroupType type,
    required String zone,
    double? latitude,
    double? longitude,
    String? photoPath,
    required String createurId,
    String createurNom = 'Vous',
    String? createurAvatarPath,
  }) async {
    _setLoading(true);
    try {
      final group = GroupModel(
        id: '',
        nom: nom,
        photoPath: photoPath,
        description: description,
        type: type,
        zone: zone,
        latitude: latitude,
        longitude: longitude,
        estActif: false,
        createdAt: DateTime.now(),
        createurId: createurId,
        sympathisantsCount: 1,
      );
      final createur = GroupMemberModel(
        id: createurId,
        nom: createurNom,
        avatarPath: createurAvatarPath,
        role: 'Président',
        estAdmin: true,
        estBureauExecutif: true,
      );
      final added = await _repository.addGroup(group, createur);
      _groups.insert(0, added);
      _followerIds.putIfAbsent(added.id, () => {}).add(createurId);
      _membersCache[added.id] = [createur];
      _error = null;
      notifyListeners();
      return added;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ── Modification ────────────────────────────────────────────────
  // Utilisée par ModifierGroupeForm ET par chaque section éditable de
  // "À propos" — même méthode sous-jacente, pas de duplication.
  Future<GroupModel> updateGroup(
    String groupId, {
    String? nom,
    String? photoPath,
    String? description,
    GroupType? type,
    String? zone,
    double? latitude,
    double? longitude,
    String? missionTexte,
    String? activitesClesTexte,
    String? besoinCommunication,
    String? besoinBenevoles,
    String? besoinFinancement,
    String? besoinMateriel,
  }) async {
    final current = groupById(groupId);
    if (current == null) throw Exception('Groupe introuvable : $groupId');

    final updated = current.copyWith(
      nom: nom,
      photoPath: photoPath,
      description: description,
      type: type,
      zone: zone,
      latitude: latitude,
      longitude: longitude,
      missionTexte: missionTexte,
      activitesClesTexte: activitesClesTexte,
      besoinCommunication: besoinCommunication,
      besoinBenevoles: besoinBenevoles,
      besoinFinancement: besoinFinancement,
      besoinMateriel: besoinMateriel,
    );
    await _persist(updated);
    return updated;
  }

  Future<void> deleteGroup(String groupId) async {
    await _repository.deleteGroup(groupId);
    _groups.removeWhere((g) => g.id == groupId);
    _followerIds.remove(groupId);
    notifyListeners();
  }

  // ── Suivre / ne plus suivre ────────────────────────────────────
  // Action immédiate, sans validation ni invitation. "Sympathisant"
  // englobe tout le monde dans le groupe (bureau exécutif, administrateurs
  // délégués, simples suiveurs) : ce compteur augmente dès qu'une personne
  // suit le groupe, qu'elle devienne ensuite administratrice ou non.
  // C'est aussi la SEULE façon de "quitter" un groupe pour un simple
  // sympathisant (unfollowGroup) — pas de bouton "Quitter" séparé, réservé
  // aux administrateurs dans les Paramètres.
  Future<void> followGroup(String groupId, String userId) async {
    final current = groupById(groupId);
    if (current == null) return;
    final followers = _followerIds.putIfAbsent(groupId, () => {});
    if (!followers.add(userId)) return;
    await _persist(current.copyWith(
        sympathisantsCount: current.sympathisantsCount + 1));
  }

  Future<void> unfollowGroup(String groupId, String userId) async {
    final current = groupById(groupId);
    if (current == null) return;
    final followers = _followerIds[groupId];
    if (followers == null || !followers.remove(userId)) return;
    final next = current.sympathisantsCount > 0
        ? current.sympathisantsCount - 1
        : 0;
    await _persist(current.copyWith(sympathisantsCount: next));
  }

  bool isFollowing(String groupId, String userId) =>
      _followerIds[groupId]?.contains(userId) ?? false;

  // ── Administrateurs ────────────────────────────────────────────
  // Rappel : la personne ajoutée doit déjà être sympathisante du groupe
  // (avoir suivi) avant de pouvoir être promue administratrice — le
  // mécanisme de recherche du Lot 3 ne propose que des sympathisants.
  // poste != null -> estBureauExecutif = true, role = poste (apparaît
  // dans "Notre équipe"). poste == null -> "Administrateur sans poste
  // officiel", visible uniquement dans l'Espace gestion.
  Future<void> addAdmin(
    String groupId,
    GroupMemberModel membre, {
    String? poste,
  }) async {
    // Construction directe (pas copyWith) : poste == null doit pouvoir
    // effacer un role précédent, ce que le repli `??` de copyWith ne
    // permet pas.
    final admin = GroupMemberModel(
      id: membre.id,
      nom: membre.nom,
      avatarPath: membre.avatarPath,
      role: poste,
      estAdmin: true,
      estBureauExecutif: poste != null,
    );
    await _repository.addMember(groupId, admin);
    _membersCache[groupId] = await _repository.fetchMembers(groupId);
    notifyListeners();
  }

  Future<void> removeAdmin(String groupId, String memberId) async {
    await _repository.removeMember(groupId, memberId);
    _membersCache[groupId] = await _repository.fetchMembers(groupId);
    notifyListeners();
  }

  // ── Badges — calcul automatique, jamais saisi manuellement ────────
  // Appelée automatiquement à chaque mise à jour des compteurs d'impact
  // (casSignalesCount / casTraitesCount / actionsCount). Seuils détaillés
  // dans group_model.dart, au-dessus de calculateGroupBadges().
  Future<void> recalculerBadges(String groupId) async {
    final current = groupById(groupId);
    if (current == null) return;
    final badges = calculateGroupBadges(
      casSignalesCount: current.casSignalesCount,
      casTraitesCount: current.casTraitesCount,
      actionsCount: current.actionsCount,
    );
    if (listEquals(badges, current.badges)) return;
    await _persist(current.copyWith(badges: badges));
  }

  // ── Requêtes ────────────────────────────────────────────────────
  static int _badgeRank(GroupModel g) {
    if (g.badges.contains('officiel')) return 3;
    if (g.badges.contains('impact')) return 2;
    if (g.badges.contains('engage')) return 1;
    return 0;
  }

  List<GroupModel> getGroupsActifs() {
    final actifs = _groups.where((g) => g.estActif).toList()
      ..sort((a, b) => _badgeRank(b).compareTo(_badgeRank(a)));
    return actifs;
  }

  List<GroupModel> getMesGroupes(String userId) {
    return _groups.where((g) => isFollowing(g.id, userId)).toList();
  }

  List<GroupModel> getGroupesADecouvrir(String userId) {
    return _groups.where((g) => !isFollowing(g.id, userId)).toList();
  }

  List<GroupModel> rechercherGroupes(
    String query, {
    GroupType? type,
    String? niveauImpact,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return _groups.where((g) {
      final matchesQuery = normalizedQuery.isEmpty ||
          g.nom.toLowerCase().contains(normalizedQuery);
      final matchesType = type == null || g.type == type;
      final matchesNiveau =
          niveauImpact == null || g.badges.contains(niveauImpact);
      return matchesQuery && matchesType && matchesNiveau;
    }).toList();
  }

  // ── Helpers internes ──────────────────────────────────────────
  Future<void> _persist(GroupModel updated) async {
    final saved = await _repository.updateGroup(updated);
    final index = _groups.indexWhere((g) => g.id == saved.id);
    if (index != -1) {
      _groups[index] = saved;
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
