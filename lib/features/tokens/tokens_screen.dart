import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/providers.dart';
import '../../core/models/token_usage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/section_card.dart';

class TokensScreen extends ConsumerWidget {
  const TokensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(tokenSummaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Token Usage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(tokenSummaryProvider),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e, onRetry: () => ref.invalidate(tokenSummaryProvider)),
        data: (summary) => _buildBody(summary),
      ),
    );
  }

  Widget _buildBody(TokenSummary summary) {
    final today = summary.today;
    final total = summary.total;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildCliWarning(today),
        const SizedBox(height: 8),
        Padding(
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
                label: 'INPUT TODAY',
                value: _fmt(today?.inputTokens ?? 0),
                icon: Icons.input_rounded,
              ),
              MetricCard(
                label: 'OUTPUT TODAY',
                value: _fmt(today?.outputTokens ?? 0),
                icon: Icons.output_rounded,
              ),
              MetricCard(
                label: 'TOTAL TODAY',
                value: _fmt(today?.total ?? 0),
                icon: Icons.toll_rounded,
                valueColor: AppTheme.accentBlue,
              ),
              MetricCard(
                label: 'CACHE HIT RATE',
                value:
                    '${(today?.cacheHitRate ?? 0 * 100).toStringAsFixed(0)}%',
                icon: Icons.cached_rounded,
                valueColor: AppTheme.success,
              ),
            ],
          ),
        ),
        if (total != null) ...[
          SectionCard(
            title: 'ALL TIME',
            child: Column(
              children: [
                _row('Total Tokens', _fmt(total.total)),
                _row('Input', _fmt(total.inputTokens ?? 0)),
                _row('Output', _fmt(total.outputTokens ?? 0)),
                _row('Cache Read', _fmt(total.cacheReadTokens ?? 0)),
                if (today?.isEstimated == true)
                  _row('Mode', 'Estimated (Claude CLI)'),
              ],
            ),
          ),
        ],
        if (summary.efficiencySavings != null) ...[
          SectionCard(
            title: 'EFFICIENCY',
            child: Column(
              children: [
                _row('Cache Savings',
                    '${summary.efficiencySavings!.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCliWarning(TokenUsage? today) {
    if (today?.provider != 'claude_cli' && today?.isEstimated != true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 14),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exact remaining Claude subscription tokens are unavailable unless Claude CLI exposes them officially. Showing estimated usage only.',
                style: TextStyle(color: AppTheme.warning, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(int t) {
    if (t >= 1000000) return '${(t / 1000000).toStringAsFixed(2)}M';
    if (t >= 1000) return '${(t / 1000).toStringAsFixed(1)}K';
    return '$t';
  }
}
