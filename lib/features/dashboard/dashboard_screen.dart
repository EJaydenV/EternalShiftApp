import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/models/system_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    final interval = ref.read(pollIntervalProvider);
    _pollTimer = Timer.periodic(Duration(seconds: interval), (_) => _refresh());
  }

  void _refresh() {
    ref.invalidate(mobileHomeProvider);
    ref.invalidate(systemStatusProvider);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(mobileHomeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: homeAsync.when(
        loading: () => const LoadingState(message: 'Loading…'),
        error: (e, _) => ErrorState(error: e, onRetry: _refresh),
        data: (home) => _buildBody(home),
      ),
    );
  }

  Widget _buildBody(MobileHomeData home) {
    final status = home.systemStatus;
    final sessions = home.activeSessions ?? [];
    final attentionItems = home.attentionItems ?? [];

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfaceContainerHigh,
      onRefresh: () async => _refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(status)),
          SliverToBoxAdapter(child: _buildStatRow(status, home)),
          if ((home.pendingApprovals ?? 0) > 0 ||
              (home.pendingQuestions ?? 0) > 0)
            SliverToBoxAdapter(child: _buildAttentionBanner(home)),
          SliverToBoxAdapter(child: _buildQuickActions()),
          if (sessions.isNotEmpty)
            SliverToBoxAdapter(child: _buildActiveSessions(sessions)),
          if (attentionItems.isNotEmpty)
            SliverToBoxAdapter(child: _buildAttentionItems(attentionItems)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(SystemStatus? status) {
    final healthy = status?.healthy ?? false;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.logoGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mission Control',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: healthy ? AppTheme.success : AppTheme.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (healthy ? AppTheme.success : AppTheme.danger)
                        .withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/sessions/smart-create'),
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainerHigh,
                foregroundColor: AppTheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(foregroundColor: AppTheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(SystemStatus? status, MobileHomeData home) {
    final stats = [
      _Stat('Total Sessions',
          '${(status?.activeSessions ?? 0) + (status?.completedSessions ?? 0)}',
          AppTheme.primary),
      _Stat('Active', '${status?.activeSessions ?? 0}', AppTheme.secondary),
      _Stat('Running', '${status?.runningSessions ?? 0}', AppTheme.success),
      _Stat('Cycles Today', '${status?.cyclesToday ?? 0}', AppTheme.tertiary),
      _Stat('Pending', '${home.pendingApprovals ?? 0}', AppTheme.warning),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: stats.length,
        itemBuilder: (_, i) => _buildStatCard(stats[i]),
      ),
    );
  }

  Widget _buildStatCard(_Stat stat) {
    return Container(
      width: 110,
      decoration: AppTheme.glassCard(radius: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: TextStyle(
              color: stat.color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: const TextStyle(
              color: AppTheme.outline,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionBanner(MobileHomeData home) {
    final approvals = home.pendingApprovals ?? 0;
    final questions = home.pendingQuestions ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassCard(
          radius: 12,
          borderColor: AppTheme.warning.withOpacity(0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: AppTheme.warning, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                [
                  if (approvals > 0)
                    '$approvals approval${approvals > 1 ? 's' : ''} pending',
                  if (questions > 0)
                    '$questions question${questions > 1 ? 's' : ''} waiting',
                ].join(' · '),
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/approvals'),
              child: const Text('Review',
                  style: TextStyle(color: AppTheme.warning, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _Action('New Session', Icons.auto_awesome_rounded, AppTheme.primary,
          () => context.push('/sessions/smart-create')),
      _Action('Approvals', Icons.approval_rounded, AppTheme.danger,
          () => context.go('/approvals')),
      _Action('Sessions', Icons.layers_rounded, AppTheme.secondary,
          () => context.go('/sessions')),
      _Action('Proof', Icons.verified_rounded, AppTheme.success,
          () => context.go('/proof')),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                color: AppTheme.outline,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: actions.map(_buildActionButton).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(_Action action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: action.color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 18),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: TextStyle(
                  color: action.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessions(List<Map<String, dynamic>> sessions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ACTIVE SESSIONS',
                  style: TextStyle(
                    color: AppTheme.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/sessions'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('All →',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sessions.take(4).map(_buildSessionRow),
        ],
      ),
    );
  }

  Widget _buildSessionRow(Map<String, dynamic> s) {
    final status = s['status'] as String? ?? 'unknown';
    final statusColor = _statusColor(status);
    return GestureDetector(
      onTap: () => context.push('/sessions/${s['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: statusColor, width: 3),
            top: const BorderSide(color: AppTheme.glassBorder, width: 1),
            right: const BorderSide(color: AppTheme.glassBorder, width: 1),
            bottom: const BorderSide(color: AppTheme.glassBorder, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name'] as String? ?? 'Session',
                    style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((s['current_task'] as String?) != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      s['current_task'] as String,
                      style: const TextStyle(
                          color: AppTheme.outline, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            StatusBadge(status: status),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionItems(List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'NEEDS ATTENTION',
              style: TextStyle(
                color: AppTheme.outline,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...items.take(3).map((item) {
            final type = item['type'] as String? ?? 'unknown';
            final color =
                type == 'approval' ? AppTheme.danger : AppTheme.warning;
            return GestureDetector(
              onTap: () => type == 'approval'
                  ? context.go('/approvals')
                  : context.go('/questions'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: AppTheme.glassCard(
                    radius: 12, borderColor: color.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      type == 'approval'
                          ? Icons.approval_rounded
                          : Icons.help_outline_rounded,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['title'] as String? ??
                            item['message'] as String? ??
                            'Attention needed',
                        style: const TextStyle(
                            color: AppTheme.onSurface, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'running':
        return AppTheme.success;
      case 'paused':
        return AppTheme.warning;
      case 'blocked':
        return AppTheme.danger;
      case 'active':
        return AppTheme.primary;
      default:
        return AppTheme.outline;
    }
  }
}

class _Stat {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.label, this.icon, this.color, this.onTap);
}
