import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api/providers.dart';
import '../../core/models/approval.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(approvalsProvider),
          ),
        ],
      ),
      body: approvalsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            error: e, onRetry: () => ref.invalidate(approvalsProvider)),
        data: (approvals) {
          final pending =
              approvals.where((a) => a.isPending).toList();
          final resolved = approvals
              .where((a) => !a.isPending)
              .toList()
            ..sort((a, b) =>
                (b.resolvedAt ?? DateTime(0)).compareTo(a.resolvedAt ?? DateTime(0)));

          if (approvals.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No approvals',
              subtitle: 'All clear — no pending approvals.',
            );
          }

          return RefreshIndicator(
            color: AppTheme.accentBlue,
            backgroundColor: AppTheme.card,
            onRefresh: () async => ref.invalidate(approvalsProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (pending.isNotEmpty) ...[
                  _sectionHeader('PENDING (${pending.length})'),
                  ...pending.map((a) => _ApprovalCard(
                        approval: a,
                        onRefresh: () => ref.invalidate(approvalsProvider),
                      )),
                ],
                if (resolved.isNotEmpty) ...[
                  _sectionHeader('RESOLVED'),
                  ...resolved.take(10).map((a) => _ApprovalCard(
                        approval: a,
                        onRefresh: () => ref.invalidate(approvalsProvider),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  final Approval approval;
  final VoidCallback onRefresh;

  const _ApprovalCard({required this.approval, required this.onRefresh});

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  final _commentCtrl = TextEditingController();
  bool _actioning = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Approve This Action?',
      message: 'Approving does NOT instantly execute the action.\n\n'
          'It marks the approval so the next safe server-side cycle can continue.',
      warningNote:
          'Approving does not instantly execute dangerous actions. The server handles execution.',
      confirmLabel: 'Approve',
    );
    if (!ok) return;
    setState(() => _actioning = true);
    try {
      await ref.read(apiClientProvider).approveApproval(
            widget.approval.id,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _reject() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reject This Action?',
      message: 'The session will be informed and will not proceed with this action.',
      isDangerous: true,
      confirmLabel: 'Reject',
    );
    if (!ok) return;
    setState(() => _actioning = true);
    try {
      await ref.read(apiClientProvider).rejectApproval(
            widget.approval.id,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.approval;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: a.isPending ? AppTheme.danger : AppTheme.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.requestedAction,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge(status: a.status),
              ],
            ),
            if (a.reason != null) ...[
              const SizedBox(height: 8),
              Text(a.reason!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
            if (a.riskCategory != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 12),
                  const SizedBox(width: 4),
                  Text('Risk: ${a.riskCategory}',
                      style: const TextStyle(
                          color: AppTheme.warning, fontSize: 11)),
                ],
              ),
            ],
            if (a.requestedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Requested ${DateFormat('MMM d, HH:mm').format(a.requestedAt!.toLocal())}',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
            if (a.isPending) ...[
              const SizedBox(height: 10),
              _approvalWarning(),
              const SizedBox(height: 10),
              TextFormField(
                controller: _commentCtrl,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 12),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Comment (optional)…',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _actioning ? null : _approve,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success),
                      child: const Text('Approve', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _actioning ? null : _reject,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger)),
                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _actioning
                        ? null
                        : () async {
                            await ref
                                .read(apiClientProvider)
                                .dismissApproval(a.id);
                            widget.onRefresh();
                          },
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _approvalWarning() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppTheme.warning, size: 13),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Approving does not instantly execute the action. It lets the next safe server-side cycle continue.',
              style: TextStyle(color: AppTheme.warning, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
