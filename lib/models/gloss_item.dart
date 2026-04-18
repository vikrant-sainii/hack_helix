/// Represents a single ISL gloss as returned by n8n.
/// Duration is in SECONDS — never convert here.
class GlossItem {
  final String action;
  final double duration; // seconds — conversion happens ONLY at FastAPI boundary

  const GlossItem({
    required this.action,
    required this.duration,
  });

  factory GlossItem.fromJson(Map<String, dynamic> json) {
    return GlossItem(
      action: json['action'] as String,
      duration: (json['duration'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action,
        'duration': duration,
      };

  @override
  String toString() => 'GlossItem(action: $action, duration: ${duration}s)';
}
