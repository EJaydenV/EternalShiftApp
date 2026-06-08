import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SettingsStorage {
  static const _keyServerUrl = 'server_url';
  static const _keyApiToken = 'api_token';
  static const _keyRefreshInterval = 'refresh_interval';
  static const _keyOnboardingComplete = 'onboarding_complete';

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  SettingsStorage(this._prefs)
      : _secure = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  String get serverUrl =>
      _prefs.getString(_keyServerUrl) ?? AppConfig.defaultServerUrl;

  Future<void> setServerUrl(String url) => _prefs.setString(_keyServerUrl, url);

  Future<String?> getApiToken() => _secure.read(key: _keyApiToken);

  Future<void> setApiToken(String token) =>
      _secure.write(key: _keyApiToken, value: token);

  Future<void> clearApiToken() => _secure.delete(key: _keyApiToken);

  int get refreshInterval =>
      _prefs.getInt(_keyRefreshInterval) ?? AppConfig.defaultPollIntervalSeconds;

  Future<void> setRefreshInterval(int seconds) =>
      _prefs.setInt(_keyRefreshInterval, seconds);

  bool get onboardingComplete =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_keyOnboardingComplete, value);
}
