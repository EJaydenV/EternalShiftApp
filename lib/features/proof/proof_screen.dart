import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/models/proof_package.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';

class ProofScreen extends ConsumerWidget {
  final String? sessionId;
  const ProofScreen({super.key, this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofAsync = sessionId != null
        ? ref.watch(sessionProofProvider(sessionId!))
        : ref.watch(proofProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Proof Packages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => sessionId != null
                ? ref.invalidate(sessionProofProvider(sessionId!))
                : ref.invalidate(proofProvider),
          ),
        ],
      ),
      body: proofAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(error: e),
        data: (proofList) {
          final packages = proofList as List<ProofPackage>;
          if (packages.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_rounded,
              title: 'No proof packages',
              subtitle: 'Proof packages appear after cycles complete.',
            );
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: AppTheme.surfaceContainerHigh,
            onRefresh: () async => sessionId != null
                ? ref.invalidate(sessionProofProvider(sessionId!))
                : ref.invalidate(proofProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: packages.length,
              itemBuilder: (_, i) => _ProofCard(proof: packages[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  final ProofPackage proof;
  const _ProofCard({required this.proof});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon) = _proofStyle();

    return GestureDetector(
      onTap: () => context.push('/proof/${proof.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: statusColor, width: 3),
            top: const BorderSide(color: AppTheme.glassBorder, width: 1),
            right: const BorderSide(color: AppTheme.glassBorder, width: 1),
            bottom: const BorderSide(color: AppTheme.glassBorder, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    proof.task ?? 'Proof Package',
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(statusColor),
              ],
            ),
            if (proof.acceptanceCriteria != null) ...[
              const SizedBox(height: 8),
              Text(
                proof.acceptanceCriteria!,
                style: const TextStyle(
                    color: AppTheme.onSurfaceVariant, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (proof.exitCode != null)
                  _chip('Exit ${proof.exitCode}',
                      proof.exitCode == 0 ? AppTheme.success : AppTheme.danger),
                if (proof.uiTestsPassed != null)
                  _chip(
                    proof.uiTestsPassed! ? 'UI Tests ✓' : 'UI Tests ✗',
                    proof.uiTestsPassed! ? AppTheme.success : AppTheme.danger,
                  ),
                if (proof.testsRun != null)
                  _chip('${proof.testsRun!.length} tests', AppTheme.outline),
                if (proof.filesChanged != null)
                  _chip('${proof.filesChanged!.length} files changed',
                      AppTheme.outline),
                if (proof.reviewerVerdict != null)
                  _chip(proof.reviewerVerdict!, AppTheme.accentViolet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(Color color) {
    final label = proof.isPassed
        ? 'Verified'
        : proof.isFailed
            ? 'Rejected'
            : proof.status ?? 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  (Color, IconData) _proofStyle() {
    if (proof.isPassed) return (AppTheme.secondary, Icons.verified_rounded);
    if (proof.isFailed) return (AppTheme.danger, Icons.cancel_rounded);
    return (AppTheme.outline, Icons.pending_rounded);
  }
}
