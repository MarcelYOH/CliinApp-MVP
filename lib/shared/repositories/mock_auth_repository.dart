// lib/shared/repositories/mock_auth_repository.dart
// Implémentation de test — pas de vrai SMS/email.
// Le code OTP généré est exposé via lastDebugCode pour affichage dans l'UI.

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repository.dart';
import '../models/auth_user_model.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository._();
  static final MockAuthRepository instance = MockAuthRepository._();

  static const String _prefKey = 'auth_user_json';

  AuthUser? _currentUser;
  String? _pendingCode;
  DateTime? _codeExpiry;
  String? _pendingContact;
  String? _lastDebugCode;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  String? get lastDebugCode => _lastDebugCode;

  @override
  Future<void> sendPhoneOtp(String phoneNumber) async {
    _pendingContact = phoneNumber;
    _pendingCode = _generateCode();
    _lastDebugCode = _pendingCode;
    _codeExpiry = DateTime.now().add(const Duration(minutes: 5));
    // Pas de vrai SMS — le code s'affiche dans l'UI via lastDebugCode
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    _pendingContact = email;
    _pendingCode = _generateCode();
    _lastDebugCode = _pendingCode;
    _codeExpiry = DateTime.now().add(const Duration(minutes: 5));
  }

  @override
  Future<bool> verifyOtp(String code) async {
    if (_pendingCode == null || _codeExpiry == null) return false;
    if (DateTime.now().isAfter(_codeExpiry!)) {
      _pendingCode = null;
      return false;
    }
    return code.trim() == _pendingCode;
  }

  @override
  Future<AuthUser> completeProfile({
    required String username,
    required String zone,
    String? avatarPath,
  }) async {
    final user = AuthUser(
      id: _generateId(),
      username: username,
      phoneNumber:
          _pendingContact != null && _pendingContact!.startsWith('+')
              ? _pendingContact
              : null,
      email:
          _pendingContact != null && _pendingContact!.contains('@')
              ? _pendingContact
              : null,
      avatarPath: avatarPath,
      zone: zone,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    await _persistSession(user);
    return user;
  }

  @override
  Future<void> signInWithGoogle() async {
    // Pas de vraie intégration Google — bouton visible mais "Bientôt disponible"
    throw UnsupportedError('google_not_yet');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _pendingCode = null;
    _pendingContact = null;
    _lastDebugCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  @override
  Future<AuthUser?> loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefKey);
      if (json == null) return null;
      final user = AuthUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
      _currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSession(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(user.toJson()));
  }

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  String _generateId() {
    final rand = Random();
    return 'usr_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(9999)}';
  }
}
