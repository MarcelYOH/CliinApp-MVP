// lib/shared/models/auth_user_model.dart

class AuthUser {
  final String id;
  final String username;
  final String? phoneNumber;
  final String? email;
  final String? avatarPath;
  final String zone;
  final DateTime createdAt;
  // Correction 2 — ON par défaut. OFF : le profil public de cet
  // utilisateur n'est plus accessible via un lien auteur/intervenant
  // ailleurs dans l'app (message de blocage affiché à la place). Ne
  // s'applique jamais aux groupes, toujours publics.
  final bool publicProfileEnabled;

  const AuthUser({
    required this.id,
    required this.username,
    this.phoneNumber,
    this.email,
    this.avatarPath,
    required this.zone,
    required this.createdAt,
    this.publicProfileEnabled = true,
  });

  AuthUser copyWith({
    String? id,
    String? username,
    String? phoneNumber,
    String? email,
    String? avatarPath,
    String? zone,
    DateTime? createdAt,
    bool? publicProfileEnabled,
  }) {
    return AuthUser(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      zone: zone ?? this.zone,
      createdAt: createdAt ?? this.createdAt,
      publicProfileEnabled: publicProfileEnabled ?? this.publicProfileEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'phoneNumber': phoneNumber,
        'email': email,
        'avatarPath': avatarPath,
        'zone': zone,
        'createdAt': createdAt.toIso8601String(),
        'publicProfileEnabled': publicProfileEnabled,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        username: json['username'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String?,
        avatarPath: json['avatarPath'] as String?,
        zone: json['zone'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        publicProfileEnabled: json['publicProfileEnabled'] as bool? ?? true,
      );
}
