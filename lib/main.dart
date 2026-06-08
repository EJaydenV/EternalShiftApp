import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/api/api_client.dart';
import 'core/api/providers.dart';
import 'core/storage/settings_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsStorage(prefs);
  final token = await settings.getApiToken();
  final client = ApiClient(baseUrl: settings.serverUrl, token: token);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWithValue(client),
      ],
      child: const EternalShiftApp(),
    ),
  );
}
