import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlCtrl;
  late TextEditingController _tokenCtrl;
  bool _tokenSet = false;
  bool _saving = false;
  int _refreshInterval = AppConfig.defaultPollIntervalSeconds;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsStorageProvider);
    _urlCtrl = TextEditingController(text: settings.serverUrl);
    _tokenCtrl = TextEditingController();
    _refreshInterval = settings.refreshInterval;
    _loadTokenState();
  }

  Future<void> _loadTokenState() async {
    final token = await ref.read(settingsStorageProvider).getApiToken();
    if (mounted) setState(() => _tokenSet = token != null && token.isNotEmpty);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    final token = _tokenCtrl.text.trim();

    if (url != ref.read(settingsStorageProvider).serverUrl) {
      final ok = await showConfirmDialog(
        context,
        title: 'Change Server URL?',
        message: 'App will reconnect to the new server URL.',
        isDangerous: true,
      );
      if (!ok) return;
    }

    if (token.isNotEmpty) {
      final ok = await showConfirmDialog(
        context,
        title: 'Change API Token?',
        message: 'The new token will be saved securely.',
        isDangerous: true,
      );
      if (!ok) return;
    }

    setState(() => _saving = true);
    try {
      final settings = ref.read(settingsStorageProvider);
      await settings.setServerUrl(url);
      if (token.isNotEmpty) {
        await settings.setApiToken(token);
        setState(() => _tokenSet = true);
      }
      await settings.setRefreshInterval(_refreshInterval);

      final client = ref.read(apiClientProvider);
      final activeToken = token.isNotEmpty ? token : await settings.getApiToken();
      client.updateConfig(baseUrl: url, token: activeToken);

      ref.read(serverUrlProvider.notifier).state = url;
      ref.read(pollIntervalProvider.notifier).state = _refreshInterval;

      _tokenCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearToken() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear API Token?',
      message: 'The stored token will be deleted. You will need to re-enter it.',
      isDangerous: true,
    );
    if (!ok) return;
    await ref.read(settingsStorageProvider).clearApiToken();
    final client = ref.read(apiClientProvider);
    client.updateConfig(token: null);
    setState(() => _tokenSet = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token cleared')));
    }
  }

  Future<void> _testConnection() async {
    final settings = ref.read(settingsStorageProvider);
    final url = _urlCtrl.text.trim();
    final token = _tokenCtrl.text.trim().isEmpty
        ? await settings.getApiToken()
        : _tokenCtrl.text.trim();
    final client = ref.read(apiClientProvider);
    client.updateConfig(baseUrl: url, token: token);
    final healthy = await client.checkHealth();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              healthy ? 'Connected successfully!' : 'Connection failed'),
          backgroundColor: healthy ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          SectionCard(
            title: 'SERVER CONNECTION',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _urlCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    prefixIcon: Icon(Icons.dns_rounded, size: 16, color: AppTheme.textMuted),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                if (_tokenSet)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.success.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: AppTheme.success, size: 14),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'API token is set (not displayed for security)',
                            style: TextStyle(
                                color: AppTheme.success, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearToken,
                          child: const Text('Clear',
                              style: TextStyle(
                                  color: AppTheme.danger, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tokenCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _tokenSet
                        ? 'New API Token (leave blank to keep current)'
                        : 'API Access Token',
                    prefixIcon: const Icon(Icons.key_rounded,
                        size: 16, color: AppTheme.textMuted),
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testConnection,
                        icon: const Icon(Icons.wifi_tethering_rounded,
                            size: 14),
                        label: const Text('Test',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Save',
                                style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'POLLING',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refresh Interval: ${_refreshInterval}s',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                ),
                Slider(
                  value: _refreshInterval.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '${_refreshInterval}s',
                  onChanged: (v) =>
                      setState(() => _refreshInterval = v.round()),
                ),
                const Text(
                  'Longer intervals save battery. Shorter intervals give faster updates.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'SECURITY',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _securityNote(
                    Icons.check_circle_rounded,
                    AppTheme.success,
                    'No LLM runs locally on this device'),
                _securityNote(
                    Icons.check_circle_rounded,
                    AppTheme.success,
                    'API token stored in secure encrypted storage'),
                _securityNote(
                    Icons.check_circle_rounded,
                    AppTheme.success,
                    'Token is never displayed after saving'),
                _securityNote(
                    Icons.check_circle_rounded,
                    AppTheme.success,
                    'Server is the only source of truth'),
                _securityNote(
                    Icons.warning_rounded,
                    AppTheme.warning,
                    'Do not expose server publicly without auth'),
              ],
            ),
          ),
          SectionCard(
            title: 'ABOUT',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('App Version', AppConfig.appVersion),
                _row('Default Server', AppConfig.defaultServerUrl),
                _row('Architecture', 'Mobile client → Server API only'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Reset Onboarding?',
                  message:
                      'You will be taken back to the server setup screen.',
                  isDangerous: true,
                );
                if (ok) {
                  await ref
                      .read(settingsStorageProvider)
                      .setOnboardingComplete(false);
                  ref.read(isConfiguredProvider.notifier).state = false;
                  if (mounted) context.go('/setup');
                }
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger)),
              child: const Text('Reset Setup / Change Server'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityNote(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }
}
