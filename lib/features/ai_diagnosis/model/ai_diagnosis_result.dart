class AiDiagnosisResult {
  final int id;
  final String imageUrl;

  final String species;
  final double speciesConfidence;
  final Map<String, double> speciesProbs;

  final String diseaseGroup;
  final String diseaseGroupVi;
  final double diseaseConfidence;
  final Map<String, double> diseaseProbs;

  final List<String> advice;

  AiDiagnosisResult({
    required this.id,
    required this.imageUrl,
    required this.species,
    required this.speciesConfidence,
    required this.speciesProbs,
    required this.diseaseGroup,
    required this.diseaseGroupVi,
    required this.diseaseConfidence,
    required this.diseaseProbs,
    required this.advice,
  });

  static Map<String, double> _mapDouble(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), (val as num).toDouble()));
    }
    return {};
  }

  factory AiDiagnosisResult.fromJson(Map<String, dynamic> json) {
    return AiDiagnosisResult(
      id: (json['id'] as num).toInt(),
      imageUrl: (json['image_url'] ?? '').toString(),
      species: (json['species'] ?? '').toString(),
      speciesConfidence: (json['species_confidence'] as num?)?.toDouble() ?? 0,
      speciesProbs: _mapDouble(json['species_probs']),
      diseaseGroup: (json['disease_group'] ?? '').toString(),
      diseaseGroupVi: (json['disease_group_vi'] ?? '').toString(),
      diseaseConfidence: (json['disease_confidence'] as num?)?.toDouble() ?? 0,
      diseaseProbs: _mapDouble(json['disease_probs']),
      advice: ((json['advice'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
