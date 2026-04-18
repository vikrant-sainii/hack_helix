import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/gloss_item.dart';

/// Service to communicate with the n8n webhook.
/// Sends raw text/speech transcript and receives ISL gloss sequence.
class N8nService {
  final http.Client _client;

  N8nService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends [text] to the n8n webhook and returns a list of [GlossItem].
  /// n8n returns: [{"action": "LIFE", "duration": 1.5}, ...]
  /// Duration is kept in SECONDS as received — never converted here.
  Future<List<GlossItem>> sendText(String text) async {
    // TODO: implement n8n webhook call
    // Placeholder returns empty list until n8n URL is configured
    if (AppConfig.n8nWebhookUrl == 'YOUR_N8N_WEBHOOK_URL') {
      return _mockGlosses(text);
    }

    final response = await _client.post(
      Uri.parse(AppConfig.n8nWebhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode != 200) {
      throw Exception('n8n webhook error: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => GlossItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mock glosses for development/testing (no n8n needed)
  List<GlossItem> _mockGlosses(String text) {
    return [
      const GlossItem(action: 'LIFE', duration: 1.5),
      const GlossItem(action: 'MY', duration: 1.0),
      const GlossItem(action: 'DANGER', duration: 2.0),
    ];
  }

  void dispose() => _client.close();
}
