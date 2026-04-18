/// Represents an enriched ISL sign returned by FastAPI /enrich.
/// duration_ms is in MILLISECONDS — already converted at FastAPI boundary.
/// Three.js receives this directly for setTimeout sequencing.
class EnrichedSign {
  final String gloss;
  final int durationMs; // milliseconds — converted from seconds at FastAPI ONLY
  final List<Map<String, dynamic>> keyframes;
  final Map<String, dynamic> nmm;

  const EnrichedSign({
    required this.gloss,
    required this.durationMs,
    required this.keyframes,
    required this.nmm,
  });

  factory EnrichedSign.fromJson(Map<String, dynamic> json) {
    return EnrichedSign(
      gloss: json['gloss'] as String,
      durationMs: json['duration_ms'] as int,
      keyframes: (json['keyframes'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      nmm: Map<String, dynamic>.from(json['nmm'] as Map),
    );
  }

  Map<String, dynamic> toJson() => {
        'gloss': gloss,
        'duration_ms': durationMs,
        'keyframes': keyframes,
        'nmm': nmm,
      };

  @override
  String toString() => 'EnrichedSign(gloss: $gloss, duration_ms: ${durationMs}ms)';
}
