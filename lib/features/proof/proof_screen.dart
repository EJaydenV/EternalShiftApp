import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/providers.dart';
import '../../core/models/proof_package.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

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
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: packages.length,
            itemBuilder: (_, i) => _ProofCard(proof: packages[i]),
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
    return Card(
      child: InkWell(
        onTap: () => context.push('/proof/${proof.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    proof.isPassed
                        ? Icons.verified_rounded
                        : proof.isFailed
                            ? Icons.cancel_rounded
                            : Icons.pending_rounded,
                    color: proof.isPassed
                        ? AppTheme.success
                        : proof.isFailed
                            ? AppTheme.danger
                            : AppTheme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      proof.task ?? 'Proof Package',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (proof.status != null) StatusBadge(status: proof.status!),
                ],
              ),
              if (proof.acceptanceCriteria != null) ...[
                const SizedBox(height: 8),
                Text(
                  proof.acceptanceCriteria!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
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
                    _chip(
                      'Exit ${proof.exitCode}',
                      proof.exitCode == 0 ? AppTheme.success : AppTheme.danger,
                    ),
                  if (proof.uiTestsPassed != null)
                    _chip(
                      proof.uiTestsPassed! ? 'UI Tests ✓' : 'UI Tests ✗',
                      proof.uiTestsPassed! ? AppTheme.success : AppTheme.danger,
                    ),
                  if (proof.testsRun != null)
                    _chip('${proof.testsRun!.length} tests', AppTheme.textMuted),
                  if (proof.filesChanged != null)
                    _chip(
                        '${proof.filesChanged!.length} files changed',
                        AppTheme.textMuted),
                  if (proof.reviewerVerdict != null)
                    _chip(proof.reviewerVerdict!, AppTheme.accentViolet),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
