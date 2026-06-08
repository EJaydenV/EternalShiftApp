import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/providers.dart';
import '../../core/models/provider_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class ProvidersScreen extends ConsumerWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(providersStatusProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Providers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(providersStatusProvider),
          ),
        ],
      ),
      body: providersAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e, onRetry: () => ref.invalidate(providersStatusProvider)),
        data: (providers) {
          if (providers.isEmpty) {
            return const EmptyState(
              icon: Icons.device_hub_rounded,
              title: 'No providers found',
              subtitle: 'Check server configuration.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'API secrets and credentials are not shown. Configure them on the server.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
              ...providers.map((p) => _ProviderCard(provider: p)),
            ],
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderStatus provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconFor(provider.name),
                  color: provider.available
                      ? AppTheme.success
                      : AppTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.displayName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(
                    status: provider.available ? 'active' : 'unavailable'),
                if (provider.isSelected == true) ...[
                  const SizedBox(width: 8),
                  const StatusBadge(status: 'selected'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (provider.model != null)
              _row('Model', provider.model!),
            if (provider.mode != null)
              _row('Mode', provider.mode!),
            if (provider.timeoutSeconds != null)
              _row('Timeout', '${provider.timeoutSeconds}s'),
            if (provider.error != null)
              _errorNote(provider.error!),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _errorNote(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
      ),
      child: Text(error,
          style: const TextStyle(color: AppTheme.danger, fontSize: 11)),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'claude_cli':
        return Icons.terminal_rounded;
      case 'anthropic_api':
        return Icons.cloud_rounded;
      case 'mock':
        return Icons.science_rounded;
      default:
        return Icons.device_hub_rounded;
    }
  }
}
