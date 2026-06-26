// lib/shared/models/intervenant_model.dart

class IntervenantModel {
  final String id;
  final String name;
  final String? logoAsset;
  final String? takenAgo;
  final DateTime? takenAt;
  final DateTime? treatedAt;

  // whatsAppNumber  : numéro enregistré (null si pas de numéro)
  // whatsAppVisible : contrôle la visibilité publique (allowContact)
  final String? groupName;    // null si intervention individuelle
  final String? whatsAppNumber;
  final bool whatsAppVisible;

  const IntervenantModel({
    required this.id,
    required this.name,
    this.logoAsset,
    this.takenAgo,
    this.takenAt,
    this.treatedAt,
    this.groupName,
    this.whatsAppNumber,
    this.whatsAppVisible = false, // OFF par défaut
  });

  // Bouton "Contacter" public visible uniquement si :
  // whatsAppVisible = true ET whatsAppNumber != null
  bool get isContactable =>
      whatsAppVisible && whatsAppNumber != null && whatsAppNumber!.isNotEmpty;

  IntervenantModel copyWith({
    String? id,
    String? name,
    String? logoAsset,
    String? takenAgo,
    DateTime? takenAt,
    DateTime? treatedAt,
    String? groupName,
    String? whatsAppNumber,
    bool? whatsAppVisible,
  }) {
    return IntervenantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoAsset: logoAsset ?? this.logoAsset,
      takenAgo: takenAgo ?? this.takenAgo,
      takenAt: takenAt ?? this.takenAt,
      treatedAt: treatedAt ?? this.treatedAt,
      groupName: groupName ?? this.groupName,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
      whatsAppVisible: whatsAppVisible ?? this.whatsAppVisible,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoAsset': logoAsset,
    'takenAt': takenAt?.toIso8601String(),
    'treatedAt': treatedAt?.toIso8601String(),
    'whatsAppNumber': whatsAppNumber,
    'whatsAppVisible': whatsAppVisible,
  };

  factory IntervenantModel.fromJson(Map<String, dynamic> json) =>
      IntervenantModel(
        id: json['id'] as String,
        name: json['name'] as String,
        logoAsset: json['logoAsset'] as String?,
        takenAt: json['takenAt'] != null
            ? DateTime.parse(json['takenAt'] as String)
            : null,
        treatedAt: json['treatedAt'] != null
            ? DateTime.parse(json['treatedAt'] as String)
            : null,
        whatsAppNumber: json['whatsAppNumber'] as String?,
        whatsAppVisible: json['whatsAppVisible'] as bool? ?? false,
      );
}