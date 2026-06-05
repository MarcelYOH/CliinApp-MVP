// lib/shared/models/intervenant_model.dart

class IntervenantModel {
  final String id;
  final String name;
  final String? logoAsset;
  final String? takenAgo;
  final DateTime? takenAt;
  final DateTime? treatedAt;

  // ── WhatsApp — MVP ────────────────────────────────────────────
  // whatsAppNumber : null si l'intervenant n'a pas consenti
  // whatsAppVisible : toggle ON/OFF depuis l'interface intervenant
  final String? whatsAppNumber;
  final bool whatsAppVisible;

  const IntervenantModel({
    required this.id,
    required this.name,
    this.logoAsset,
    this.takenAgo,
    this.takenAt,
    this.treatedAt,
    this.whatsAppNumber,
    this.whatsAppVisible = false,
  });

  // ── Backend-ready : sérialisation ────────────────────────────
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