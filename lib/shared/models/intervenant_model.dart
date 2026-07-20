// lib/shared/models/intervenant_model.dart

// Issue d'une intervention lorsque le cas est redevenu Disponible sans
// avoir été traité. Sans lien avec ReportStatus (qui repasse à
// `disponible`) — sert uniquement à l'affichage du tableau de bord
// de l'intervenant concerné (IntervenantDetailPage).
// abandoned          : délai de 72h dépassé sans preuve (automatique).
// abandonedVoluntary : l'intervenant a lui-même abandonné avant la fin du
//                      délai — même effet (cas libéré) mais motif distinct,
//                      affiché différemment dans le résidu privé.
enum InterventionOutcome { none, abandoned, abandonedVoluntary, rejected }

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
  final InterventionOutcome outcome;

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
    this.outcome = InterventionOutcome.none,
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
    InterventionOutcome? outcome,
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
      outcome: outcome ?? this.outcome,
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