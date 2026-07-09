// lib/shared/repositories/auth_repository.dart

import '../models/auth_user_model.dart';

abstract class AuthRepository {
  Future<void> sendPhoneOtp(String phoneNumber);
  Future<void> sendEmailOtp(String email);
  Future<bool> verifyOtp(String code);
  Future<AuthUser> completeProfile({
    required String username,
    required String zone,
    String? avatarPath,
  });
  Future<AuthUser> updateProfile({
    String? username,
    String? zone,
    String? avatarPath,
  });
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<AuthUser?> loadPersistedSession();
  AuthUser? get currentUser;

  // Donne accès au code généré pour l'afficher en debug UI
  String? get lastDebugCode;
}
