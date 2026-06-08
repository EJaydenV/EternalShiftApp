import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/models/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  String _filter = 'all';

  static const _filters = [
    ('all', 'All'),
    ('active', 'Active'),
    ('running', 'Running'),
    ('paused', 'Paused'),
    ('blocked', 'Blocked'),
    ('completed', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/sessions/smart-create'),
            tooltip: 'New Session',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(sessionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: sessionsAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(sessionsProvider)),
              data: (sessions) {
                final filtered = _applyFilter(sessions);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.layers_rounded,
                    title: 'No sessions',
                    subtitle: _filter == 'all'
                        ? 'Create your first session to get started.'
                        : 'No sessions with status "$_filter".',
                    actionLabel: 'New Session',
                    onAction: () => context.push('/sessions/smart-create'),
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.accentBlue,
                  backgroundColor: AppTheme.card,
                  onRefresh: () async => ref.invalidate(sessionsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _SessionCard(
                      session: filtered[i],
                      onRefresh: () => ref.invalidate(sessionsProvider),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sessions/smart-create'),
        backgroundColor: AppTheme.accentBlue,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text('Smart Session'),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final (value, label) = _filters[i];
          final selected = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accentBlue
                    : AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected
                        ? AppTheme.accentBlue
                        : AppTheme.cardBorder),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Session> _applyFilter(List<Session> sessions) {
    if (_filter == 'all') {
      return sessions.where((s) => !s.isDeleted).toList();
    }
    return sessions.where((s) => s.status == _filter).toList();
  }
}

class _SessionCard extends ConsumerWidget {
  final Session session;
  final VoidCallback onRefresh;

  const _SessionCard({required this.session, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/sessions/${session.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: session.status),
                ],
              ),
              if (session.objective != null) ...[
                const SizedBox(height: 6),
                Text(
                  session.objective!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (session.currentTask != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_right_rounded,
                        color: AppTheme.accentCyan, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.currentTask!,
                        style: const TextStyle(
                            color: AppTheme.accentCyan, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (session.provider != null) ...[
                    _chip(session.provider!, AppTheme.accentViolet),
                    const SizedBox(width: 6),
                  ],
                  if (session.cycleCount != null) ...[
                    _chip('${session.cycleCount} cycles', AppTheme.textMuted),
                    const SizedBox(width: 6),
                  ],
                  if (session.totalTokens != null)
                    _chip(_formatTokens(session.totalTokens!), AppTheme.textMuted),
                  const Spacer(),
                  _buildActions(context, ref),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.isRunning)
          _iconBtn(Icons.pause_rounded, AppTheme.warning, () async {
            final ok = await showConfirmDialog(
              context,
              title: 'Pause Session?',
              message: 'The current cycle will complete before pausing.',
            );
            if (ok) {
              await ref.read(apiClientProvider).pauseSession(session.id);
              onRefresh();
            }
          }),
        if (session.isPaused || session.isBlocked)
          _iconBtn(Icons.play_arrow_rounded, AppTheme.success, () async {
            await ref.read(apiClientProvider).resumeSession(session.id);
            onRefresh();
          }),
        if (session.isActive && !session.isRunning)
          _iconBtn(Icons.stop_rounded, AppTheme.danger, () async {
            final ok = await showConfirmDialog(
              context,
              title: 'Stop Session?',
              message: 'This will stop the session. You can reopen it later.',
              isDangerous: true,
            );
            if (ok) {
              await ref.read(apiClientProvider).stopSession(session.id);
              onRefresh();
            }
          }),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style:
              TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  String _formatTokens(int t) {
    if (t >= 1000000) return '${(t / 1000000).toStringAsFixed(1)}M tok';
    if (t >= 1000) return '${(t / 1000).toStringAsFixed(1)}K tok';
    return '$t tok';
  }
}
