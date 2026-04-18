/// App-wide configuration constants.
/// Update these before running the app.
class AppConfig {
  AppConfig._();

  /// Your n8n webhook URL — update before running
  static const String n8nWebhookUrl = 'https://projectnumcr7.app.n8n.cloud/webhook-test/isl-input';

  /// FastAPI backend base URL
  /// Local dev: http://localhost:8000
  /// Deployed: https://hack-helix.onrender.com
  static const String fastApiBaseUrl = 'https://hack-helix.onrender.com';

  /// FastAPI enrich endpoint
  static const String enrichEndpoint = '$fastApiBaseUrl/enrich';

  /// App name
  static const String appName = 'ISL Sign Language';
}
