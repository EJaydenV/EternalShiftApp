import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/providers.dart';
import '../../core/models/computer_action.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class ComputerActionsScreen extends ConsumerWidget {
  const ComputerActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(computerActionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Computer Actions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(computerActionsProvider),
          ),
        ],
      ),
      body: actionsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e, onRetry: () => ref.invalidate(computerActionsProvider)),
        data: (actions) {
          final list = actions as List<ComputerAction>;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.computer_rounded,
              title: 'No computer actions',
              subtitle: 'Browser and computer actions will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: list.length,
            itemBuilder: (_, i) => _ActionCard(action: list[i]),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final ComputerAction action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconFor(action.actionType),
                  color: AppTheme.accentCyan,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.actionType ?? 'Action',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (action.status != null)
                  StatusBadge(status: action.status!),
              ],
            ),
            if (action.description != null) ...[
              const SizedBox(height: 6),
              Text(action.description!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
            if (action.riskDecision != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.security_rounded,
                      color: AppTheme.warning, size: 12),
                  const SizedBox(width: 4),
                  Text('Risk: ${action.riskDecision}',
                      style: const TextStyle(
                          color: AppTheme.warning, fontSize: 11)),
                ],
              ),
            ],
            if (action.error != null) ...[
              const SizedBox(height: 6),
              Text('Error: ${action.error}',
                  style: const TextStyle(
                      color: AppTheme.danger, fontSize: 11)),
            ],
            if (action.executedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, HH:mm').format(action.executedAt!.toLocal()),
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? type) {
    switch (type?.toLowerCase()) {
      case 'browser':
      case 'navigate':
        return Icons.open_in_browser_rounded;
      case 'click':
        return Icons.touch_app_rounded;
      case 'type':
        return Icons.keyboard_rounded;
      case 'screenshot':
        return Icons.camera_alt_rounded;
      default:
        return Icons.computer_rounded;
    }
  }
}
