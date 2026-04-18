import '../models/enriched_sign.dart';
import '../models/gloss_item.dart';
import '../services/isl_service.dart';
import '../services/n8n_service.dart';

/// Repository that orchestrates:
/// 1. Sending text to n8n → getting ISL gloss sequence
/// 2. Enriching glosses via FastAPI → getting keyframes + NMM in ms
///
/// This is the single data source for [IslBloc].
class IslRepository {
  final N8nService _n8nService;
  final IslService _islService;

  IslRepository({
    N8nService? n8nService,
    IslService? islService,
  })  : _n8nService = n8nService ?? N8nService(),
        _islService = islService ?? IslService();

  /// Full pipeline: text → glosses → enriched signs
  Future<List<EnrichedSign>> processText(String text) async {
    final List<GlossItem> glosses = await _n8nService.sendText(text);
    if (glosses.isEmpty) return [];
    final List<EnrichedSign> enriched = await _islService.enrich(glosses);
    return enriched;
  }

  /// Only fetch glosses from n8n (step 1)
  Future<List<GlossItem>> fetchGlosses(String text) async {
    return _n8nService.sendText(text);
  }

  /// Only enrich glosses via FastAPI (step 2)
  Future<List<EnrichedSign>> enrichGlosses(List<GlossItem> glosses) async {
    return _islService.enrich(glosses);
  }

  void dispose() {
    _n8nService.dispose();
    _islService.dispose();
  }
}
