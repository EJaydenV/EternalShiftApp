import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';

class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  final _urlController =
      TextEditingController(text: AppConfig.defaultServerUrl);
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _testing = false;
  bool _saving = false;
  _ConnectionState _connState = _ConnectionState.idle;
  String? _connMessage;
  String? _serverVersion;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _testing = true;
      _connState = _ConnectionState.testing;
      _connMessage = null;
      _serverVersion = null;
    });

    try {
      final client = ApiClient(
        baseUrl: _urlController.text.trim(),
        token: _tokenController.text.trim().isEmpty
            ? null
            : _tokenController.text.trim(),
      );
      final healthy = await client.checkHealth();
      if (!mounted) return;
      if (healthy) {
        try {
          final status = await client.getSystemStatus();
          _serverVersion = status.version;
        } catch (_) {}
        setState(() {
          _connState = _ConnectionState.success;
          _connMessage = _serverVersion != null
              ? 'Connected — Server v$_serverVersion'
              : 'Connected successfully';
        });
      } else {
        setState(() {
          _connState = _ConnectionState.failure;
          _connMessage = 'Server responded but health check failed.';
        });
      }
    } catch (e) {
      setState(() {
        _connState = _ConnectionState.failure;
        _connMessage = 'Cannot reach the server. Check the URL and try again.';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'No API Token',
        message:
            'You have not entered an API token. Some features may not work without authentication.',
        confirmLabel: 'Continue Anyway',
      );
      if (!confirmed) return;
    }

    setState(() => _saving = true);
    try {
      final settings = ref.read(settingsStorageProvider);
      await settings.setServerUrl(url);
      if (token.isNotEmpty) {
        await settings.setApiToken(token);
      }
      await settings.setOnboardingComplete(true);

      final client = ref.read(apiClientProvider);
      client.updateConfig(baseUrl: url, token: token.isEmpty ? null : token);

      ref.read(isConfiguredProvider.notifier).state = true;
      ref.read(serverUrlProvider.notifier).state = url;

      if (mounted) context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildFields(),
                const SizedBox(height: 24),
                _buildConnectionStatus(),
                const SizedBox(height: 32),
                _buildActions(),
                const SizedBox(height: 40),
                _buildNetworkNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentBlue, AppTheme.accentViolet],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 20),
        const Text(
          'Eternal Shift',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Connect to your Eternal Shift server to manage your AI sessions.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        TextFormField(
          controller: _urlController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://127.0.0.1:8765',
            prefixIcon: Icon(Icons.dns_rounded, size: 18, color: AppTheme.textMuted),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Server URL is required';
            final uri = Uri.tryParse(v.trim());
            if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tokenController,
          style: const TextStyle(color: AppTheme.textPrimary),
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API Access Token',
            hintText: 'Enter your API token (optional for local dev)',
            prefixIcon: Icon(Icons.key_rounded, size: 18, color: AppTheme.textMuted),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    if (_connState == _ConnectionState.idle) return const SizedBox.shrink();

    final (icon, color, bg) = switch (_connState) {
      _ConnectionState.testing => (
          Icons.hourglass_empty_rounded,
          AppTheme.textSecondary,
          AppTheme.surface
        ),
      _ConnectionState.success => (
          Icons.check_circle_rounded,
          AppTheme.success,
          AppTheme.success.withOpacity(0.1)
        ),
      _ConnectionState.failure => (
          Icons.error_rounded,
          AppTheme.danger,
          AppTheme.danger.withOpacity(0.1)
        ),
      _ => (Icons.info_rounded, AppTheme.textSecondary, AppTheme.surface),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _connMessage ?? 'Testing connection…',
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _testing ? null : _testConnection,
          icon: _testing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accentBlue),
                )
              : const Icon(Icons.wifi_tethering_rounded, size: 16),
          label: Text(_testing ? 'Testing…' : 'Test Connection'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save & Continue'),
        ),
      ],
    );
  }

  Widget _buildNetworkNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.accentCyan),
              SizedBox(width: 6),
              Text('Physical Device Note',
                  style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'On a physical phone, use your computer\'s LAN IP (e.g. http://192.168.x.x:8765) instead of localhost. Both devices must be on the same network.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

enum _ConnectionState { idle, testing, success, failure }
