/// App-wide configuration constants.
/// Update these before running the app.
class AppConfig {
  AppConfig._();

  /// Your n8n webhook URL — update before running
  static const String n8nWebhookUrl = 'YOUR_N8N_WEBHOOK_URL';

  /// FastAPI backend base URL
  /// Local dev: http://localhost:8000
  /// Deployed: https://your-backend.railway.app
  static const String fastApiBaseUrl = 'http://localhost:8000';

  /// FastAPI enrich endpoint
  static const String enrichEndpoint = '$fastApiBaseUrl/enrich';

  /// App name
  static const String appName = 'ISL Sign Language';
}
