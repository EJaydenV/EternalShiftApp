import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../storage/settings_storage.dart';
import '../config/app_config.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope');
});

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsStorage(prefs);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final settings = ref.watch(settingsStorageProvider);
  return ApiClient(
    baseUrl: settings.serverUrl,
    token: null,
  );
});

final serverUrlProvider = StateProvider<String>((ref) {
  final settings = ref.watch(settingsStorageProvider);
  return settings.serverUrl;
});

final isConfiguredProvider = StateProvider<bool>((ref) {
  final settings = ref.watch(settingsStorageProvider);
  return settings.onboardingComplete;
});

final pollIntervalProvider = StateProvider<int>((ref) {
  final settings = ref.watch(settingsStorageProvider);
  return settings.refreshInterval;
});

// Async API providers

final sessionsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getSessions();
});

final sessionProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, id) async {
  final client = ref.watch(apiClientProvider);
  return client.getSession(id);
});

final approvalsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getApprovals();
});

final questionsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getQuestions();
});

final providersStatusProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getProviders();
});

final tokenSummaryProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getTokenSummary();
});

final systemStatusProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getSystemStatus();
});

final mobileHomeProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getMobileHome();
});

final uiTestScenariosProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getUiTestScenarios();
});

final uiTestRunsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getUiTestRuns();
});

final computerActionsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getComputerActions();
});

final screenshotsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getScreenshots();
});

final proofProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getProof();
});

// Per-session providers

final sessionConversationProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getConversation(sessionId);
});

final sessionCyclesProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getCycles(sessionId);
});

final sessionApprovalsProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getApprovals(sessionId: sessionId);
});

final sessionQuestionsProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getQuestions(sessionId: sessionId);
});

final sessionProofProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getProof(sessionId: sessionId);
});

final sessionScreenshotsProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getScreenshots(sessionId: sessionId);
});

final sessionTokensProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getSessionTokens(sessionId);
});

final sessionComputerActionsProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, sessionId) async {
  final client = ref.watch(apiClientProvider);
  return client.getComputerActions(sessionId: sessionId);
});
