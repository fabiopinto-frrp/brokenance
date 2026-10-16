import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/app_preferences.dart';
import 'core/storage/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await AppPreferences.load();
  final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl, session: SecureSessionStorage());

  runApp(BrokenanceApp(preferences: preferences, apiClient: apiClient));
}
