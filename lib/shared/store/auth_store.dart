// lib/shared/store/auth_store.dart
// Store d'authentification — singleton ChangeNotifier, même pattern que ReportStore.

import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mock_auth_repository.dart';
import '../models/auth_user_model.dart';

class AuthStore extends ChangeNotifier {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  final AuthRepository _repository = MockAuthRepository.instance;

  AuthUser? _currentUser;
  bool _isLoading = false;

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  // Exposé pour affichage debug du code OTP dans l'UI
  String? get lastDebugCode => _repository.lastDebugCode;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _repository.loadPersistedSession();
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    await _repository.sendPhoneOtp(phoneNumber);
    notifyListeners();
  }

  Future<void> sendEmailOtp(String email) async {
    await _repository.sendEmailOtp(email);
    notifyListeners();
  }

  Future<bool> verifyOtp(String code) async {
    return _repository.verifyOtp(code);
  }

  Future<AuthUser> completeProfile({
    required String username,
    required String zone,
    String? avatarPath,
  }) async {
    final user = await _repository.completeProfile(
      username: username,
      zone: zone,
      avatarPath: avatarPath,
    );
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<AuthUser> updateProfile({
    String? username,
    String? zone,
    String? avatarPath,
  }) async {
    final user = await _repository.updateProfile(
      username: username,
      zone: zone,
      avatarPath: avatarPath,
    );
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<void> signInWithGoogle() async {
    await _repository.signInWithGoogle();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
