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
  _ConnState _connState = _ConnState.idle;
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
      _connState = _ConnState.testing;
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
          _connState = _ConnState.success;
          _connMessage = _serverVersion != null
              ? 'Connected — Server v$_serverVersion'
              : 'Connected successfully';
        });
      } else {
        setState(() {
          _connState = _ConnState.failure;
          _connMessage = 'Server responded but health check failed.';
        });
      }
    } catch (e) {
      setState(() {
        _connState = _ConnState.failure;
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
      if (token.isNotEmpty) await settings.setApiToken(token);
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
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.inversePrimary.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 64),
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildHeading(),
                    const SizedBox(height: 36),
                    _buildGlassCard(),
                    const SizedBox(height: 20),
                    _buildConnectionStatus(),
                    const SizedBox(height: 32),
                    _buildActions(),
                    const SizedBox(height: 28),
                    _buildNetworkNote(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppTheme.logoGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inversePrimary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'E',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return const Column(
      children: [
        Text(
          'Eternal Shift',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Connect to your AI orchestration server',
          style: TextStyle(color: AppTheme.outline, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    return Container(
      decoration: AppTheme.glassCard(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVER CONFIGURATION',
            style: TextStyle(
              color: AppTheme.outline,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _urlController,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://127.0.0.1:8765',
              prefixIcon: Icon(Icons.dns_rounded, size: 18, color: AppTheme.outline),
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
            style: const TextStyle(color: AppTheme.onSurface),
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Bearer Token',
              hintText: 'Optional for local development',
              prefixIcon: Icon(Icons.key_rounded, size: 18, color: AppTheme.outline),
            ),
            autocorrect: false,
            enableSuggestions: false,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_connState == _ConnState.idle) return const SizedBox.shrink();

    final (icon, color) = switch (_connState) {
      _ConnState.testing => (Icons.hourglass_empty_rounded, AppTheme.outline),
      _ConnState.success => (Icons.check_circle_rounded, AppTheme.success),
      _ConnState.failure => (Icons.error_rounded, AppTheme.danger),
      _ => (Icons.info_rounded, AppTheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassCard(
        radius: 12,
        borderColor: color.withOpacity(0.4),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
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
                      strokeWidth: 2, color: AppTheme.primary),
                )
              : const Icon(Icons.wifi_tethering_rounded, size: 16),
          label: Text(_testing ? 'Testing…' : 'Test Connection'),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _saving ? null : _save,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: _saving ? null : AppTheme.primaryGradient,
              color: _saving ? AppTheme.surfaceContainerHigh : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.onSurface),
                    )
                  : const Text(
                      'Connect',
                      style: TextStyle(
                        color: AppTheme.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard(
        radius: 12,
        borderColor: AppTheme.secondary.withOpacity(0.3),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.secondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'On a physical device, use your computer\'s LAN IP (e.g. http://192.168.x.x:8765) instead of localhost. Both devices must be on the same network.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ConnState { idle, testing, success, failure }
