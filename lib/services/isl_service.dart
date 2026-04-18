import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/gloss_item.dart';
import '../models/enriched_sign.dart';

/// Service to communicate with the FastAPI /enrich endpoint.
/// Sends gloss list (with duration in seconds), receives enriched signs
/// with duration already converted to milliseconds by FastAPI.
class IslService {
  final http.Client _client;

  IslService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends [glosses] to FastAPI /enrich and returns enriched sign sequence.
  /// FastAPI converts duration: seconds → milliseconds (ONLY there).
  /// [EnrichedSign.durationMs] will be in ms when we receive it here.
  Future<List<EnrichedSign>> enrich(List<GlossItem> glosses) async {
    // TODO: implement FastAPI /enrich call
    final response = await _client.post(
      Uri.parse(AppConfig.enrichEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'glosses': glosses.map((g) => g.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('FastAPI /enrich error: ${response.statusCode}');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> sequence = data['sequence'] as List<dynamic>;

    return sequence
        .map((e) => EnrichedSign.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _client.close();
}
