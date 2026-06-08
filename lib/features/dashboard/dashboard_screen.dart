import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/providers.dart';
import '../../core/models/system_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/section_card.dart';
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Session',
            onPressed: () => context.push('/sessions/smart-create'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const LoadingState(message: 'Loading dashboard…'),
        error: (e, _) => ErrorState(error: e, onRetry: _refresh),
        data: (home) => _buildDashboard(home),
      ),
    );
  }

  Widget _buildDashboard(MobileHomeData home) {
    final status = home.systemStatus;
    final sessions = home.activeSessions ?? [];
    final attentionItems = home.attentionItems ?? [];

    return RefreshIndicator(
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.card,
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        children: [
          if (status != null) _buildStatusRow(status),
          const SizedBox(height: 8),
          _buildMetricsGrid(status, home),
          const SizedBox(height: 8),
          if ((home.pendingApprovals ?? 0) > 0 ||
              (home.pendingQuestions ?? 0) > 0)
            _buildAttentionBanner(home),
          if (sessions.isNotEmpty) _buildActiveSessions(sessions),
          if (attentionItems.isNotEmpty) _buildAttentionItems(attentionItems),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatusRow(SystemStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.healthy ? AppTheme.success : AppTheme.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.healthy ? 'Server Connected' : 'Server Issues Detected',
            style: TextStyle(
              color: status.healthy ? AppTheme.success : AppTheme.danger,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (status.version != null) ...[
            const SizedBox(width: 8),
            Text('v${status.version}',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11)),
          ],
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(SystemStatus? status, MobileHomeData home) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricCard(
            label: 'ACTIVE SESSIONS',
            value: '${status?.activeSessions ?? 0}',
            icon: Icons.layers_rounded,
            valueColor: AppTheme.accentBlue,
            onTap: () => context.go('/sessions'),
          ),
          MetricCard(
            label: 'RUNNING NOW',
            value: '${status?.runningSessions ?? 0}',
            icon: Icons.play_circle_rounded,
            valueColor: AppTheme.accentCyan,
            onTap: () => context.go('/sessions'),
          ),
          MetricCard(
            label: 'PENDING APPROVALS',
            value: '${home.pendingApprovals ?? status?.pendingApprovals ?? 0}',
            icon: Icons.approval_rounded,
            valueColor: (home.pendingApprovals ?? 0) > 0
                ? AppTheme.danger
                : AppTheme.textPrimary,
            onTap: () => context.go('/approvals'),
          ),
          MetricCard(
            label: 'PENDING QUESTIONS',
            value: '${home.pendingQuestions ?? status?.pendingQuestions ?? 0}',
            icon: Icons.help_outline_rounded,
            valueColor: (home.pendingQuestions ?? 0) > 0
                ? AppTheme.warning
                : AppTheme.textPrimary,
            onTap: () => context.go('/questions'),
          ),
          MetricCard(
            label: 'CYCLES TODAY',
            value: '${status?.cyclesToday ?? 0}',
            icon: Icons.loop_rounded,
          ),
          MetricCard(
            label: 'TOKENS TODAY',
            value: _formatTokens(status?.tokensToday ?? 0),
            icon: Icons.toll_rounded,
            onTap: () => context.push('/tokens'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionBanner(MobileHomeData home) {
    final approvals = home.pendingApprovals ?? 0;
    final questions = home.pendingQuestions ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: AppTheme.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                [
                  if (approvals > 0) '$approvals approval${approvals > 1 ? 's' : ''} pending',
                  if (questions > 0) '$questions question${questions > 1 ? 's' : ''} waiting',
                ].join(' · '),
                style: const TextStyle(
                    color: AppTheme.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/approvals'),
              child: const Text('Review',
                  style: TextStyle(color: AppTheme.danger, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessions(List<Map<String, dynamic>> sessions) {
    return SectionCard(
      title: 'ACTIVE SESSIONS',
      trailing: TextButton(
        onPressed: () => context.go('/sessions'),
        child: const Text('All', style: TextStyle(fontSize: 12)),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: sessions.take(4).map((s) {
          final status = s['status'] as String? ?? 'unknown';
          return ListTile(
            dense: true,
            title: Text(
              s['name'] as String? ?? 'Session',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              s['current_task'] as String? ?? '',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: StatusBadge(status: status),
            onTap: () => context.push('/sessions/${s['id']}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttentionItems(List<Map<String, dynamic>> items) {
    return SectionCard(
      title: 'NEEDS ATTENTION',
      padding: EdgeInsets.zero,
      child: Column(
        children: items.take(3).map((item) {
          final type = item['type'] as String? ?? 'unknown';
          return ListTile(
            dense: true,
            leading: Icon(
              type == 'approval'
                  ? Icons.approval_rounded
                  : Icons.help_outline_rounded,
              color: type == 'approval' ? AppTheme.danger : AppTheme.warning,
              size: 18,
            ),
            title: Text(
              item['title'] as String? ?? item['message'] as String? ?? 'Attention needed',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              if (type == 'approval') {
                context.go('/approvals');
              } else {
                context.go('/questions');
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SectionCard(
      title: 'QUICK ACTIONS',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _actionChip(
            Icons.add_circle_rounded,
            'New Session',
            AppTheme.accentBlue,
            () => context.push('/sessions/smart-create'),
          ),
          _actionChip(
            Icons.approval_rounded,
            'Approvals',
            AppTheme.danger,
            () => context.go('/approvals'),
          ),
          _actionChip(
            Icons.help_outline_rounded,
            'Questions',
            AppTheme.warning,
            () => context.go('/questions'),
          ),
          _actionChip(
            Icons.toll_rounded,
            'Tokens',
            AppTheme.accentViolet,
            () => context.push('/tokens'),
          ),
          _actionChip(
            Icons.verified_rounded,
            'Proof',
            AppTheme.success,
            () => context.push('/proof'),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return tokens.toString();
  }
}
