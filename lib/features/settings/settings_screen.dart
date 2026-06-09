import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';

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
      final activeToken =
          token.isNotEmpty ? token : await settings.getApiToken();
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
    ref.read(apiClientProvider).updateConfig(token: null);
    setState(() => _tokenSet = false);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Token cleared')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(healthy ? 'Connected successfully!' : 'Connection failed'),
        backgroundColor: healthy ? AppTheme.success : AppTheme.danger,
      ));
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
          const SizedBox(height: 8),
          _sectionLabel('SERVER CONNECTION'),
          _glassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _urlCtrl,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    prefixIcon: Icon(Icons.dns_rounded,
                        size: 16, color: AppTheme.outline),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                if (_tokenSet)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
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
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Clear',
                              style: TextStyle(
                                  color: AppTheme.danger, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tokenCtrl,
                  style: const TextStyle(color: AppTheme.onSurface),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _tokenSet
                        ? 'New API Token (leave blank to keep current)'
                        : 'API Access Token',
                    prefixIcon: const Icon(Icons.key_rounded,
                        size: 16, color: AppTheme.outline),
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testConnection,
                        icon: const Icon(Icons.wifi_tethering_rounded,
                            size: 14),
                        label: const Text('Test'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimary))
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('POLLING INTERVAL'),
          _glassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Refresh every ${_refreshInterval}s',
                      style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
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
                  style: TextStyle(color: AppTheme.outline, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('SECURITY'),
          _glassSection(
            child: Column(
              children: [
                _secNote(Icons.check_circle_rounded, AppTheme.success,
                    'No LLM runs locally on this device'),
                _secNote(Icons.check_circle_rounded, AppTheme.success,
                    'API token stored in secure encrypted storage'),
                _secNote(Icons.check_circle_rounded, AppTheme.success,
                    'Token is never displayed after saving'),
                _secNote(Icons.check_circle_rounded, AppTheme.success,
                    'Server is the only source of truth'),
                _secNote(Icons.warning_rounded, AppTheme.warning,
                    'Do not expose server publicly without auth'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('ABOUT'),
          _glassSection(
            child: Column(
              children: [
                _infoRow('App Version', AppConfig.appVersion),
                _infoRow('Default Server', AppConfig.defaultServerUrl),
                _infoRow('Architecture', 'Mobile client → Server API only'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Reset Setup?',
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

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.outline,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _glassSection({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

  Widget _secNote(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.outline, fontSize: 12)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppTheme.onSurface, fontSize: 12))),
        ],
      ),
    );
  }
}
